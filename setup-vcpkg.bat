@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo  Setup vcpkg and dependencies for Gridex
echo ========================================================

if not exist "C:\vcpkg" (
    echo [1/3] Cloning vcpkg to C:\vcpkg...
    git clone https://github.com/microsoft/vcpkg.git C:\vcpkg
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to clone vcpkg. Please check your internet connection or git installation.
        pause
        exit /b %ERRORLEVEL%
    )
) else (
    echo [1/3] C:\vcpkg already exists.
)

if not exist "C:\vcpkg\vcpkg.exe" (
    echo [2/3] Bootstrapping vcpkg...
    call C:\vcpkg\bootstrap-vcpkg.bat
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to bootstrap vcpkg.
        pause
        exit /b %ERRORLEVEL%
    )
) else (
    echo [2/3] vcpkg.exe is ready.
)

echo [3/3] Installing required libraries (sqlite3, libpq, libmariadb, openssl, etc.)...
echo This may take a few minutes...
C:\vcpkg\vcpkg.exe install sqlite3 libpq libmariadb openssl hiredis libssh2 nlohmann-json cpp-httplib mongo-cxx-driver --triplet x64-windows

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] vcpkg package installation failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo  [SUCCESS] All vcpkg dependencies installed successfully!
echo  You can now run 'build-win' or './build-win.sh'
echo ========================================================
pause
