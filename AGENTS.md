# AGENTS.md

## Projekt

Flutter-Companion-App für den High-Performance-CPR-Standard. Die App unterstützt den Reanimationsablauf mit Zeit- und Ablaufinformationen.

## Befehle

Wenn die Umgebung nicht bereits über `nix develop` oder direnv aktiv ist:

```bash
nix develop --command flutter <command>
```

Qualitätssicherung vor jedem Abschluss:

```bash
flutter analyze
flutter test
```

Builds:

```bash
flutter build web --release
flutter build apk --debug
```

## UI-Sprache

- Die gesamte sichtbare Oberfläche ist deutsch.
- Keine hartcodierten UI-Texte: neue Strings in `lib/l10n/app_de.arb` ergänzen und `flutter gen-l10n` ausführen.
- Die generierten `app_localizations*.dart`-Dateien werden versioniert.
- Die App ist aktuell in `lib/app.dart` fest auf `Locale('de')` gesetzt.

## Plattformen

- Android und Web sind aktive Ziele.
- iOS wird erst ergänzt, wenn macOS/Xcode verfügbar ist. Keine iOS-Plattformdateien auf Linux erzeugen.
- Der Nix-Dev-Shell enthält Android SDK 36, Build-Tools 36.0.0 und NDK 28.2. Bei einem Flutter-Upgrade die Versionen in `flake.nix` prüfen und `flutter doctor -v` ausführen.

## Architektur

- Feature-first-Struktur unter `lib/features/<feature>/presentation/`.
- Keine fachliche CPR-Logik erfinden; der konkrete HP-CPR-Ablauf wird noch abgestimmt.
- Neue Features erst nach Abstimmung der fachlichen Anforderungen implementieren.

## MCP

Der Dart-/Flutter-MCP-Server ist in `opencode.json` konfiguriert und wird direkt über `dart mcp-server` gestartet. OpenCode muss dafür aus dem Nix-Dev-Shell laufen, damit `dart` im `PATH` liegt. Wenn ein gemeinsamer OpenCode-Hintergrunddienst bereits außerhalb der Dev-Shell läuft, `opencode --standalone` verwenden oder den Dienst vor dem Start beenden und innerhalb der Dev-Shell neu starten. Nach Codeänderungen an einer laufenden App Hot Reload oder Hot Restart verwenden.
