#!/bin/bash
# Builds LidBlur.app and packages it into build/LidBlur.dmg
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build.sh

DMG="build/LidBlur.dmg"
# Stage outside the project so synced-folder attributes don't break the signature.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

ditto build/LidBlur.app "$STAGE/LidBlur.app"
xattr -cr "$STAGE/LidBlur.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "LidBlur" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
echo "Built $DMG"
