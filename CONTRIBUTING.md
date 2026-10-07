# Contributing to LidBlur

Thanks for helping out. Bug reports, compatibility reports, and pull requests are all welcome.

## Getting set up

You need a Mac with the Xcode Command Line Tools:

```bash
xcode-select --install
```

Then:

```bash
git clone https://github.com/AbabilX/LidBlur.git
cd LidBlur
make run
```

| Command | What it does |
| --- | --- |
| `make build` | Builds `build/LidBlur.app` |
| `make run` | Builds and launches it |
| `make dmg` | Builds `build/LidBlur.dmg` |
| `make install` | Builds and copies into `/Applications` |
| `make clean` | Removes build output |

Xcode is not required. If you prefer it, open `Package.swift`.

## Where things live

```
Sources/LidBlur/
├── App/         Entry point, menu bar item, the angle → blur loop
├── Sensor/      Hinge angle reading over IOKit HID
├── Overlay/     Blur windows and the private WindowServer calls
└── Settings/    Preferences stored in UserDefaults
Resources/       Info.plist
scripts/         Build, packaging, and versioning scripts
install.sh       One-command installer served from the main branch
```

## Reporting a bug or a new MacBook model

The lid sensor differs between models, so hardware reports are valuable even when everything works. Please include:

- MacBook model and macOS version
- What the **Lid angle** menu item shows with the lid fully open and half closed
- Whether **Preview Blur** shows a blur or only a dim

## Pull requests

1. Fork the repo and create a branch from `main`.
2. Keep the change focused; one fix or feature per pull request.
3. Test on real hardware. The sensor and the blur can't be exercised in CI, so say which model and macOS version you tested on.
4. Open the pull request and fill in the template.

## Code guidelines

- Match the style of the surrounding code.
- Keep the app dependency-free: AppKit, IOKit, and ServiceManagement only.
- Private API declarations go in `Sources/LidBlur/Overlay/CGSPrivate.swift` and nowhere else, so the private surface stays easy to audit.
- The app must stay offline. No network calls, analytics, or telemetry.

## Releases

Releases are automatic. When a commit that touches `Sources/`, `Resources/`, `scripts/`, or `Package.swift` lands on `main`, the [release workflow](.github/workflows/release.yml):

1. Takes the newest `vX.Y.Z` tag and bumps it.
2. Builds `LidBlur.dmg` with that version.
3. Publishes a GitHub release with generated notes and the DMG attached.

The patch number is bumped by default. Put `[minor]` or `[major]` anywhere in the commit message to bump that part instead. Changes that only touch docs don't trigger a release. Versions below 1.0 are published as pre-releases.

The version in `Resources/Info.plist` is only used for local builds; release builds get theirs from the tag.
