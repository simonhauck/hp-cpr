# HP-CPR Companion

Flutter app as a companion for the **High-Performance CPR standard**. The app is intended to support the resuscitation workflow with timing: resuscitation duration, medication administration, rhythm analyses, and further steps.

> **Status:** The Zeitnehmer can start a Reanimationsfall immediately or with a corrected Startzeit, run the Druckphase countdown, enter the Analysephase, record a Rhythmusanalyse result, skip it, and return to the Druckphase. Adrenalin and Amiodaron hints are implemented, the case can be interrupted by ROSC, resumed after a rearrest, and ended with an in-app summary, and active, completed, and Verworfene Reanimationsfälle are stored locally in the Einsatzlog. Messwerte and free-text notes are recorded in a separate view and included in the summary.

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

# Android APKs, output under build/app/outputs/flutter-apk/
flutter build apk --debug
flutter build apk --release # release-mode, debug-signed by the current signing config

# Quality checks
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --platform chrome
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

## Delivery

The public web app is available at <https://simonhauck.github.io/hp-cpr/>. It serves the latest GitHub Release, not `main`.

### Pull requests

Every pull request runs the same checks in CI:

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `flutter test --platform chrome`
- `flutter gen-l10n` plus a diff check on `lib/l10n`
- `flutter build web --release`
- `flutter build apk --release`
- Conventional PR title and exactly one type label

The type label follows the PR title:

| Title type | Label |
| --- | --- |
| `fix` | `bug` |
| `feat` | `feature` |
| `docs` | `documentation` |
| everything else | `maintenance` |

release-please PRs are exempt from the label check.

### Releases

release-please keeps one release PR open. Merge it when you want to cut a release. Merging it bumps `pubspec.yaml` (including the `+build` number) and `CHANGELOG.md`; the delivery workflow then checks the merged commit, creates the `vX.Y.Z` tag and GitHub Release, deploys the release build to Pages, and attaches:

- `hp-cpr-<version>-debug-signed.apk` — release-mode, debug-signed, for testing only
- `hp-cpr-web-<version>.zip`

The release PR itself does not run CI because release-please uses `GITHUB_TOKEN`. The merged release commit is checked before anything is tagged or deployed.

Direct pushes to `main` are allowed, but they are not checked before they land. Force pushes and deletions are blocked. To catch problems early, enable the local hook once:

```bash
git config core.hooksPath .githooks
```

`nix develop` does this automatically when `.githooks` exists.

### Rollback

Revert the bad commit on `main` and merge a new release PR. The live page stays on the previous release until the new release is published. For the APK, use the previous GitHub Release asset. Play Store rollback will be documented with the Play workflow.

## Project structure

