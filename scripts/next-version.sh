#!/bin/bash
# Prints the next release version: the newest vX.Y.Z tag with one part bumped.
# Usage: next-version.sh [commit message]
# A message containing [major] or [minor] bumps that part; anything else bumps the patch.
set -euo pipefail
cd "$(dirname "$0")/.."

MESSAGE="${1:-}"
LATEST="$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n 1)"

if [ -z "$LATEST" ]; then
    /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist
    exit 0
fi

IFS=. read -r MAJOR MINOR PATCH <<< "${LATEST#v}"
case "$MESSAGE" in
    *"[major]"*) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    *"[minor]"*) MINOR=$((MINOR + 1)); PATCH=0 ;;
    *) PATCH=$((PATCH + 1)) ;;
esac
echo "$MAJOR.$MINOR.$PATCH"
