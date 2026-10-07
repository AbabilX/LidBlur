#!/bin/bash
# Installs the newest LidBlur release into /Applications and launches it.
#   curl -fsSL https://raw.githubusercontent.com/AbabilX/LidBlur/main/install.sh | bash
set -euo pipefail

REPO="AbabilX/LidBlur"
APP="LidBlur.app"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "LidBlur only runs on macOS." >&2
    exit 1
fi
if [ "$(uname -m)" != "arm64" ]; then
    echo "LidBlur needs an Apple silicon Mac." >&2
    exit 1
fi

echo "Finding the newest LidBlur release..."
# The releases list includes pre-releases, which /releases/latest skips.
URL="$(curl -fsSL "https://api.github.com/repos/$REPO/releases" \
    | grep -o '"browser_download_url": *"[^"]*LidBlur\.dmg"' \
    | head -n 1 \
    | sed 's/.*"\(https[^"]*\)"/\1/')"
if [ -z "$URL" ]; then
    echo "Couldn't find a LidBlur.dmg in the releases of $REPO." >&2
    exit 1
fi

WORK="$(mktemp -d)"
MOUNT="$WORK/mount"
cleanup() {
    hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup EXIT

echo "Downloading $URL"
curl -fL --progress-bar -o "$WORK/LidBlur.dmg" "$URL"

mkdir "$MOUNT"
hdiutil attach "$WORK/LidBlur.dmg" -nobrowse -readonly -mountpoint "$MOUNT" -quiet

DEST="/Applications"
if [ ! -w "$DEST" ]; then
    DEST="$HOME/Applications"
    mkdir -p "$DEST"
fi

pkill -x LidBlur 2>/dev/null || true
rm -rf "$DEST/$APP"
ditto "$MOUNT/$APP" "$DEST/$APP"
xattr -dr com.apple.quarantine "$DEST/$APP" 2>/dev/null || true

open "$DEST/$APP"
echo "LidBlur installed in $DEST. Look for the laptop icon in the menu bar."
