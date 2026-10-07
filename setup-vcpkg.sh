#!/usr/bin/env bash
# Automated vcpkg setup script for Git Bash

set -e

echo "========================================================"
echo " Setup vcpkg and dependencies for Gridex"
echo "========================================================"

if [ ! -d "/c/vcpkg" ]; then
  echo "[1/3] Cloning vcpkg to C:/vcpkg..."
  git clone https://github.com/microsoft/vcpkg.git /c/vcpkg
else
  echo "[1/3] C:/vcpkg already exists."
fi

if [ ! -f "/c/vcpkg/vcpkg.exe" ]; then
  echo "[2/3] Bootstrapping vcpkg..."
  cmd.exe /c "C:\\vcpkg\\bootstrap-vcpkg.bat"
else
  echo "[2/3] vcpkg.exe is ready."
fi

echo "[3/3] Installing required libraries (sqlite3, libpq, libmariadb, openssl, etc.)..."
echo "This may take a few minutes..."
/c/vcpkg/vcpkg.exe install sqlite3 libpq libmariadb openssl hiredis libssh2 nlohmann-json cpp-httplib mongo-cxx-driver --triplet x64-windows

echo ""
echo "========================================================"
echo " [SUCCESS] All vcpkg dependencies installed successfully!"
echo " You can now run './build-win.sh'"
echo "========================================================"
