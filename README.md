# Standup

A native macOS menu bar app that reminds you to stand up and drink water at intervals you set.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- Lives in the menu bar — no Dock icon
- Separate intervals for stand-up and water reminders (5–120 min)
- Live countdown timers
- Animated full-screen reminder overlays
- Expandable panel with wellness tips
- Google Material color scheme

## Install

**Requirements:** macOS 13 Ventura or later, Xcode Command Line Tools

```bash
# Install CLT if needed
xcode-select --install

# Clone and install
git clone https://github.com/YOUR_USERNAME/standup.git
cd standup
chmod +x install.sh
./install.sh
```

This builds the app from source and installs it to `/Applications/Standup.app`.

> First launch may be blocked by Gatekeeper since the app isn't notarized.
> Go to **System Settings → Privacy & Security → Open Anyway** to allow it.

## Usage

- **Left-click** the menu bar icon to open the settings panel
- **Right-click** the menu bar icon → **Quit Standup** to exit
- Hit **Test** on any card to preview the reminder animation
- Click **Start Reminders** to begin the countdown
- Click the **⤢** expand button for a larger panel with wellness tips

## Build manually

```bash
chmod +x build.sh
./build.sh
open build/Standup.app
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
```
