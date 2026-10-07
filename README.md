<div align="center">

# LidBlur

**Lower your MacBook lid, and the screen blurs.**

A tiny menu bar app that reads the hinge angle sensor and fades a blur over your screen as the lid comes down. Lift the lid and it clears again.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Chip](https://img.shields.io/badge/Apple%20silicon-arm64-lightgrey)

</div>

---

## Why

Someone walks up to your desk. You tip the lid forward out of habit, but the screen is still perfectly readable until it's almost shut. LidBlur makes that gesture actually hide what's on screen, without locking the Mac or putting it to sleep.

## How it works

| Lid angle | Screen |
| --- | --- |
| Above **70°** | Normal |
| **70° → 25°** | Blur and dim grow smoothly as the lid lowers |
| Below **25°** | Fully blurred |
| Lid raised again | Clears automatically |

Both angles are adjustable from the menu.

- Covers every connected display
- Click-through: the overlay never steals focus or blocks input
- Stays out of the way in clamshell mode (lid shut with an external monitor)
- No Dock icon, no windows, no network access, no data collected

## Install

### One command

```bash
curl -fsSL https://raw.githubusercontent.com/AbabilX/LidBlur/main/install.sh | bash
```

This downloads the newest release, copies **LidBlur** into **Applications**, and launches it. A laptop icon appears in the menu bar. Run the same command again to update.

### Manual

1. Download `LidBlur.dmg` from the [releases page](../../releases).
2. Open it and drag **LidBlur** into **Applications**.
3. Launch it.

LidBlur is not notarized by Apple, so macOS blocks a manually downloaded copy the first time. Either:

- Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**, or
- Run this once in Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/LidBlur.app
```

### Uninstall

Quit LidBlur from its menu, then delete `/Applications/LidBlur.app`.

## Menu

| Item | What it does |
| --- | --- |
| **Lid angle** | Live reading from the sensor |
| **Enabled** | Turn the blur on or off |
| **Start Blur At** | Angle where blur begins (50°–100°) |
| **Full Blur At** | Angle where blur is at full strength (15°–45°) |
| **Preview Blur** | Runs a 3 second ramp so you can see the effect |
| **Launch at Login** | Start LidBlur automatically |
| **Quit LidBlur** | Exit |

## Requirements

- macOS 13 or later
- A MacBook with a lid angle sensor

Developed and tested on a MacBook Pro 14" (M4). Other MacBooks with the sensor should work; if yours doesn't have one, the menu shows **Lid sensor not found**.

## Build from source

Needs only the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/AbabilX/LidBlur.git
cd LidBlur
./build.sh
open build/LidBlur.app
```

To package a DMG:

```bash
./dmg.sh
```

## Project layout

```
Sources/LidBlur/
├── main.swift          App entry point
├── AppDelegate.swift   Menu bar item and the angle → blur loop
├── LidSensor.swift     Reads the hinge angle over IOKit HID
├── BlurOverlay.swift   Full-screen blur windows
└── Settings.swift      Preferences stored in UserDefaults
build.sh                Builds and signs LidBlur.app
dmg.sh                  Packages LidBlur.dmg
install.sh              One-command installer
```

## Under the hood

- **Sensor.** The hinge angle comes from Apple's built-in HID sensor (vendor `0x05AC`, product `0x8104`, usage page `0x20`, usage `0x8A`), read as a feature report 30 times a second.
- **Blur.** AppKit's public blur has a fixed strength, so LidBlur sets a variable radius with the private WindowServer call `CGSSetWindowBackgroundBlurRadius`. That is why the app can't ship on the Mac App Store, and why a future macOS release could change how the blur looks.

## Limitations

- LidBlur is a privacy convenience, not a security boundary. It doesn't lock your Mac, and screen recordings or screenshots may capture the content underneath.
- Once the lid is fully shut, macOS turns the display off as usual.

## Contributing

Issues and pull requests are welcome. Reports from other MacBook models are especially useful: include the model, macOS version, and what the **Lid angle** menu item shows.
