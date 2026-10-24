# HP-CPR Companion

Private Flutter app as a companion for the **High-Performance CPR standard**. The app is intended to support the resuscitation workflow with timing: resuscitation duration, medication administration, rhythm analyses, and further steps.

> **Status:** First feature slice. The Zeitnehmer can start a new Reanimationsfall immediately or with a corrected Startzeit and watch the Druckphase with the 2-minute compression countdown. The Analysephase, medication timers, and the Einsatzlog are still to come.

## Goals

| Platform | Status |
| --- | --- |
| Android | ✅ prepared and built |
| Web | ✅ prepared and built |
| iOS | ⏳ later, requires macOS with Xcode |

## Prerequisites

- NixOS or another Linux with Nix flakes enabled
- Optional: [direnv](https://direnv.net/) to automatically enter the development environment
- For Android tests: a device connected via USB (an emulator is not part of the dev shell)

## Development environment

All required tools are provided by the Nix flake:

- Flutter 3.47.4 and Dart 3.13.3
- JDK 21
- Android SDK 36, Build-Tools 36.0.0, NDK 28.2, and CMake
- Chromium for web development
- Git, GitHub CLI, ripgrep, jq, and other CLI tools

```bash
nix develop
```

The first invocation downloads and builds the dependencies and may take some time. Afterwards, check the toolchain:

```bash
flutter doctor -v
```

With direnv, a one-time `direnv allow` is enough; the dev shell is then activated automatically.

### Updating Nix dependencies

```bash
nix flake update
nix develop
```

The exact versions are pinned in `flake.lock`. The dev shell currently uses `nixos-unstable` so that a current stable Flutter version is available.

## Getting started

```bash
flutter pub get

# Start web in the browser
flutter run -d chrome

# Alternatively, start only a web server (e.g. under WSL2)
flutter run -d web-server --web-port 8080

# Show available devices
flutter devices

# Start the Android app on a connected device
flutter run -d <device-id>
```

### Builds

```bash
# Web release, output under build/web
flutter build web --release

# Android debug APK, output under build/app/outputs/flutter-apk/
flutter build apk --debug

# Quality checks
flutter analyze
flutter test
```

### Android device on NixOS

For `adb` and Flutter to see the device without root, enable ADB in the NixOS configuration:

```nix
programs.adb.enable = true;
```

After `nixos-rebuild switch`, connect the device and check:

```bash
adb devices
```

Under WSL2, the USB device may first need to be passed through to the distribution with `usbipd-win`.

## OpenCode and Dart MCP

The project contains an `opencode.json` with the official Dart/Flutter MCP server. The server is started directly via `dart mcp-server`, without `nix develop` in the MCP command. For this, OpenCode itself must be started from the Nix dev shell so that `dart` is on the `PATH`:

```bash
nix develop
opencode --standalone
```

`--standalone` matters when an OpenCode background service is already running outside the dev shell. Otherwise OpenCode would reuse that service; the MCP process inherits its `PATH` and cannot find `dart` (`NotFound: ChildProcess.spawn`). With `--standalone`, OpenCode starts a private server with the current shell's environment.

If you deliberately want to use the shared background service, stop it first and then restart OpenCode inside the dev shell:

```bash
nix develop
opencode service stop
opencode
```

Check the status in the OpenCode TUI via `/mcps`. When using the shared background service, additionally via the CLI:

```bash
opencode mcp list
# ✓ dart  connected
```

The server provides, among other things, analysis, tests, pub, hot reload/restart, the widget inspector, and the connection to the running app via the Dart Tooling Daemon (DTD).

## Project structure

```text
lib/
├── app.dart                                    # MaterialApp, theme, localization, dependencies
├── main.dart                                   # entry point
├── core/
│   ├── clock.dart                              # wall-clock + monotonic time source
│   └── wake_lock.dart                          # keeps the screen awake during a case
├── features/
│   ├── reanimationsfall/
│   │   ├── domain/
│   │   │   └── reanimationsfall.dart           # Startzeit, Reanimationsphase, read model
│   │   └── presentation/
│   │       ├── reanimationsfall_page.dart      # running Reanimationsfall
│   │       ├── custom_startzeit_dialog.dart    # custom backdate entry
│   │       ├── start_page.dart                 # new Reanimationsfall + backdated Startzeit
│   │       └── timer_format.dart               # MM:SS / H:MM:SS formatting
│   ├── leitlinienprofil/
│   │   ├── domain/leitlinienprofil.dart        # ERC 2025 / AHA 2025
│   │   └── presentation/
│   │       └── leitlinienprofil_chip.dart      # read-only Leitlinienprofil chip
│   └── settings/
│       └── domain/app_settings.dart            # Leitlinienprofil selection
└── l10n/
    ├── app_de.arb                              # German UI strings
    └── app_localizations*.dart                 # generated
test/
├── app_test.dart                               # start-screen and running-screen flows
├── reanimationsfall_test.dart                  # start, backdate, and timer rules
└── support/                                    # fake clock and wake lock
android/                                        # Android target
web/                                            # web target
flake.nix                                       # Nix dev shell
opencode.json                                   # OpenCode/MCP configuration
```

## Localization

The interface is currently pinned to German (`Locale('de')`). All visible text lives in `lib/l10n/app_de.arb`; new text belongs there as well.

```bash
flutter gen-l10n
```

The generated files under `lib/l10n/` are versioned. If more languages are added later, a corresponding ARB file is added and the fixed locale in `lib/app.dart` is removed.

## Adding iOS later

The iOS files are deliberately not created yet, because building requires macOS with Xcode. On a Mac in the project directory:

```bash
flutter create --platforms=ios .
flutter build ios
```

## Contributing

Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, …) and commit messages are written in English. PRs link the issues they fully resolve with `Closes #<number>` (one keyword per issue) so GitHub closes them on merge. Specs use GitHub sub-issues for their tickets, and dependencies use the native blocked-by relation (`gh issue edit <child> --add-blocked-by <blocker>`). See `AGENTS.md` for the full issue, commit, and PR rules.

## Project metadata

- Flutter project name: `hp_cpr`
- Android `applicationId` and namespace: `de.simonhauck.hp_cpr`
- Web app title: `HP-CPR`
- Repository: [simonhauck/hp-cpr](https://github.com/simonhauck/hp-cpr) (private)
