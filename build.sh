#!/bin/bash
# Сглобява Tamagotchi.app.
#   ./build.sh            → build/Tamagotchi.app за този Мак
#   ./build.sh install    → и го слага в /Applications, и го пуска
#   ./build.sh universal  → за Intel + Apple Silicon, плюс build/Tamagotchi.zip
set -euo pipefail
cd "$(dirname "$0")"

APP=build/Tamagotchi.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
# номер на версията: в GitHub е номерът на сглобяването, на ръка е 0 (няма да се „обновява“ надолу)
BUILD_NUMBER="${BUILD_NUMBER:-0}"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$APP/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "1.$BUILD_NUMBER" "$APP/Contents/Info.plist"

if [ "${1:-}" = "universal" ]; then
  for arch in arm64 x86_64; do
    xcrun swiftc -O -target "$arch-apple-macos11" Sources/*.swift -o "build/Tamagotchi-$arch"
  done
  lipo -create build/Tamagotchi-arm64 build/Tamagotchi-x86_64 -output "$APP/Contents/MacOS/Tamagotchi"
  rm build/Tamagotchi-arm64 build/Tamagotchi-x86_64
else
  xcrun swiftc -O Sources/*.swift -o "$APP/Contents/MacOS/Tamagotchi"
fi

codesign --force --deep --sign - "$APP"
echo "✓ $APP"

if [ "${1:-}" = "universal" ]; then
  ditto -c -k --keepParent "$APP" build/Tamagotchi.zip
  echo "✓ build/Tamagotchi.zip"
fi

if [ "${1:-}" = "install" ]; then
  pkill -x Tamagotchi 2>/dev/null || true
  rm -rf /Applications/Tamagotchi.app
  cp -R "$APP" /Applications/
  open /Applications/Tamagotchi.app
  echo "✓ /Applications/Tamagotchi.app"
fi
