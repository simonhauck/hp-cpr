import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/app.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';

import 'support/fake_clock.dart';
import 'support/fake_wake_lock.dart';

void main() {
  late FakeClock clock;
  late FakeWakeLock wakeLock;

  setUp(() {
    clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    wakeLock = FakeWakeLock();
  });

  Future<void> pumpApp(WidgetTester tester, {AppSettings? settings}) async {
    await tester.pumpWidget(
      HpCprApp(
        key: UniqueKey(),
        clock: clock,
        settings: settings,
        wakeLock: wakeLock,
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
    expect(wakeLock.enabled, isTrue);
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

    await tester.tap(find.byType(BackButton));
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

      await pumpApp(tester);

      expect(find.text('Jetzt starten'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, '15'), findsOneWidget);
      expectInsideViewport(tester, find.text('Jetzt starten'));
      expectInsideViewport(tester, find.widgetWithText(ActionChip, '15'));
      expectInsideViewport(tester, find.text('Eigene Startzeit'));
      expect(tester.takeException(), isNull);

      await startNow(tester);

      expect(find.text('02:00'), findsOneWidget);
      expect(find.text('Druckphase'), findsOneWidget);
      expect(find.text('ERC 2025'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expectInsideViewport(tester, find.text('02:00'));
      expectInsideViewport(tester, find.text('Druckphase'));
      expect(tester.takeException(), isNull);

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
    expect(tester.takeException(), isNull);

    await startNow(tester);

    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('Druckphase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
