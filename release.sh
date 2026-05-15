#!/bin/bash
set -e

cd "$(dirname "$0")"

VERSION="${1:-1.0}"
DMG_NAME="Standup-v${VERSION}.dmg"
VOLUME_NAME="Standup"
APP="build/Standup.app"
STAGING="/tmp/standup-dmg-staging"

echo "▶ Building Standup v${VERSION}..."
./build.sh

echo ""
echo "▶ Creating DMG..."

# Clean staging area
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Copy app + add /Applications symlink for drag-and-drop install
cp -r "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Create a read-write DMG from staging, then convert to compressed read-only
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDRW \
  -fs HFS+ \
  "build/Standup-rw.dmg" > /dev/null

# Mount it so we can set the window layout
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "build/Standup-rw.dmg" \
  | grep "/Volumes/" | awk '{print $NF}')

# Set Finder window size + icon positions via AppleScript
osascript << APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {400, 100, 900, 400}
    set arrangement of icon view options of container window to not arranged
    set icon size of icon view options of container window to 96
    set position of item "Standup.app"   of container window to {140, 150}
    set position of item "Applications"  of container window to {360, 150}
    close
    open
    update without registering applications
    delay 2
    close
  end tell
end tell
APPLESCRIPT

# Give Finder time to finish, then unmount
sleep 3
hdiutil detach "$MOUNT_DIR" -force > /dev/null

# Convert to compressed, read-only DMG
rm -f "build/$DMG_NAME"
hdiutil convert "build/Standup-rw.dmg" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "build/$DMG_NAME" > /dev/null

rm -f "build/Standup-rw.dmg"
rm -rf "$STAGING"

echo "✓ Created build/$DMG_NAME"
echo ""

# Upload to GitHub Releases
echo "▶ Creating GitHub Release v${VERSION}..."
gh release create "v${VERSION}" \
  "build/$DMG_NAME" \
  --title "Standup v${VERSION}" \
  --notes "## Install

1. Download **${DMG_NAME}**
2. Open it and drag **Standup** into your **Applications** folder
3. Launch Standup from Applications (or Spotlight)
4. If macOS blocks it: **System Settings → Privacy & Security → Open Anyway**

## What's new
- Menu bar app that reminds you to stand up and drink water
- Set your own intervals (5–120 min)
- Animated floating reminder overlays
- Expandable panel with wellness tips"

echo ""
echo "✓ Released! View at: https://github.com/aadityesh/remindMeToStandUp/releases/tag/v${VERSION}"
