#!/usr/bin/env bash
# Pack full Gridex Windows Release (Setup.exe + Portable.zip + Velopack feeds)
# Usage:
#   ./pack-win.sh               # Pack with default version 0.1.0
#   ./pack-win.sh 0.1.13        # Pack with specific version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-0.1.0}"
CHANNEL="${2:-stable}"

echo "========================================================"
echo " Packaging Gridex Installer (v$VERSION - $CHANNEL)"
echo "========================================================"

powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/windows/scripts/build-and-pack.ps1" -Version "$VERSION" -Channel "$CHANNEL"

OUTPUT_DIR="$SCRIPT_DIR/windows/Releases"
SETUP_EXE="$OUTPUT_DIR/Gridex-$CHANNEL-Setup.exe"

if [ -f "$SETUP_EXE" ]; then
  echo ""
  echo "========================================================"
  echo " [SUCCESS] Full installer created successfully!"
  echo " Artifacts located at: $OUTPUT_DIR"
  echo "  - Installer: Gridex-$CHANNEL-Setup.exe"
  echo "  - Portable:  Gridex-$CHANNEL-Portable.zip"
  echo "========================================================"
else
  echo "[ERROR] Setup.exe not found at: $SETUP_EXE"
  exit 1
fi
