@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "VERSION=%~1"
if "%VERSION%"=="" set "VERSION=0.1.0"
set "CHANNEL=%~2"
if "%CHANNEL%"=="" set "CHANNEL=stable"

echo ========================================================
echo  Packaging Gridex Installer (v%VERSION% - %CHANNEL%)
echo ========================================================

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%windows\scripts\build-and-pack.ps1" -Version "%VERSION%" -Channel "%CHANNEL%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Packaging failed with error code %ERRORLEVEL%!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo  [SUCCESS] Full installer created successfully!
echo  Artifacts located at: %SCRIPT_DIR%windows\Releases\
echo   - Installer: Gridex-%CHANNEL%-Setup.exe
echo   - Portable:  Gridex-%CHANNEL%-Portable.zip
echo ========================================================
echo.
pause
