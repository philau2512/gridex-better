@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "VERSION=%~1"
set "EXE_PATH=%SCRIPT_DIR%windows\Gridex\x64\Release\Gridex\Gridex.exe"
if not exist "%EXE_PATH%" set "EXE_PATH=%SCRIPT_DIR%windows\x64\Release\Gridex\Gridex.exe"

echo ========================================================
echo  Building Gridex (Windows x64 Unpackaged)
echo ========================================================

if "%VERSION%"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%windows\scripts\build-unpackaged.ps1"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%windows\scripts\build-unpackaged.ps1" -Version "%VERSION%"
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build failed with error code %ERRORLEVEL%!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo  [SUCCESS] Build completed!
echo  Output: %EXE_PATH%
echo ========================================================
echo.

if not "%2"=="--no-pause" (
    echo Press any key to exit...
    pause >nul
)
