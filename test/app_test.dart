import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hp_cpr/app.dart';
import 'package:hp_cpr/features/about/presentation/about_page.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';

import 'support/fake_clock.dart';
import 'support/fake_wake_lock.dart';

void main() {
  late FakeClock clock;
  late FakeWakeLock wakeLock;
  late InMemoryReanimationsfallStore store;

  setUp(() {
    clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    wakeLock = FakeWakeLock();
    store = InMemoryReanimationsfallStore();
    PackageInfo.setMockInitialValues(
      appName: 'HP-CPR',
      packageName: 'de.simonhauck.hp_cpr',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menü öffnen').hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> selectFromDrawer(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text(label)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    AppSettings? settings,
    ReanimationsfallStore? appStore,
  }) async {
    await tester.pumpWidget(
      HpCprApp(
        key: UniqueKey(),
        clock: clock,
        settings: settings,
        wakeLock: wakeLock,
        store: appStore ?? store,
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectInsideViewport(WidgetTester tester, Finder finder) {
    final rect = tester.getRect(finder);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final padding = tester.view.padding;
    final top = padding.top / tester.view.devicePixelRatio;
    final bottom = size.height - padding.bottom / tester.view.devicePixelRatio;

    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(top));
    expect(rect.right, lessThanOrEqualTo(size.width));
    expect(rect.bottom, lessThanOrEqualTo(bottom));
  }

  Future<void> startNow(WidgetTester tester) async {
    await tester.tap(find.text('Jetzt starten'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> openActions(WidgetTester tester) async {
    await tester.tap(find.text('Aktionen'));
    await tester.pumpAndSettle();
  }

  Future<void> recordSchock(WidgetTester tester) async {
    await openActions(tester);
    await tester.scrollUntilVisible(
      find.text('Schock erfassen'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Schock erfassen'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers the two ways to start a Reanimationsfall', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('HP-CPR'), findsOneWidget);
    expect(find.text('Neuer Reanimationsfall'), findsOneWidget);
    expect(find.text('Reanimation startet jetzt'), findsOneWidget);
    expect(find.text('Jetzt starten'), findsOneWidget);
    expect(find.text('Laufende Reanimation'), findsOneWidget);
    expect(find.text('Minuten seit Beginn'), findsOneWidget);
    for (final minutes in ['1', '2', '5', '8', '10', '12', '15']) {
      expect(find.widgetWithText(ActionChip, minutes), findsOneWidget);
    }
    expect(find.text('Eigene Startzeit'), findsOneWidget);
    expect(find.text('ERC 2025'), findsOneWidget);
  });

  testWidgets('starting immediately records time zero and starts the '
      'Druckphase at 2:00', (tester) async {
    await pumpApp(tester);

    await startNow(tester);

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Reanimationsdauer'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Nächste Analyse'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('ERC 2025'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
    expect(wakeLock.enabled, isTrue);
  });

  testWidgets('shows the phase strip, the shock count, and Weitere Aktionen', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    expect(
      find.text('Druckphase · Jetzt 2 Minuten komprimieren'),
      findsOneWidget,
    );
    expect(find.text('Schocks: 0'), findsOneWidget);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Druckphase · Analyse jetzt starten'), findsOneWidget);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    expect(find.text('Analysephase · Jetzt Rhythmus prüfen'), findsOneWidget);
    expect(find.text('Schockbar'), findsOneWidget);
    expect(find.text('Nicht schockbar'), findsOneWidget);
    expect(find.text('ROSC'), findsOneWidget);
    expect(find.text('Unklar'), findsOneWidget);
    expect(find.text('Überspringen'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsNWidgets(2));
    expect(find.byIcon(Icons.flash_off), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.question_mark), findsOneWidget);
    expect(find.text('Aktionen'), findsOneWidget);
    expect(find.text('Schock (0)'), findsNothing);

    await openActions(tester);
    expect(find.text('Weitere Aktionen'), findsOneWidget);
    expect(find.text('Messwerte'), findsOneWidget);
    expect(find.text('Notiz'), findsOneWidget);
    expect(find.text('Schock erfassen'), findsOneWidget);
    expect(find.text('Druckphase neu starten'), findsNothing);
    expect(find.text('Letzten Schock korrigieren'), findsNothing);
    expect(find.text('Letzten Schock rückgängig'), findsNothing);
  });

  testWidgets('restarts the Druckphase from Weitere Aktionen and keeps the '
      'medication timer', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.text('Gabe'));
    await tester.pump();
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));

    await openActions(tester);
    expect(find.text('Letzten Schock korrigieren'), findsNothing);
    expect(find.text('Letzten Schock rückgängig'), findsNothing);
    await tester.tap(find.text('Druckphase neu starten'));
    await tester.pumpAndSettle();

    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 01:00'), findsOneWidget);
    expect(find.text('wartet'), findsOneWidget);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('fällig'), findsOneWidget);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Druckphase neu gestartet'), 200);
    expect(find.text('Druckphase neu gestartet'), findsOneWidget);
  });

  testWidgets('counts the Druckphase down and the Reanimationsdauer up', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
  });

  testWidgets('shows Analyse fällig at 0:00 and counts the overdue time up', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Analyse fällig'), findsOneWidget);
    expect(find.text('+00:00'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);

    clock.advance(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Analyse fällig'), findsOneWidget);
    expect(find.text('+00:05'), findsOneWidget);
    expect(find.text('02:05'), findsOneWidget);
  });

  testWidgets('keeps the manual Analyse starten action available before it is '
      'due', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    expect(find.text('Analyse starten'), findsOneWidget);

    clock.advance(const Duration(minutes: 1, seconds: 50));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Analyse starten'), findsOneWidget);
    expect(find.text('Analyse in 00:10'), findsNothing);

    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Analyse fällig'), findsOneWidget);
    expect(find.text('Analyse starten'), findsOneWidget);
  });

  testWidgets('records an AED advisory from the inlined Analysephase choices', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    await tester.tap(find.text('Nicht schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unbekannt (AED)'));
    await tester.pumpAndSettle();

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Nächste Analyse'), findsOneWidget);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Rhythmusanalyse: Nicht schockbar – Unbekannt (AED)'),
      200,
    );
    expect(
      find.text('Rhythmusanalyse: Nicht schockbar – Unbekannt (AED)'),
      findsOneWidget,
    );
  });

  testWidgets('enters the Analysephase from the due Druckphase and pauses the '
      'compression timer', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    expect(find.text('Analysephase'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    clock.advance(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('00:06'), findsOneWidget);
    expect(find.text('Pause über 5 s – CPR fortsetzen'), findsOneWidget);
  });

  testWidgets('records a Rhythmusanalyse result and starts a fresh Druckphase '
      'automatically', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    await tester.tap(find.text('Schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kammerflimmern (VF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nein'));
    await tester.pumpAndSettle();

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Nächste Analyse'), findsOneWidget);
    expect(find.text('02:00'), findsNWidgets(2));
  });

  testWidgets('records a confirmed Schock from the wizard and resumes', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    await tester.tap(find.text('Schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kammerflimmern (VF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Schocks: 1'), findsOneWidget);
    expect(find.text('02:00'), findsNWidgets(2));
    expect(find.text('CPR fortsetzen'), findsNothing);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Schock 1'), 200);
    expect(find.text('Schock 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Rhythmusanalyse: Schockbar – Kammerflimmern (VF)'),
      200,
    );
    expect(
      find.text('Rhythmusanalyse: Schockbar – Kammerflimmern (VF)'),
      findsOneWidget,
    );
  });

  testWidgets('cancels the ROSC confirmation without recording ROSC', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('ROSC'));
    await tester.pumpAndSettle();

    expect(find.text('ROSC bestätigen?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();

    expect(find.text('Analysephase'), findsOneWidget);
    expect(find.text('Schockbar'), findsOneWidget);
    expect(find.text('Kreislauf zurückgekehrt'), findsNothing);
  });

  testWidgets('opens settings from the Leitlinienprofil chip and applies the '
      'selection to new Reanimationsfälle', (tester) async {
    final settings = AppSettings();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.text('ERC 2025'));
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Leitlinienprofil'), findsOneWidget);
    expect(find.text('AHA 2025'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Ton'), findsOneWidget);

    await tester.tap(find.text('AHA 2025'));
    await tester.pump();
    expect(settings.leitlinienprofil, Leitlinienprofil.aha2025);

    final vibrationSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Vibration'),
    );
    expect(vibrationSwitch.value, isTrue);
    await tester.tap(find.text('Vibration'));
    await tester.pump();
    expect(settings.vibrationEnabled, isFalse);

    final soundSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Ton'),
    );
    expect(soundSwitch.value, isFalse);
    await tester.tap(find.text('Ton'));
    await tester.pump();
    expect(settings.soundEnabled, isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('AHA 2025'), findsOneWidget);

    await startNow(tester);
    expect(find.text('AHA 2025'), findsOneWidget);
  });

  testWidgets('shows the AHA pause hint only after ten seconds', (
    tester,
  ) async {
    final settings = AppSettings(leitlinienprofil: Leitlinienprofil.aha2025);
    await pumpApp(tester, settings: settings);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pulscheck über 10 s – CPR fortsetzen'), findsNothing);

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pulscheck über 10 s – CPR fortsetzen'), findsOneWidget);
  });

  testWidgets('records Unklar and resumes without a note prompt', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    await tester.tap(find.text('Unklar'));
    await tester.pumpAndSettle();

    expect(find.text('Notiz zur Rhythmusanalyse'), findsNothing);
    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Nächste Analyse'), findsOneWidget);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Rhythmusanalyse: Unklar'), 200);
    expect(find.text('Rhythmusanalyse: Unklar'), findsOneWidget);
  });

  testWidgets('skips the Rhythmusanalyse in one tap and starts a fresh cycle', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();

    expect(find.text('Grund (optional)'), findsNothing);
    expect(find.text('Analyse übersprungen'), findsOneWidget);
    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Nächste Analyse'), findsOneWidget);
    expect(find.text('02:00'), findsNWidgets(2));
  });

  testWidgets('records a non-shockable rhythm and ROSC from the guided '
      'dialog', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    await tester.tap(find.text('Nicht schockbar'));
    await tester.pumpAndSettle();

    expect(find.text('Asystolie'), findsOneWidget);
    expect(find.text('PEA'), findsOneWidget);
    expect(find.text('Unbekannt (AED)'), findsOneWidget);

    await tester.tap(find.text('Asystolie'));
    await tester.pumpAndSettle();
    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Ergebnis: Nicht schockbar – Asystolie'), findsNothing);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    await tester.tap(find.text('ROSC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROSC bestätigen'));
    await tester.pumpAndSettle();

    expect(find.text('ROSC'), findsWidgets);
    expect(find.text('Kreislauf zurückgekehrt'), findsOneWidget);
    expect(find.text('Reanimationswiederbeginn'), findsOneWidget);
    expect(find.text('Fall beenden'), findsOneWidget);
    expect(find.text('Zusammenfassung'), findsNothing);
  });

  testWidgets('starts a running Reanimationsfall with a backdate preset and the corrected '
      'Startzeit', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(ActionChip, '5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Startzeit 07:55:00'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Analyse fällig'), findsOneWidget);
    expect(find.text('+03:00'), findsOneWidget);
  });

  testWidgets('starts a running Reanimationsfall with a custom Startzeit', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Eigene Startzeit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Starten'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bitte eine Dauer größer als 0 eingeben.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(0), '3');
    await tester.enterText(find.byType(TextFormField).at(1), '30');
    await tester.tap(find.text('Starten'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Startzeit 07:56:30'), findsOneWidget);
    expect(find.text('03:30'), findsOneWidget);
    expect(find.text('Analyse fällig'), findsOneWidget);
    expect(find.text('+01:30'), findsOneWidget);
  });

  testWidgets('snapshots the Leitlinienprofil per Reanimationsfall', (
    tester,
  ) async {
    final settings = AppSettings();
    await pumpApp(tester, settings: settings);
    await startNow(tester);
    expect(find.text('ERC 2025'), findsOneWidget);

    settings.leitlinienprofil = Leitlinienprofil.aha2025;
    await tester.pump();

    expect(find.text('ERC 2025'), findsOneWidget);
    expect(find.text('AHA 2025'), findsNothing);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    expect(find.text('Zusammenfassung'), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('AHA 2025'), findsOneWidget);
    expect(wakeLock.enabled, isFalse);

    await startNow(tester);
    expect(find.text('AHA 2025'), findsOneWidget);
  });

  testWidgets('keeps the timer accurate after the app is backgrounded', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advanceWallClockOnly(const Duration(minutes: 3, seconds: 12));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('03:12'), findsOneWidget);
    expect(find.text('Analyse fällig'), findsOneWidget);
    expect(find.text('+01:12'), findsOneWidget);
  });

  testWidgets('records a Schock in the Druckphase without pausing the cycle', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);
    expect(find.text('Schocks: 0'), findsOneWidget);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('01:30'), findsOneWidget);

    await recordSchock(tester);

    expect(find.text('Schocks: 1'), findsOneWidget);
    expect(find.text('Weitere Aktionen'), findsNothing);
    expect(find.text('CPR fortsetzen'), findsNothing);
    expect(find.text('Schock 1 erfasst'), findsNothing);
    expect(find.text('Analyse starten'), findsOneWidget);

    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('01:20'), findsOneWidget);
    expect(find.text('Nächste Analyse'), findsOneWidget);
  });

  testWidgets('records a shockable result, resumes automatically, and keeps '
      'the manual Schock available', (tester) async {
    await pumpApp(tester);
    await startNow(tester);
    expect(find.text('Schocks: 0'), findsOneWidget);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    expect(find.text('Schocks: 0'), findsOneWidget);

    await tester.tap(find.text('Schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kammerflimmern (VF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nein'));
    await tester.pumpAndSettle();

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Nächste Analyse'), findsOneWidget);
    expect(find.text('CPR fortsetzen'), findsNothing);

    await recordSchock(tester);
    expect(find.text('Schocks: 1'), findsOneWidget);
    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('CPR fortsetzen'), findsNothing);
  });

  testWidgets('shows the Adrenalin hint after a non-shockable result', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    expect(find.textContaining('Letzte Gabe'), findsNothing);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('Nicht schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asystolie'));
    await tester.pumpAndSettle();

    expect(find.text('Erste Gabe fällig'), findsOneWidget);
    expect(find.text('Gabe'), findsOneWidget);
    expect(find.textContaining('Letzte Gabe'), findsNothing);
  });

  testWidgets('shows the Adrenalin hint at the ERC shock count', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('Schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kammerflimmern (VF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nein'));
    await tester.pumpAndSettle();

    expect(find.text('Erste Gabe fällig'), findsNothing);

    for (var count = 1; count <= 3; count++) {
      await recordSchock(tester);
      expect(find.text('Schocks: $count'), findsOneWidget);
      if (count < 3) {
        expect(find.text('Erste Gabe fällig'), findsNothing);
      }
    }

    expect(find.text('Erste Gabe fällig'), findsOneWidget);
  });

  testWidgets('shows the Adrenalin hint at the AHA shock count', (
    tester,
  ) async {
    await pumpApp(
      tester,
      settings: AppSettings(leitlinienprofil: Leitlinienprofil.aha2025),
    );
    await startNow(tester);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('Schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kammerflimmern (VF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nein'));
    await tester.pumpAndSettle();

    await recordSchock(tester);
    expect(find.text('Schocks: 1'), findsOneWidget);
    expect(find.text('Erste Gabe fällig'), findsNothing);

    await recordSchock(tester);
    expect(find.text('Schocks: 2'), findsOneWidget);
    expect(find.text('Erste Gabe fällig'), findsOneWidget);
  });

  testWidgets('records an Adrenalin dose and runs the 3-5 minute window', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.text('Gabe'));
    await tester.pump();

    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 00:00'), findsOneWidget);
    expect(find.text('wartet'), findsOneWidget);
    expect(find.text('03:00'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    clock.advance(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('fällig'), findsOneWidget);
    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 03:00'), findsOneWidget);

    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('fällig'), findsOneWidget);
    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 04:00'), findsOneWidget);

    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('fällig'), findsOneWidget);
    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 05:00'), findsOneWidget);

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('überfällig'), findsOneWidget);
    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 05:01'), findsOneWidget);

    await tester.tap(find.text('Gabe'));
    await tester.pump();

    expect(find.text('Letzte Gabe: 08:05 Uhr, vor 00:00'), findsOneWidget);
    expect(find.text('wartet'), findsOneWidget);
  });

  testWidgets('keeps the Adrenalin window running during the Analysephase', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.text('Gabe'));
    await tester.pump();
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Analysephase'), findsOneWidget);
    expect(find.text('fällig'), findsOneWidget);
  });

  testWidgets('keeps the Adrenalin timer inside a compact landscape phone', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(568, 320);

    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.text('Gabe'));
    await tester.pump();
    clock.advance(const Duration(minutes: 4));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 04:00'), findsOneWidget);
    expectInsideViewport(
      tester,
      find.text('Letzte Gabe: 08:00 Uhr, vor 04:00'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the Amiodaron hint only after the third Schock and '
      'dismisses it without recording a dose', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    for (var count = 0; count < 2; count++) {
      await recordSchock(tester);
    }

    expect(find.text('Amiodaron erwägen – 300 mg'), findsNothing);
    expect(find.textContaining('Letzte Gabe'), findsNothing);

    await recordSchock(tester);

    expect(find.text('Amiodaron erwägen – 300 mg'), findsOneWidget);
    expect(find.text('Gegeben'), findsOneWidget);
    expect(find.text('Nicht jetzt'), findsOneWidget);
    expect(find.textContaining('Letzte Gabe'), findsNothing);

    await tester.tap(find.text('Nicht jetzt'));
    await tester.pump();

    expect(find.text('Amiodaron erwägen – 300 mg'), findsNothing);
    expect(find.textContaining('Letzte Gabe'), findsNothing);
  });

  testWidgets('records Amiodaron when given and follows the ERC second-dose '
      'trigger', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    for (var count = 0; count < 3; count++) {
      await recordSchock(tester);
    }

    expect(find.text('Amiodaron erwägen – 300 mg'), findsOneWidget);
    expect(find.textContaining('Letzte Gabe'), findsNothing);

    await tester.tap(find.text('Gegeben'));
    await tester.pump();

    expect(find.text('Amiodaron erwägen – 300 mg'), findsNothing);
    expect(find.text('Amiodaron · Letzte Gabe 00:00'), findsOneWidget);

    await recordSchock(tester);
    expect(find.text('Amiodaron erwägen – 150 mg'), findsNothing);

    clock.advance(const Duration(seconds: 45));
    await tester.pump(const Duration(milliseconds: 250));

    await recordSchock(tester);
    expect(find.text('Amiodaron erwägen – 150 mg'), findsOneWidget);

    await tester.tap(find.text('Gegeben'));
    await tester.pump();

    expect(find.text('Amiodaron erwägen – 150 mg'), findsNothing);
    expect(find.text('Amiodaron · Letzte Gabe 00:45'), findsOneWidget);
  });

  testWidgets('uses the AHA second Amiodaron dose trigger after the fourth '
      'Schock', (tester) async {
    await pumpApp(
      tester,
      settings: AppSettings(leitlinienprofil: Leitlinienprofil.aha2025),
    );
    await startNow(tester);

    for (var count = 0; count < 3; count++) {
      await recordSchock(tester);
    }
    await tester.tap(find.text('Gegeben'));
    await tester.pump();
    expect(find.text('Amiodaron erwägen – 150 mg'), findsNothing);

    await recordSchock(tester);

    expect(find.text('Amiodaron erwägen – 150 mg'), findsOneWidget);
  });

  testWidgets('keeps the Amiodaron hint inside a compact landscape phone', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(568, 320);

    await pumpApp(tester);
    await startNow(tester);

    for (var count = 0; count < 3; count++) {
      await recordSchock(tester);
    }

    expect(find.text('Amiodaron erwägen – 300 mg'), findsOneWidget);
    expectInsideViewport(tester, find.text('Amiodaron erwägen – 300 mg'));
    expectInsideViewport(tester, find.text('Gegeben'));
    expectInsideViewport(tester, find.text('Nicht jetzt'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the timer and primary actions visible on landscape '
      'phones and tablets', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    tester.view.devicePixelRatio = 1;

    for (final size in [
      const Size(568, 320),
      const Size(640, 360),
      const Size(844, 390),
      const Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      tester.view.padding = FakeViewPadding(
        top: size.height >= 360 ? 24 : 0,
        bottom: size.height >= 360 ? 24 : 0,
      );
      clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
      wakeLock = FakeWakeLock();
      store = InMemoryReanimationsfallStore();

      await pumpApp(tester);

      expect(find.text('Jetzt starten'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, '15'), findsOneWidget);
      expect(find.byTooltip('Menü öffnen'), findsOneWidget);
      expectInsideViewport(tester, find.text('Jetzt starten'));
      expectInsideViewport(tester, find.widgetWithText(ActionChip, '15'));
      expectInsideViewport(tester, find.text('Eigene Startzeit'));
      expectInsideViewport(tester, find.byTooltip('Menü öffnen'));
      expect(tester.takeException(), isNull);

      await openDrawer(tester);
      expectInsideViewport(tester, find.widgetWithText(ListTile, 'Über'));
      expect(tester.takeException(), isNull);
      await tester.tapAt(Offset(size.width - 20, 20));
      await tester.pumpAndSettle();

      await startNow(tester);

      expect(find.text('02:00'), findsOneWidget);
      expect(find.text('Druckphase'), findsOneWidget);
      expect(find.text('ERC 2025'), findsOneWidget);
      expect(find.text('Schocks: 0'), findsOneWidget);
      expect(find.text('Adrenalin'), findsOneWidget);
      expect(find.text('Gabe'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expectInsideViewport(tester, find.text('02:00'));
      expectInsideViewport(tester, find.text('Druckphase'));
      expectInsideViewport(tester, find.text('Schocks: 0'));
      expectInsideViewport(tester, find.text('Gabe'));
      expectInsideViewport(tester, find.byTooltip('Menü öffnen'));
      expectInsideViewport(tester, find.byTooltip('Fall beenden'));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Analyse starten'));
      await tester.pump();

      expect(find.text('Analysephase'), findsOneWidget);
      expect(find.text('Schockbar'), findsOneWidget);
      expect(find.text('Nicht schockbar'), findsOneWidget);
      expect(find.text('ROSC'), findsOneWidget);
      expect(find.text('Unklar'), findsOneWidget);
      expect(find.text('Überspringen'), findsOneWidget);
      expect(find.text('Schocks: 0'), findsOneWidget);
      expectInsideViewport(tester, find.text('Schockbar'));
      expectInsideViewport(tester, find.text('Nicht schockbar'));
      expectInsideViewport(tester, find.text('ROSC'));
      expectInsideViewport(tester, find.text('Unklar'));
      expectInsideViewport(tester, find.text('Überspringen'));
      expectInsideViewport(tester, find.text('Schocks: 0'));
      expect(tester.takeException(), isNull, reason: 'size $size');

      await tester.tap(find.text('Schockbar'));
      await tester.pumpAndSettle();
      expect(find.text('Kammerflimmern (VF)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schockbar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kammerflimmern (VF)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nein'));
      await tester.pumpAndSettle();

      expect(find.text('Druckphase'), findsOneWidget);
      expect(find.text('CPR fortsetzen'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'size $size result');

      await recordSchock(tester);

      expect(find.text('Schocks: 1'), findsOneWidget);
      expect(find.text('Druckphase'), findsOneWidget);
      expect(find.text('CPR fortsetzen'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'size $size Schock');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('also fits a portrait phone', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    await pumpApp(tester);

    expect(find.text('Jetzt starten'), findsOneWidget);
    expect(find.byTooltip('Menü öffnen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await startNow(tester);

    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('Druckphase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the case open after ROSC and continues the medication '
      'timers', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.text('Gabe'));
    await tester.pump();

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('ROSC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROSC bestätigen'));
    await tester.pumpAndSettle();

    expect(find.text('ROSC'), findsWidgets);
    expect(find.text('ROSC · Reanimation pausiert'), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
    expect(find.text('Reanimationswiederbeginn'), findsOneWidget);
    expect(find.text('Aktionen'), findsOneWidget);
    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 02:00'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Gabe'))
          .onPressed,
      isNull,
    );
    expect(find.text('Zusammenfassung'), findsNothing);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('fällig'), findsOneWidget);
    expect(find.text('Letzte Gabe: 08:00 Uhr, vor 04:00'), findsOneWidget);
    expect(find.text('Zusammenfassung'), findsNothing);
  });

  testWidgets('resumes after ROSC, ends with a reason, and shows the summary', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('ROSC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROSC bestätigen'));
    await tester.pumpAndSettle();

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Reanimationswiederbeginn'));
    await tester.pump();

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('ROSC'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Gabe'))
          .onPressed,
      isNotNull,
    );

    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();

    expect(find.text('Grund'), findsOneWidget);
    expect(find.text('Übergabe'), findsOneWidget);
    expect(find.text('Abbruch'), findsOneWidget);
    expect(find.text('Sonstiges'), findsOneWidget);

    await tester.tap(find.text('Übergabe'));
    await tester.pumpAndSettle();

    expect(find.text('Zusammenfassung'), findsOneWidget);
    expect(find.text('Reanimationsfall beendet'), findsOneWidget);
    expect(find.text('CPR-Dauer'), findsOneWidget);
    expect(find.text('02:10'), findsOneWidget);
    expect(find.text('ROSC'), findsOneWidget);
    expect(find.text('Reanimationswiederbeginn'), findsOneWidget);
    expect(find.text('Fall beendet: Übergabe'), findsOneWidget);
    expect(find.text('Übergabe'), findsOneWidget);
    expect(find.text('08:00:00'), findsNWidgets(2));
    expect(find.text('08:02:00'), findsOneWidget);
    expect(find.text('08:02:30'), findsOneWidget);
    expect(find.text('08:02:40'), findsNWidgets(2));
    expect(wakeLock.enabled, isFalse);
  });

  testWidgets('cancels or confirms ending a running case', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Zusammenfassung'), findsNothing);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    expect(find.text('Zusammenfassung'), findsOneWidget);
    expect(find.text('Fall beendet: Abbruch'), findsOneWidget);
    expect(wakeLock.enabled, isFalse);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neuer Reanimationsfall'), findsOneWidget);
  });

  testWidgets('restores an active Reanimationsfall after an app restart', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 250));
    await recordSchock(tester);

    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    await pumpApp(tester);

    expect(find.text('Aktiver Reanimationsfall'), findsOneWidget);
    expect(find.text('Fortsetzen'), findsOneWidget);
    expect(find.text('Jetzt starten'), findsNothing);

    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('Schocks: 1'), findsOneWidget);
    expect(find.text('00:40'), findsOneWidget);
    expect(wakeLock.enabled, isTrue);
  });

  testWidgets('restores the Analysephase after an app restart', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    clock.advance(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 250));

    await pumpApp(tester);

    expect(find.text('Aktiver Reanimationsfall'), findsOneWidget);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Analysephase'), findsOneWidget);
    expect(find.text('00:05'), findsOneWidget);
  });

  testWidgets('stores a completed case in the Einsatzlog across a restart', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Übergabe'));
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    expect(find.text('Reanimationsfall 08:00:00'), findsOneWidget);
    expect(find.text('CPR 00:00 · ERC 2025'), findsOneWidget);

    await tester.tap(find.text('Reanimationsfall 08:00:00'));
    await tester.pumpAndSettle();
    expect(find.text('Zusammenfassung'), findsOneWidget);
    expect(find.text('Reanimationsfall beendet'), findsOneWidget);

    await pumpApp(tester);
    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    expect(find.text('Reanimationsfall 08:00:00'), findsOneWidget);
  });

  testWidgets('marks a mis-started case as Verworfen and retains it in the '
      'Einsatzlog', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    await recordSchock(tester);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fall verwerfen'));
    await tester.pumpAndSettle();

    expect(find.text('Reanimationsfall verwerfen?'), findsOneWidget);
    await tester.tap(find.text('Verwerfen'));
    await tester.pumpAndSettle();

    expect(find.text('Jetzt starten'), findsOneWidget);
    expect(find.byTooltip('Reanimationsfall löschen'), findsNothing);

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    expect(find.text('Reanimationsfall 08:00:00'), findsOneWidget);
    expect(find.text('CPR 00:00 · ERC 2025 · Verworfen'), findsOneWidget);

    await tester.tap(find.text('Reanimationsfall 08:00:00'));
    await tester.pumpAndSettle();

    expect(find.text('Reanimationsfall verworfen'), findsOneWidget);
    expect(find.text('Fall verworfen'), findsOneWidget);
    expect(find.text('Schock 1'), findsOneWidget);
  });

  testWidgets('deletes a case only from the Einsatzlog after confirmation', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    await tester.tap(find.byTooltip('Reanimationsfall löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Reanimationsfall löschen?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Reanimationsfall 08:00:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Reanimationsfall löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(
      find.text('Noch keine abgeschlossenen Reanimationsfälle'),
      findsOneWidget,
    );

    await pumpApp(tester);
    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    expect(
      find.text('Noch keine abgeschlossenen Reanimationsfälle'),
      findsOneWidget,
    );
  });

  testWidgets('does not list an active case in the Einsatzlog', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    expect(
      find.text('Noch keine abgeschlossenen Reanimationsfälle'),
      findsOneWidget,
    );
    expect(find.byTooltip('Reanimationsfall löschen'), findsNothing);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Druckphase'), findsOneWidget);
    expect(wakeLock.enabled, isTrue);
  });

  Future<void> openMesswerte(WidgetTester tester) async {
    await openActions(tester);
    await tester.tap(find.text('Messwerte'));
    await tester.pumpAndSettle();
  }

  Future<void> openMesswertDialog(WidgetTester tester, String typ) async {
    await tester.tap(find.text(typ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> saveMesswert(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Speichern'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('does not show Messwerte in the drawer during a case', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);
    await openDrawer(tester);

    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Messwerte'),
      ),
      findsNothing,
    );
  });

  testWidgets('records a general Notiz from Weitere Aktionen', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    await openActions(tester);
    await tester.tap(find.text('Notiz'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Patient kalt');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.load()).single.notizen, hasLength(1));

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Patient kalt'), 200);
    expect(find.text('Patient kalt'), findsOneWidget);
  });

  testWidgets('ends the Reanimationsfall from Weitere Aktionen', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await openActions(tester);
    expect(find.text('Fall beenden'), findsOneWidget);

    await tester.tap(find.text('Fall beenden'));
    await tester.pumpAndSettle();

    expect(find.text('Grund'), findsOneWidget);
    await tester.tap(find.text('Übergabe'));
    await tester.pumpAndSettle();

    expect(find.text('Zusammenfassung'), findsOneWidget);
    expect(find.text('Fall beendet: Übergabe'), findsOneWidget);
    expect(wakeLock.enabled, isFalse);
  });

  testWidgets('keeps the timer running while Messwerte is open', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 250));
    await openMesswerte(tester);

    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('persists notes from Weitere Aktionen and the Messwerte page', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await openActions(tester);
    await tester.tap(find.text('Notiz'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Erste Notiz');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    await openMesswerte(tester);
    await tester.tap(find.text('Notiz erfassen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Zweite Notiz');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    final notes = (await store.load()).single.notizen;
    expect(notes, hasLength(2));
    expect(
      notes.map((notiz) => notiz.text),
      containsAll(['Erste Notiz', 'Zweite Notiz']),
    );
  });

  testWidgets('shows Messwerte and Notiz but no Schock in the ROSC actions', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('ROSC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROSC bestätigen'));
    await tester.pumpAndSettle();

    await openActions(tester);
    expect(find.text('Messwerte'), findsOneWidget);
    expect(find.text('Notiz'), findsOneWidget);
    expect(find.text('Schock erfassen'), findsNothing);
    expect(find.text('Druckphase neu starten'), findsNothing);
  });

  testWidgets('records all four Messwerte and a note from the active case', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));
    await openMesswerte(tester);

    expect(find.text('Noch keine Messwerte'), findsOneWidget);
    expect(find.text('Noch keine Notizen'), findsOneWidget);

    await openMesswertDialog(tester, 'Temperatur');
    await tester.enterText(find.byType(TextFormField).at(0), '36,5');
    await tester.enterText(find.byType(TextFormField).at(1), 'rektal');
    await saveMesswert(tester);

    expect(find.text('36,5 °C'), findsOneWidget);
    expect(find.textContaining('rektal'), findsOneWidget);

    await openMesswertDialog(tester, 'Blutdruck');
    await tester.enterText(find.byType(TextFormField).at(0), '120');
    await tester.enterText(find.byType(TextFormField).at(1), '80');
    await saveMesswert(tester);

    expect(find.text('120/80 mmHg'), findsOneWidget);

    await openMesswertDialog(tester, 'Blutzucker');
    await tester.enterText(find.byType(TextFormField).at(0), '100');
    await saveMesswert(tester);

    expect(find.text('100 mg/dL'), findsOneWidget);

    await openMesswertDialog(tester, 'Herzfrequenz');
    await tester.enterText(find.byType(TextFormField).at(0), '88');
    await saveMesswert(tester);

    expect(find.text('88 /min'), findsOneWidget);

    await tester.tap(find.text('Notiz erfassen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextFormField), 'Patient kalt');
    await tester.tap(find.text('Speichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Patient kalt'), findsOneWidget);
  });

  testWidgets('persists Messwerte with the active case across a restart', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);
    await openMesswerte(tester);

    await openMesswertDialog(tester, 'Herzfrequenz');
    await tester.enterText(find.byType(TextFormField).at(0), '90');
    await saveMesswert(tester);

    await pumpApp(tester);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await openMesswerte(tester);

    expect(find.text('90 /min'), findsOneWidget);
  });

  testWidgets('shows Messwerte and notes in the summary and opens the '
      'read-only view', (tester) async {
    await pumpApp(tester);
    await startNow(tester);
    await openMesswerte(tester);

    await openMesswertDialog(tester, 'Temperatur');
    await tester.enterText(find.byType(TextFormField).at(0), '37,2');
    await saveMesswert(tester);

    await tester.tap(find.text('Notiz erfassen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextFormField), 'Nach der Übergabe');
    await tester.tap(find.text('Speichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Übergabe'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Messwerte öffnen'), 300);
    expect(find.text('37,2 °C'), findsOneWidget);

    await tester.tap(find.text('Messwerte öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('37,2 °C'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nach der Übergabe'), 200);
    expect(find.text('Nach der Übergabe'), findsOneWidget);
    for (final typ in [
      'Temperatur',
      'Blutzucker',
      'Blutdruck',
      'Herzfrequenz',
    ]) {
      expect(find.text(typ), findsNothing);
    }
    expect(find.text('Notiz erfassen'), findsNothing);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Nach der Übergabe'), 300);
    expect(find.text('Nach der Übergabe'), findsOneWidget);
  });

  testWidgets('opens the app menu and closes it on the current destination', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byTooltip('Menü öffnen'), findsOneWidget);

    await openDrawer(tester);

    expect(find.text('Menü'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Einsatzlog'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Einstellungen'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Rechtliches'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Über'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Einstellungen'))
          .selected,
      isFalse,
    );

    await selectFromDrawer(tester, 'Einstellungen');

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Menü'), findsNothing);

    await openDrawer(tester);

    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Einstellungen'))
          .selected,
      isTrue,
    );

    await selectFromDrawer(tester, 'Einstellungen');

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Menü'), findsNothing);
  });

  testWidgets('opens Über from the drawer with the licenses entry', (
    tester,
  ) async {
    await pumpApp(tester);

    await openDrawer(tester);
    expect(find.widgetWithText(ListTile, 'Rechtliches'), findsNothing);
    await selectFromDrawer(tester, 'Über');

    expect(find.text('Über'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AboutPage),
        matching: find.text('HP-CPR'),
      ),
      findsOneWidget,
    );
    expect(find.text('Version 0.1.0 (Build 1)'), findsOneWidget);
    expect(
      find.text('Begleit-App für den High-Performance-CPR-Standard'),
      findsOneWidget,
    );
    expect(find.text('© 2026 Simon Hauck'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Quellcode und Issues'), findsOneWidget);
    expect(find.text('Lizenzen'), findsOneWidget);
    expect(
      find.text('Lizenztexte der App und ihrer Bibliotheken'),
      findsOneWidget,
    );
  });

  testWidgets('opens the license page with the app and package licenses', (
    tester,
  ) async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks([
        'hp_cpr',
      ], 'MIT License\n\nCopyright (c) 2026 Simon Hauck');
      yield const LicenseEntryWithLineBreaks([
        'wakelock_plus',
      ], 'BSD 3-Clause License');
    });

    await pumpApp(tester);

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Über');
    await tester.tap(find.text('Lizenzen'));
    await tester.pumpAndSettle();

    expect(find.text('HP-CPR'), findsOneWidget);
    expect(find.text('0.1.0 (Build 1)'), findsOneWidget);
    expect(find.text('MIT-Lizenz · © 2026 Simon Hauck'), findsOneWidget);
    expect(find.text('hp_cpr'), findsOneWidget);
    expect(find.text('wakelock_plus'), findsOneWidget);

    await tester.tap(find.text('hp_cpr'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Copyright (c) 2026 Simon Hauck'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the running Reanimationsfall alive while visiting the '
      'menu', (tester) async {
    await pumpApp(tester);
    await startNow(tester);

    clock.advance(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 250));

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einstellungen');

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(wakeLock.enabled, isTrue);

    clock.advance(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Druckphase'), findsOneWidget);
    expect(find.text('00:35'), findsOneWidget);
    expect(wakeLock.enabled, isTrue);
  });

  testWidgets('switches destinations from secondary pages and unwinds with '
      'back', (tester) async {
    await pumpApp(tester);

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einstellungen');
    await openDrawer(tester);
    await selectFromDrawer(tester, 'Über');

    expect(find.text('Version 0.1.0 (Build 1)'), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Einstellungen'), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Neuer Reanimationsfall'), findsOneWidget);
  });

  testWidgets('enables Demo-Modus on the start screen and advances the '
      'simulated case time in 30 second steps', (tester) async {
    final settings = AppSettings();
    await pumpApp(tester, settings: settings);

    expect(find.text('Demo-Modus'), findsOneWidget);
    expect(find.text('Zeit im Fall zum Testen vorspulen.'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Demo-Modus'),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.text('Demo-Modus'));
    await tester.pump();
    expect(settings.demoMode, isTrue);

    await startNow(tester);

    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('+30 s'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('+30 s'));
      await tester.pump();
    }

    expect(find.text('Analyse fällig'), findsOneWidget);
    expect(find.text('+00:00'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);
  });

  testWidgets('advances the Adrenalin Zeitfenster with the demo action', (
    tester,
  ) async {
    await pumpApp(tester, settings: AppSettings(demoMode: true));
    await startNow(tester);

    await tester.tap(find.text('Gabe'));
    await tester.pump();
    expect(find.text('wartet'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('+30 s'));
      await tester.pump();
    }

    expect(find.text('fällig'), findsOneWidget);
  });

  testWidgets('advances the Analysephase pause with the demo action', (
    tester,
  ) async {
    await pumpApp(tester, settings: AppSettings(demoMode: true));
    await startNow(tester);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    expect(find.text('+30 s'), findsOneWidget);

    await tester.tap(find.text('+30 s'));
    await tester.pump();

    expect(find.text('Pause über 5 s – CPR fortsetzen'), findsOneWidget);
  });

  testWidgets('restores a demo case with its simulated time and action', (
    tester,
  ) async {
    await pumpApp(tester, settings: AppSettings(demoMode: true));
    await startNow(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('+30 s'));
      await tester.pump();
    }
    expect(find.text('01:00'), findsNWidgets(2));

    await pumpApp(tester);

    expect(find.text('Aktiver Reanimationsfall'), findsOneWidget);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('+30 s'), findsOneWidget);
    expect(find.text('01:00'), findsNWidgets(2));
  });

  testWidgets('marks a demo case in the summary and the Einsatzlog', (
    tester,
  ) async {
    await pumpApp(tester, settings: AppSettings(demoMode: true));
    await startNow(tester);

    await tester.tap(find.text('+30 s'));
    await tester.pump();
    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbruch'));
    await tester.pumpAndSettle();

    expect(find.text('Zusammenfassung'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(BackButton),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    expect(find.text('Reanimationsfall 08:00:00'), findsOneWidget);
    expect(find.text('CPR 00:30 · ERC 2025 · Demo'), findsOneWidget);
  });

  testWidgets('hides the Demo-Modus toggle while an active case is shown', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Aktiver Reanimationsfall'), findsOneWidget);
    expect(find.text('Demo-Modus'), findsNothing);
  });

  testWidgets('does not persist the Demo-Modus toggle across an app restart', (
    tester,
  ) async {
    final settings = AppSettings();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.text('Demo-Modus'));
    await tester.pump();
    expect(settings.demoMode, isTrue);

    await pumpApp(tester);

    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Demo-Modus'),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('keeps the demo action inside a compact landscape phone', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(568, 320);

    await pumpApp(tester, settings: AppSettings(demoMode: true));

    expectInsideViewport(
      tester,
      find.widgetWithText(SwitchListTile, 'Demo-Modus'),
    );
    expect(find.text('Zeit im Fall zum Testen vorspulen.'), findsNothing);
    expect(tester.takeException(), isNull);

    await startNow(tester);

    expect(find.text('+30 s'), findsOneWidget);
    expectInsideViewport(tester, find.text('+30 s'));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Analyse starten'));
    await tester.pump();

    expect(find.text('+30 s'), findsOneWidget);
    expectInsideViewport(tester, find.text('+30 s'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits, removes, and restores a live Schock from the Protokoll', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);
    await recordSchock(tester);
    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 250));

    await openActions(tester);
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();

    expect(find.text('Reanimationsfall gestartet'), findsOneWidget);
    expect(find.text('Schock 1'), findsOneWidget);
    expect(
      find.text(
        'Im laufenden Fall sind nur Schocks, Medikamente, Messwerte und Notizen korrigierbar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Messwert erfassen'), findsNothing);

    await tester.tap(find.text('Schock 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Schock bearbeiten'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0');
    await tester.enterText(fields.at(1), '05');
    await tester.enterText(fields.at(2), '150');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Schock 1 · 150 J'), findsOneWidget);
    expect(find.text('00:05'), findsOneWidget);

    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Schocks: 1'), findsOneWidget);

    await openActions(tester);
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schock 1 · 150 J'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entfernen'));
    await tester.pumpAndSettle();

    expect(find.text('Eintrag entfernt'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Schock 1 · 150 J'), findsNothing);

    await tester.tap(find.text('Änderungsverlauf'));
    await tester.pumpAndSettle();
    expect(find.text('Schock'), findsOneWidget);
    expect(find.text('Schock · 150 J'), findsOneWidget);
    final entferntRow = find
        .ancestor(of: find.text('Entfernt'), matching: find.byType(InkWell))
        .first;
    await tester.tap(
      find.descendant(of: entferntRow, matching: find.text('Schock · 150 J')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wiederherstellen'));
    await tester.pumpAndSettle();

    expect(find.text('Eintrag wiederhergestellt'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Schock 1 · 150 J'), findsOneWidget);

    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Schocks: 1'), findsOneWidget);
  });

  testWidgets('locks structural entries in the live Protokoll', (tester) async {
    await pumpApp(tester);
    await startNow(tester);
    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('Schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kammerflimmern (VF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nein'));
    await tester.pumpAndSettle();

    await openActions(tester);
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();

    final rhythmusanalyse = find.text(
      'Rhythmusanalyse: Schockbar – Kammerflimmern (VF)',
    );
    expect(rhythmusanalyse, findsOneWidget);
    expect(
      find.byTooltip('Strukturereignis – während des Falls gesperrt'),
      findsOneWidget,
    );

    await tester.tap(rhythmusanalyse);
    await tester.pumpAndSettle();
    expect(find.text('Bearbeiten'), findsNothing);
  });

  testWidgets('edits and restores a completed Protokoll entry', (tester) async {
    await pumpApp(tester);
    await startNow(tester);
    await recordSchock(tester);
    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Übergabe'));
    await tester.pumpAndSettle();

    expect(find.text('Schock 1'), findsOneWidget);
    await tester.tap(find.text('Schock 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entfernen'));
    await tester.pumpAndSettle();

    expect(find.text('Schock 1'), findsNothing);
    final schocksRow = find
        .ancestor(of: find.text('Schocks'), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: schocksRow, matching: find.text('0')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Änderungsverlauf'));
    await tester.pumpAndSettle();
    expect(find.text('Schock'), findsOneWidget);
    await tester.tap(find.text('Schock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wiederherstellen'));
    await tester.pumpAndSettle();

    expect(find.text('Schock 1'), findsOneWidget);
    expect(
      find.descendant(of: schocksRow, matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('rebuilds CPR duration after a completed ROSC removal and '
      'refreshes the Einsatzlog', (tester) async {
    await pumpApp(tester);
    await startNow(tester);
    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('ROSC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROSC bestätigen'));
    await tester.pumpAndSettle();
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Reanimationswiederbeginn'));
    await tester.pump();
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Übergabe'));
    await tester.pumpAndSettle();

    final cprRow = find
        .ancestor(of: find.text('CPR-Dauer'), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: cprRow, matching: find.text('03:00')),
      findsOneWidget,
    );

    await tester.tap(find.text('ROSC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entfernen'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: cprRow, matching: find.text('04:00')),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    await openDrawer(tester);
    await selectFromDrawer(tester, 'Einsatzlog');

    expect(find.text('CPR 04:00 · ERC 2025'), findsOneWidget);
  });

  testWidgets('corrects a live Adrenalin dose and time from the Protokoll', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);
    await tester.tap(find.text('Gabe'));
    await tester.pump();
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));

    await openActions(tester);
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adrenalin 1 mg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Dosis korrigieren'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '1');
    await tester.enterText(fields.at(1), '00');
    await tester.enterText(fields.at(2), '2');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Adrenalin 2 mg'), findsOneWidget);

    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Letzte Gabe: 08:01 Uhr, vor 00:00'), findsOneWidget);
  });

  testWidgets('validates a corrected Protokoll time against the case bounds', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNow(tester);
    await recordSchock(tester);
    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    await openActions(tester);
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schock 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '5');
    await tester.enterText(fields.at(1), '00');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bitte einen Zeitpunkt innerhalb des Falls eingeben.'),
      findsOneWidget,
    );
    expect(find.text('Schock bearbeiten'), findsOneWidget);
  });

  testWidgets('corrects a Notiz from the live Protokoll', (tester) async {
    await pumpApp(tester);
    await startNow(tester);
    await tester.tap(find.text('Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notiz'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Erste Notiz');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    await openActions(tester);
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notiz: Erste Notiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Notiz bearbeiten'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0');
    await tester.enterText(fields.at(1), '05');
    await tester.enterText(fields.at(2), 'Korrigierte Notiz');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Notiz: Korrigierte Notiz'), findsOneWidget);
    expect(find.text('00:05'), findsOneWidget);
  });

  testWidgets('corrects a completed Rhythmusanalyse result', (tester) async {
    await pumpApp(tester);
    await startNow(tester);
    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Analyse starten'));
    await tester.pump();
    await tester.tap(find.text('Schockbar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kammerflimmern (VF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nein'));
    await tester.pumpAndSettle();
    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byTooltip('Fall beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Übergabe'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Rhythmusanalyse: Schockbar – Kammerflimmern (VF)'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Schockbar – Pulslose Kammertachykardie (pVT)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Rhythmusanalyse: Schockbar – Pulslose Kammertachykardie (pVT)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits the Protokoll into a compact landscape phone', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(568, 320);

    await pumpApp(tester);
    await startNow(tester);
    await recordSchock(tester);
    await openActions(tester);
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Im laufenden Fall sind nur Schocks, Medikamente, Messwerte und Notizen korrigierbar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Schock 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
