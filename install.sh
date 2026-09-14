#!/bin/bash
set -euo pipefail

# wispr-tap installer
# Builds the helper, installs it, and registers a LaunchAgent so it runs at login.

# Where the compiled binary ends up (default: this repo's directory).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$SCRIPT_DIR}"
BIN_PATH="$INSTALL_DIR/wispr-tap"
LABEL="com.wispr-tap"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_PATH="$HOME/Library/Logs/wispr-tap.log"

cd "$SCRIPT_DIR"
echo "==> Building wispr-tap..."
swift build -c release

BUILD_BIN="$(swift build -c release --show-bin-path)/wispr-tap"
echo "==> Installing binary -> $BIN_PATH"
cp "$BUILD_BIN" "$BIN_PATH"
chmod +x "$BIN_PATH"

echo "==> Writing LaunchAgent plist -> $PLIST_PATH"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN_PATH</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$LOG_PATH</string>
  <key>StandardErrorPath</key>
  <string>$LOG_PATH</string>
</dict>
</plist>
PLIST

echo "==> Loading LaunchAgent..."
launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

sleep 1
echo ""
echo "wispr-tap is running. Watch it with:"
echo "  tail -f $LOG_PATH"
echo ""
echo "Usage: DOUBLE 3-finger tap toggles Wispr hands-free."