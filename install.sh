#!/bin/bash
set -e

# Requires: macOS 13+, Xcode Command Line Tools
# Install CLT with: xcode-select --install

command -v swift >/dev/null 2>&1 || { echo "Swift not found. Run: xcode-select --install"; exit 1; }

cd "$(dirname "$0")"

echo "▶ Generating icon..."
swift make_icon.swift

echo "▶ Building..."
swift build -c release

APP="build/Standup.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Standup "$APP/Contents/MacOS/"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns" && rm AppIcon.icns

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Standup</string>
    <key>CFBundleIdentifier</key><string>com.aadi.standup</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>Standup</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

echo "▶ Installing to /Applications..."
rm -rf /Applications/Standup.app
cp -r "$APP" /Applications/

echo ""
echo "✓ Installed! Launching Standup..."
open /Applications/Standup.app
