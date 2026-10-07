//
// QueryTool.cpp
//

#include "QueryTool.h"
#include "../MCPToolHelpers.h"
#include <algorithm>

namespace DBModels
{
    // Engines that accept `LIMIT n` as SQL-standard tail. MSSQL is
    // deliberately excluded — it uses `TOP n` after SELECT, which
    // we cannot safely inject without rewriting the statement.
    // Callers targeting MSSQL must emit their own TOP clause.
    static bool acceptsLimitSuffix(DatabaseType t)
    {
        return t == DatabaseType::PostgreSQL ||
               t == DatabaseType::MySQL      ||
               t == DatabaseType::SQLite;
    }

    MCPToolResult QueryTool::execute(const nlohmann::json& params, MCPToolContext& ctx)
    {
        const auto connId = MCPTool::extractConnectionId(params);

        std::string sqlUtf8;
        if (params.contains("sql") && params["sql"].is_string())
            sqlUtf8 = params["sql"].get<std::string>();
        else if (params.contains("query") && params["query"].is_string())
            sqlUtf8 = params["query"].get<std::string>();
        else
            throw MCPToolError::invalidParameters("sql is required");

        int rowLimit = 1000;
        if (params.contains("row_limit") && params["row_limit"].is_number_integer())
            rowLimit = std::clamp(params["row_limit"].get<int>(), 1, 10000);

        // Base permission.
        const auto perm = ctx.checkPermission(tier(), connId);
        if (const auto* msg = perm.errorMessage())
            throw MCPToolError::permissionDenied(*msg);

        // Read-only SELECT check if mode == ReadOnly.
        const auto mode = ctx.permissionEngine.getMode(connId);
        if (mode == MCPConnectionMode::ReadOnly)
        {
            auto v = ctx.permissionEngine.validateReadOnlyQuery(sqlUtf8);
            if (const auto* m = v.errorMessage())
                throw MCPToolError::permissionDenied(*m);
        }

        auto [adapter, config] = ctx.getAdapter(connId);

        // Append LIMIT if absent and target is a SELECT/WITH SQL statement.
        // Keep the raw sql untouched otherwise (SHOW, DESCRIBE, EXPLAIN, Redis/Mongo
        // adapters carry their own shape).
        std::wstring sqlW = MCPToolHelpers::fromUtf8(sqlUtf8);
        if (acceptsLimitSuffix(config.databaseType))
        {
            std::wstring trimmed = sqlW;
            size_t startPos = trimmed.find_first_not_of(L" \t\r\n");
            if (startPos != std::wstring::npos)
                trimmed = trimmed.substr(startPos);

            std::wstring upper = trimmed;
            std::transform(upper.begin(), upper.end(), upper.begin(), ::towupper);

            bool isSelectOrWith = (upper.rfind(L"SELECT", 0) == 0 || upper.rfind(L"WITH", 0) == 0);
            if (isSelectOrWith && upper.find(L"LIMIT") == std::wstring::npos)
            {
                while (!trimmed.empty() && (trimmed.back() == L' ' ||
                        trimmed.back() == L';' || trimmed.back() == L'\n' || trimmed.back() == L'\r' || trimmed.back() == L'\t'))
                    trimmed.pop_back();
                sqlW = trimmed + L" LIMIT " + std::to_wstring(rowLimit);
            }
        }

        QueryResult r;
        try { r = adapter->execute(sqlW); }
        catch (const std::exception& e)
        { throw MCPToolError::queryFailed(e.what()); }

        if (!r.success)
            throw MCPToolError::queryFailed(MCPToolHelpers::toUtf8(r.error));

        nlohmann::json response;
        response["success"] = true;
        response["row_count"] = static_cast<int>(r.rows.size());
        response["execution_time_ms"] = static_cast<int>(r.executionTimeMs);

        nlohmann::json cols = nlohmann::json::array();
        for (size_t i = 0; i < r.columnNames.size(); ++i)
        {
            nlohmann::json c{
                {"name", MCPToolHelpers::toUtf8(r.columnNames[i])}
            };
            if (i < r.columnTypes.size())
                c["type"] = MCPToolHelpers::toUtf8(r.columnTypes[i]);
            cols.push_back(std::move(c));
        }
        response["columns"] = std::move(cols);

        nlohmann::json rows = nlohmann::json::array();
        // Parenthesize to defeat windows.h `min` macro in consumers.
        const int cap = (std::min)(static_cast<int>(r.rows.size()), rowLimit);
        for (int i = 0; i < cap; ++i)
        {
            nlohmann::json rj = nlohmann::json::object();
            for (const auto& cname : r.columnNames)
            {
                auto it = r.rows[i].find(cname);
                const std::wstring v = (it != r.rows[i].end()) ? it->second : L"";
                rj[MCPToolHelpers::toUtf8(cname)] =
                    isNullCell(v) ? nlohmann::json(nullptr)
                                  : nlohmann::json(MCPToolHelpers::toUtf8(v));
            }
            rows.push_back(std::move(rj));
        }
        response["rows"] = std::move(rows);

        if (static_cast<int>(r.rows.size()) > rowLimit)
        {
            response["truncated"] = true;
            response["message"] = "Results truncated to " + std::to_string(rowLimit) + " rows";
        }

        return MCPToolResult::text(response.dump(2));
    }
}
