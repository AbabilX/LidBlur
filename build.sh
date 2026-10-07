#!/bin/bash
# Builds LidBlur.app into ./build
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="build/LidBlur.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/LidBlur" "$APP/Contents/MacOS/LidBlur"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>LidBlur</string>
    <key>CFBundleIdentifier</key>
    <string>com.murad.lidblur</string>
    <key>CFBundleExecutable</key>
    <string>LidBlur</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

xattr -cr "$APP"
codesign --force --sign - "$APP"
echo "Built $APP"
