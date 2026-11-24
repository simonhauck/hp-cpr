# Development setup

How to set up the development environment, run the app, and check your changes. For the project overview, see the [README](../README.md). For CI and releases, see [`delivery.md`](delivery.md).

## Prerequisites

- NixOS or another Linux with Nix flakes enabled
- Optional: [direnv](https://direnv.net/) to enter the development environment automatically
- For Android: a device connected via USB (an emulator is not part of the dev shell)

## Dev shell

All required tools are provided by the Nix flake:

- Flutter and Dart (see `flake.lock` for the exact version)
- JDK 21
- Android SDK 35 and 36, Build-Tools 36.0.0, NDK 28.2, and CMake
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

`nix develop` also points git at the hooks in `.githooks`. The pre-push hook runs format, analyze, and the VM tests. Bypass it only deliberately with `git push --no-verify`. Without the dev shell, enable the hooks once with:

```bash
git config core.hooksPath .githooks
```

### Updating Nix dependencies

```bash
nix flake update
nix develop
```

The exact versions are pinned in `flake.lock`. The dev shell uses `nixos-unstable` so that a current stable Flutter version is available. After a Flutter upgrade, check the Android versions in `flake.nix` and run `flutter doctor -v`.

## Running the app

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

## Quality checks

Run these before opening a pull request; CI runs the same checks:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --platform chrome
```

## Builds

```bash
# Web release, output under build/web
flutter build web --release

# Android APKs, output under build/app/outputs/flutter-apk/
flutter build apk --debug
flutter build apk --release # release-mode, debug-signed by the current signing config
```

## Localization

The interface is pinned to German (`Locale('de')` in `lib/app.dart`). All visible text lives in `lib/l10n/app_de.arb`; new text belongs there as well. Regenerate the Dart files after changing it:

```bash
flutter gen-l10n
```

The generated files under `lib/l10n/` are versioned. If more languages are added later, add a corresponding ARB file and remove the fixed locale in `lib/app.dart`.

## Project structure

```text
lib/
├── app.dart, main.dart       # MaterialApp, theme, localization, entry point
├── core/                     # platform seams: clock, wake lock, vibration, app info
├── features/<feature>/
│   ├── domain/               # domain model (Reanimationsfall, Protokoll, drugs, ...)
│   ├── data/                 # local persistence
│   └── presentation/         # pages, dialogs, and widgets of the feature
├── ui/                       # cross-feature UI: layout tokens, navigation, theme, dialogs
└── l10n/                     # German ARB file and generated localizations
test/                         # widget and unit tests; fakes under test/support/
android/, web/                # platform targets
flake.nix                     # Nix dev shell
```

Domain nouns keep their German term in code identifiers (see [ADR 0001](adr/0001-german-domain-terms-in-code.md)). Layout geometry lives in `lib/ui/layout/page_layout.dart`. [`AGENTS.md`](../AGENTS.md) has the full set of code conventions.

### Project metadata

- Flutter project name: `hp_cpr`
- Android `applicationId` and namespace: `de.simonhauck.hp_cpr`
- Web app title: `HP-CPR`

## Adding iOS later

The iOS files are deliberately not created yet, because building requires macOS with Xcode. On a Mac in the project directory:

```bash
flutter create --platforms=ios .
flutter build ios
```

## Coding agents and the Dart MCP server

The official Dart/Flutter MCP server is configured in `opencode.json` (OpenCode) and `.mcp.json` (Claude Code). It is started directly via `dart mcp-server`, without `nix develop` in the MCP command, so the agent itself must be started from the Nix dev shell so that `dart` is on the `PATH`:

```bash
nix develop
opencode --standalone   # or: claude
```

For OpenCode, `--standalone` matters when an OpenCode background service is already running outside the dev shell. Otherwise OpenCode would reuse that service; the MCP process inherits its `PATH` and cannot find `dart` (`NotFound: ChildProcess.spawn`). With `--standalone`, OpenCode starts a private server with the current shell's environment.

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
