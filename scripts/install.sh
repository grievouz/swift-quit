#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/Swift Quit.app"
DEST="${SWIFT_QUIT_INSTALL_DIR:-/Applications}/Swift Quit.app"
test -d "$APP"
codesign --verify --deep --strict "$APP"

# Address only this app, never the unrelated upstream Swift Quit process.
if pgrep -f "$DEST/Contents/MacOS/SwiftQuit" >/dev/null; then
  echo "Quit Swift Quit before installing an update." >&2
  exit 1
fi
if [ -e "$DEST" ]; then
  INSTALLED_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEST/Contents/Info.plist")
  if [ "$INSTALLED_ID" != io.github.grievouz.SwiftQuit ]; then
    echo "Another app already occupies $DEST; move it before installing." >&2
    exit 1
  fi
  rm -rf "$DEST"
fi
ditto "$APP" "$DEST"
codesign --verify --deep --strict "$DEST"
echo "Installed: $DEST"
