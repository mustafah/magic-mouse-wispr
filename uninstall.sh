#!/bin/bash
set -euo pipefail

# wispr-tap uninstaller

LABEL="com.wispr-tap"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$SCRIPT_DIR}"
BIN_PATH="$INSTALL_DIR/wispr-tap"
LOG_PATH="$HOME/Library/Logs/wispr-tap.log"

echo "==> Unloading LaunchAgent..."
launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true

echo "==> Removing files..."
rm -f "$PLIST_PATH" "$BIN_PATH" "$LOG_PATH"

echo "wispr-tap removed."