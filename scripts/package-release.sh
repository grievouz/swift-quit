#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
TAG="${1:?usage: scripts/package-release.sh v1.2.3}"
if ! [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a stable release tag like v1.2.3" >&2
  exit 1
fi
VERSION="${TAG#v}"
if [ "$VERSION" != "$(cat VERSION)" ]; then
  echo "Release tag must match VERSION" >&2
  exit 1
fi
if [ -n "$(git status --porcelain --untracked-files=normal)" ]; then
  echo "Commit all source changes before packaging matching source." >&2
  exit 1
fi
SWIFT_QUIT_UNIVERSAL=1 SWIFT_QUIT_SIGN_ID=- ./scripts/build.sh
APP="build/Swift Quit.app"
for arch in arm64 x86_64; do
  lipo "$APP/Contents/MacOS/SwiftQuit" -verify_arch "$arch"
done
DEST="build/release"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$DEST"
ditto "$APP" "$STAGE/Swift Quit.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Swift Quit" -srcfolder "$STAGE" -ov -format UDZO \
  "$DEST/swift-quit-${VERSION}-universal.dmg"
hdiutil verify "$DEST/swift-quit-${VERSION}-universal.dmg"
ditto -c -k --keepParent "$APP" "$DEST/swift-quit-${VERSION}-universal.zip"
git archive --format=tar.gz --prefix="swift-quit-${VERSION}/" \
  -o "$DEST/swift-quit-${VERSION}-source.tar.gz" HEAD
(
  cd "$DEST"
  shasum -a 256 "swift-quit-${VERSION}-universal.dmg" \
    "swift-quit-${VERSION}-universal.zip" \
    "swift-quit-${VERSION}-source.tar.gz" > SHA256SUMS
)
echo "Release assets ready in $DEST"
