#!/bin/bash
# Builds Portside.app into dist/ from the SwiftPM executable.
set -euo pipefail
cd "$(dirname "$0")/.."

# Prefer the full Xcode toolchain when present (release builds are fine under
# Command Line Tools too, but this keeps parity with `swift test`, which needs it).
if [ -d /Applications/Xcode.app ] && [ -z "${DEVELOPER_DIR:-}" ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

swift build -c release

APP=dist/Portside.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Portside "$APP/Contents/MacOS/Portside"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# A stable local signing identity keeps any granted permissions valid across
# rebuilds; anywhere it doesn't exist (CI, other machines) fall back to ad-hoc.
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Portside Dev"; then
  codesign --force --sign "Portside Dev" "$APP"
else
  codesign --force --sign - "$APP"
fi

echo "Built $APP"
