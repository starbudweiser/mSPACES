#!/bin/bash
# Compile mSPACES, signe et installe dans ~/Applications/Applications Personnelles.
set -euo pipefail
cd "$(dirname "$0")"
DEV=0; [ "${1:-}" = dev ] && { DEV=1; shift; }
VERSION="${1:-1.0.3}"
BID="com.starbudweiser.mspaces"; ANAME="mSPACES"
[ $DEV = 1 ] && { BID="$BID.dev"; ANAME="mSPACES-dev"; }
swift build -c release
APP="build/$ANAME.app"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/mSPACES "$APP/Contents/MacOS/"
# Icône
ICS=build/icon.iconset; rm -rf "$ICS"; mkdir -p "$ICS"
swift assets/icon.swift build/icon1024.png
for s in 16 32 128 256 512; do
  sips -z $s $s build/icon1024.png --out "$ICS/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) build/icon1024.png --out "$ICS/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICS" -o assets/mSPACES.icns
cp assets/mSPACES.icns "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>mSPACES</string>
<key>CFBundleIdentifier</key><string>$BID</string>
<key>CFBundleName</key><string>mSPACES</string>
<key>CFBundleIconFile</key><string>mSPACES</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>fr</string><string>en</string><string>es</string><string>it</string></array>
</dict></plist>
PL
/Volumes/SKYRIM/TOOLS/MAC/_tools/sign_app.sh "$APP" "$VERSION"
[ $DEV = 1 ] && { echo "Dev : $APP"; exit 0; }
[ $DEV = 1 ] && { echo "Dev : $APP"; exit 0; }
DEST="$HOME/Applications/Applications Personnelles"; mkdir -p "$DEST"
rm -rf "$DEST/mSPACES.app"; cp -R "$APP" "$DEST/"
echo "Installé : $DEST/mSPACES.app"