```text
lib/
├── app.dart                                    # MaterialApp, theme, localization, dependencies
├── main.dart                                   # entry point
├── core/
│   ├── app_info.dart                           # installed version via package_info_plus
│   ├── clock.dart                              # wall-clock + monotonic time source
│   └── wake_lock.dart                          # keeps the screen awake during a case
├── features/
│   ├── about/
│   │   └── presentation/about_page.dart         # app name, version, copyright
│   ├── einsatzlog/
│   │   └── presentation/einsatzlog_page.dart    # local case log + deletion
│   ├── legal/
│   │   └── presentation/legal_page.dart         # Rechtliches and the license page
│   ├── messwerte/
│   │   └── presentation/
│   │       ├── messwert_erfassen_dialog.dart    # two-step measurement entry
│   │       ├── messwert_format.dart             # value formatting + icons
│   │       ├── messwerte_page.dart              # measurements and notes
│   │       └── notiz_erfassen_dialog.dart       # free-text note entry
│   ├── reanimationsfall/
│   │   ├── data/
│   │   │   ├── reanimationsfall_session.dart    # load/restore/persist a case
│   │   │   ├── reanimationsfall_state_json.dart # local state codec
│   │   │   └── reanimationsfall_store.dart      # store interface + shared_preferences
│   │   ├── domain/
│   │   │   ├── adrenalin.dart                   # Adrenalin doses + Zeitfenster state
│   │   │   ├── amiodaron.dart                   # Amiodaron doses + hint state
│   │   │   ├── messwert.dart                    # Messwerte + free-text notes
│   │   │   ├── reanimationsfall.dart           # Startzeit, Reanimationsphase, read model
│   │   │   ├── rhythmusanalyse.dart            # Rhythmusanalyse result types
│   │   │   └── schock.dart                     # Schock events and undo entries
│   │   └── presentation/
│   │       ├── adrenalin_panel.dart            # Adrenalin Zeitfenster bar
│   │       ├── amiodaron_panel.dart            # Amiodaron hint + last dose
│   │       ├── custom_startzeit_dialog.dart    # custom backdate entry
│   │       ├── end_reanimationsfall_dialog.dart # ending reason
│   │       ├── phase_action_bar.dart           # phase actions + result summary
│   │       ├── reanimationsfall_page.dart      # running Reanimationsfall
│   │       ├── reanimationsfall_summary_page.dart # in-app case summary
│   │       ├── rhythmusanalyse_dialog.dart     # two-step result flow
│   │       ├── rhythmusanalyse_format.dart     # result labels
│   │       ├── rhythmusanalyse_notiz_dialog.dart
│   │       ├── schock_energie_dialog.dart      # optional Schock energy
│   │       ├── skip_rhythmusanalyse_dialog.dart
│   │       ├── start_card.dart                 # shared start-choice card shell
│   │       ├── start_page.dart                 # new Reanimationsfall + backdated Startzeit
│   │       └── timer_format.dart               # MM:SS / H:MM:SS formatting
│   ├── leitlinienprofil/
│   │   ├── domain/leitlinienprofil.dart        # ERC 2025 / AHA 2025
│   │   └── presentation/
│   │       └── leitlinienprofil_chip.dart      # read-only Leitlinienprofil chip
│   └── settings/
│       ├── domain/app_settings.dart            # Leitlinienprofil selection, alerts
│       └── presentation/settings_page.dart     # settings form
├── ui/
│   ├── layout/
│   │   ├── page_layout.dart                    # breakpoints + density tokens
│   │   └── page_scaffold.dart                  # shared page frame
│   └── navigation/
│       ├── app_destination.dart                # menu destinations
│       ├── app_drawer.dart                     # drawer + menu button
│       └── app_routes.dart                     # destination builders
└── l10n/
    ├── app_de.arb                              # German UI strings
    └── app_localizations*.dart                 # generated
test/
├── app_settings_test.dart                      # settings behavior
├── app_test.dart                               # app-seam flows, persistence, and log
├── reanimationsfall_test.dart                  # start, phases, drugs, ROSC, and Messwerte
├── reanimationsfall_state_json_test.dart       # local state codec round-trips
├── reanimationsfall_store_test.dart            # shared_preferences store behavior
├── timer_format_test.dart                      # timer and wall-clock formatting
└── support/                                    # fake clock and wake lock
android/                                        # Android target
web/                                            # web target
flake.nix                                       # Nix dev shell
LICENSE                                         # MIT license
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

## Clinical review

The AHA 2025 profile gives no explicit shock-count trigger for the second
Amiodaron dose. The app therefore suggests it in the next CPR block after the
first dose (after Schock 4 when the first dose followed Schock 3). This
operational choice, the medication behavior across ROSC, and any local HP-CPR
deviations need clinical review before release.

## License

HP-CPR is released under the [MIT License](LICENSE).

## Project metadata

- Flutter project name: `hp_cpr`
- Android `applicationId` and namespace: `de.simonhauck.hp_cpr`
- Web app title: `HP-CPR`
- Repository: [simonhauck/hp-cpr](https://github.com/simonhauck/hp-cpr) (public)
