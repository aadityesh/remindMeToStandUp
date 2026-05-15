#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "▶ Generating app icon..."
swift make_icon.swift

echo ""
echo "▶ Building Standup..."
swift build -c release

APP="build/Standup.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/Standup "$APP/Contents/MacOS/"

# Copy icon if generated
if [ -f AppIcon.icns ]; then
    cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
    rm AppIcon.icns
fi

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Standup</string>
    <key>CFBundleIdentifier</key>
    <string>com.aadi.standup</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Standup</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS shows "unidentified developer" instead of "damaged"
echo ""
echo "▶ Signing..."
xattr -cr "$APP"   # strip resource forks/quarantine before signing
codesign --force --deep --sign - "$APP"

echo ""
echo "Done! Installing to /Applications..."
