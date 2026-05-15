# remindMeToStandUp

A native macOS menu bar app that reminds you to stand up and drink water at intervals you set.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Download

**[⬇ Download the latest DMG](https://github.com/aadityesh/remindMeToStandUp/releases/latest)**

1. Open the `.dmg` file
2. Drag **Standup** into your **Applications** folder
3. Launch it from Applications or Spotlight

**If macOS says "damaged and can't be opened"** — this is a Gatekeeper false positive on unsigned apps. Fix it by running this once in Terminal:
```bash
xattr -cr /Applications/Standup.app
```
Then launch the app normally. When macOS asks if you're sure, click **Open**.

> The app is not notarized (requires a paid Apple Developer account). The `xattr` command simply removes the quarantine flag macOS adds to downloaded files.

---

## Features

- Lives in the menu bar — no Dock icon
- Separate intervals for stand-up and water reminders (5–120 min)
- Live countdown timers
- Animated full-screen reminder overlays
- Expandable panel with wellness tips
- Google Material color scheme

## Build from source

**Requirements:** macOS 13 Ventura or later, Xcode Command Line Tools

```bash
xcode-select --install   # if needed

git clone https://github.com/aadityesh/remindMeToStandUp.git
cd remindMeToStandUp
chmod +x install.sh
./install.sh
```

## Usage

- **Left-click** the menu bar icon to open the settings panel
- **Right-click** the menu bar icon → **Quit Standup** to exit
- Hit **Test** on any card to preview the reminder animation
- Click **Start Reminders** to begin the countdown
- Click **⤢** to expand the panel

## Release a new version

```bash
./release.sh 1.1   # builds, creates DMG, uploads to GitHub Releases
```

## Project structure

```
Sources/Standup/
  StandupApp.swift      — App entry point
  AppDelegate.swift     — Status item, popover, right-click menu
  TimerManager.swift    — Timer scheduling and countdown state
  SettingsView.swift    — Menu bar popover UI
  ReminderView.swift    — Animated floating overlay
make_icon.swift         — Generates AppIcon.icns at build time
build.sh                — Build script
install.sh              — One-shot build + install to /Applications
release.sh              — Build + package DMG + publish GitHub Release
```
