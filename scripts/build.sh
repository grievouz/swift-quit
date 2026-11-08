#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(cat VERSION)"
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must contain a semantic version such as 1.0.0" >&2
  exit 1
fi
APP="build/Swift Quit.app"
BUNDLE_ID="io.github.grievouz.SwiftQuit"
SIGN_ID="${SWIFT_QUIT_SIGN_ID:--}"
BUILD_ARGS=(-c release --product SwiftQuit)
if [ "${SWIFT_QUIT_UNIVERSAL:-0}" = 1 ]; then
  BUILD_ARGS+=(--arch arm64 --arch x86_64)
fi
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
RESOURCE_BUNDLE="$BIN_DIR/SwiftQuit_SwiftQuit.bundle"
test -d "$RESOURCE_BUNDLE"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Licenses"
cp "$BIN_DIR/SwiftQuit" "$APP/Contents/MacOS/SwiftQuit"
cp -R "$RESOURCE_BUNDLE" "$APP/Contents/Resources/"
cp LICENSE "$APP/Contents/Resources/Licenses/SwiftQuit-GPL-3.0.txt"
cp LICENSES/Hush-MIT.txt "$APP/Contents/Resources/Licenses/"
cp NOTICE.md "$APP/Contents/Resources/Licenses/"

# Derive the Finder/Dock icon from the same source used inside the app.
ICON_TEMP="$(mktemp -d)"
trap 'rm -rf "$ICON_TEMP"' EXIT
ICONSET="$ICON_TEMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" Sources/SwiftQuit/Resources/AppIcon.png \
    --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" Sources/SwiftQuit/Resources/AppIcon.png \
    --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Swift Quit</string>
  <key>CFBundleDisplayName</key><string>Swift Quit</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key><string>SwiftQuit</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAccessibilityUsageDescription</key><string>Swift Quit needs Accessibility access to detect open app windows.</string>
</dict></plist>
PLIST
codesign --force --options runtime --identifier "$BUNDLE_ID" --sign "$SIGN_ID" "$APP"
codesign --verify --deep --strict "$APP"
echo "Built: $APP"
