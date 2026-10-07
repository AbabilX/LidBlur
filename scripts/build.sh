#!/bin/bash
# Builds LidBlur.app into ./build
# VERSION and BUILD_NUMBER override the values in Resources/Info.plist (used by the release workflow).
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="build/LidBlur.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/LidBlur" "$APP/Contents/MacOS/LidBlur"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -n "${VERSION:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
fi
if [ -n "${BUILD_NUMBER:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
fi

# Synced folders (iCloud Desktop, etc.) add attributes that codesign rejects.
xattr -cr "$APP"
codesign --force --sign - "$APP"
echo "Built $APP"
