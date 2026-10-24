# HP-CPR Companion

Private Flutter-App als Begleiter für den **High-Performance-CPR-Standard**. Die App soll den Reanimationsablauf zeitlich unterstützen: Reanimationsdauer, Medikamentengaben, Rhythmusanalysen und weitere Schritte.

> **Status:** Initiales Projekt-Setup. Die fachlichen Funktionen und der konkrete HP-CPR-Ablauf werden noch abgestimmt. Die aktuelle Oberfläche ist ein deutsches Grundgerüst ohne medizinische Logik.

## Ziele

| Plattform | Status |
| --- | --- |
| Android | ✅ vorbereitet und gebaut |
| Web | ✅ vorbereitet und gebaut |
| iOS | ⏳ später, erfordert macOS mit Xcode |

## Voraussetzungen

- NixOS oder ein anderes Linux mit aktivierten Nix-Flakes
- Optional: [direnv](https://direnv.net/) für automatisches Betreten der Entwicklungsumgebung
- Für Android-Tests: ein per USB verbundenes Gerät (ein Emulator ist nicht Teil des Dev-Shells)

## Entwicklungsumgebung

Alle benötigten Werkzeuge werden über die Nix-Flake bereitgestellt:

- Flutter 3.47.4 und Dart 3.13.3
- JDK 21
- Android SDK 36, Build-Tools 36.0.0, NDK 28.2 und CMake
- Chromium für Web-Entwicklung
- Git, GitHub CLI, ripgrep, jq und weitere CLI-Werkzeuge

```bash
nix develop
```

Der erste Aufruf lädt und baut die Abhängigkeiten und kann einige Zeit dauern. Danach die Toolchain prüfen:

```bash
flutter doctor -v
```

Mit direnv genügt alternativ einmalig `direnv allow`; der Dev-Shell wird danach automatisch aktiviert.

### Nix-Abhängigkeiten aktualisieren

```bash
nix flake update
nix develop
```

Die exakten Versionen sind in `flake.lock` festgehalten. Der Dev-Shell nutzt derzeit `nixos-unstable`, damit eine aktuelle stabile Flutter-Version verfügbar ist.

## Erste Schritte

```bash
flutter pub get

# Web im Browser starten
flutter run -d chrome

# Alternativ nur einen Web-Server starten (z. B. unter WSL2)
flutter run -d web-server --web-port 8080

# Verfügbare Geräte anzeigen
flutter devices

# Android-App auf einem verbundenen Gerät starten
flutter run -d <device-id>
```

### Builds

```bash
# Web-Release, Ausgabe unter build/web
flutter build web --release

# Android-Debug-APK, Ausgabe unter build/app/outputs/flutter-apk/
flutter build apk --debug

# Qualitätssicherung
flutter analyze
flutter test
```

### Android-Gerät unter NixOS

Damit `adb` und Flutter das Gerät ohne Root sehen, in der NixOS-Konfiguration ADB aktivieren:

```nix
programs.adb.enable = true;
```

Nach `nixos-rebuild switch` das Gerät anschließen und prüfen:

```bash
adb devices
```

Unter WSL2 muss das USB-Gerät gegebenenfalls zuerst mit `usbipd-win` an die Distribution weitergegeben werden.

## OpenCode und Dart MCP

Das Projekt enthält eine `opencode.json` mit dem offiziellen Dart-/Flutter-MCP-Server. Der Server wird direkt über `dart mcp-server` gestartet, ohne `nix develop` im MCP-Befehl. Dafür muss OpenCode selbst aus der Nix-Dev-Shell gestartet werden, damit `dart` im `PATH` liegt:

```bash
nix develop
opencode --standalone
```

`--standalone` ist wichtig, wenn bereits ein OpenCode-Hintergrunddienst außerhalb der Dev-Shell läuft. OpenCode würde sonst diesen Dienst wiederverwenden; der MCP-Prozess erbt dessen `PATH` und findet `dart` nicht (`NotFound: ChildProcess.spawn`). Mit `--standalone` startet OpenCode einen privaten Server mit der Umgebung der aktuellen Shell.

Wenn du bewusst den gemeinsamen Hintergrunddienst nutzen willst, beende ihn vorher und starte OpenCode anschließend innerhalb der Dev-Shell neu:

```bash
nix develop
opencode service stop
opencode
```

Den Status prüfst du im OpenCode-TUI über `/mcps`. Bei Nutzung des gemeinsamen Hintergrunddienstes zusätzlich per CLI:

```bash
opencode mcp list
# ✓ dart  connected
```

Der Server stellt unter anderem Analyse, Tests, Pub, Hot Reload/Restart, Widget-Inspector und die Verbindung zur laufenden App über den Dart Tooling Daemon (DTD) bereit.

## Projektstruktur

```text
lib/
├── app.dart                              # MaterialApp, Theme und Lokalisierung
├── main.dart                             # Einstiegspunkt
├── features/
│   └── cpr_tracker/
│       └── presentation/
│           └── cpr_tracker_page.dart     # aktuelle Startseite
└── l10n/
    ├── app_de.arb                        # deutsche UI-Texte
    └── app_localizations*.dart           # generiert
test/
└── app_test.dart
android/                                  # Android-Ziel
web/                                      # Web-Ziel
flake.nix                                 # Nix-Dev-Shell
opencode.json                             # OpenCode-/MCP-Konfiguration
```

## Lokalisierung

Die Oberfläche ist derzeit fest auf Deutsch (`Locale('de')`) eingestellt. Alle sichtbaren Texte stehen in `lib/l10n/app_de.arb`; neue Texte gehören ebenfalls dorthin.

```bash
flutter gen-l10n
```

Die generierten Dateien unter `lib/l10n/` werden versioniert. Wenn später weitere Sprachen dazukommen, wird eine passende ARB-Datei ergänzt und die feste Locale in `lib/app.dart` entfernt.

## iOS später ergänzen

Die iOS-Dateien werden bewusst noch nicht angelegt, da zum Bauen macOS mit Xcode erforderlich ist. Auf einem Mac im Projektverzeichnis:

```bash
flutter create --platforms=ios .
flutter build ios
```

## Projekt-Metadaten

- Flutter-Projektname: `hp_cpr`
- Android `applicationId` und Namespace: `de.simonhauck.hp_cpr`
- Web-App-Titel: `HP-CPR`
- Repository: [simonhauck/hp-cpr](https://github.com/simonhauck/hp-cpr) (privat)
