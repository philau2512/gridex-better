#!/usr/bin/env bash
# Quick build script for Gridex on Windows
# Usage:
#   ./build-win.sh              # Build dev version
#   ./build-win.sh 0.1.13       # Build with specific version
#   ./build-win.sh --run        # Build and run Gridex.exe immediately

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=""
RUN_APP=false

for arg in "$@"; do
  if [ "$arg" == "--run" ] || [ "$arg" == "-r" ]; then
    RUN_APP=true
  else
    VERSION="$arg"
  fi
done

echo "==> Building Gridex (Windows x64 Unpackaged)..."
if [ -n "$VERSION" ]; then
  powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/windows/scripts/build-unpackaged.ps1" -Version "$VERSION"
else
  powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/windows/scripts/build-unpackaged.ps1"
fi

EXE_PATH="$SCRIPT_DIR/windows/Gridex/x64/Release/Gridex/Gridex.exe"
if [ ! -f "$EXE_PATH" ]; then
  EXE_PATH="$SCRIPT_DIR/windows/x64/Release/Gridex/Gridex.exe"
fi

if [ -f "$EXE_PATH" ]; then
  echo ""
  echo "========================================================"
  echo " [SUCCESS] Gridex.exe built successfully!"
  echo " Location: $EXE_PATH"
  echo "========================================================"
  if [ "$RUN_APP" = true ]; then
    echo "==> Launching Gridex.exe..."
    "$EXE_PATH" &
  fi
else
  echo "[ERROR] Gridex.exe not found at expected path: $EXE_PATH"
  exit 1
fi
