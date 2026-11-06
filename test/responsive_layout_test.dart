import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hp_cpr/app.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';

import 'support/fake_clock.dart';
import 'support/fake_wake_lock.dart';
import 'support/roboto_font.dart';

void main() {
  setUpAll(loadRobotoFont);

  testWidgets('fits the start page and running case at 360x640', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);

    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    PackageInfo.setMockInitialValues(
      appName: 'HP-CPR',
      packageName: 'de.simonhauck.hp_cpr',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );

    await tester.pumpWidget(
      HpCprApp(
        key: UniqueKey(),
        clock: clock,
        wakeLock: FakeWakeLock(),
        store: InMemoryReanimationsfallStore(),
      ),
    );
    await tester.pumpAndSettle();

    expectNoScale(tester, find.text('Neuer Reanimationsfall'));
    expectInsideViewport(tester, find.text('ERC 2025'));
    expectInsideViewport(tester, find.byTooltip('Menü öffnen'));

    final startButton = find.text('Jetzt starten');
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expectNoScale(tester, find.text('Druckphase'));
    expectNoScale(tester, find.text('02:00'));
    expectInsideViewport(tester, find.text('Schocks: 0'));
    expectInsideViewport(tester, find.text('Gabe'));

    final phaseLabel = find.text('Druckphase · Jetzt 2 Minuten komprimieren');
    expect(phaseLabel, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(phaseLabel).didExceedMaxLines,
      isFalse,
    );

    await tester.tap(find.text('Gabe'));
    await tester.pump();
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));

    final lastDose = find.text('Letzte Gabe: 08:00 Uhr, vor 01:00');
    expect(lastDose, findsOneWidget);
    expectNoScale(tester, lastDose);
    expectInsideViewport(tester, lastDose);

    for (var i = 0; i < 3; i++) {
      await recordSchock(tester);
    }

    final amiodaronTitle = find.text('Amiodaron');
    final amiodaronState = find.text('erwägen');
    final amiodaronDose = find.text('300 mg');
    final amiodaronGive = find.text('Gegeben');
    expect(amiodaronTitle, findsOneWidget);
    expect(amiodaronState, findsOneWidget);
    expect(amiodaronDose, findsOneWidget);
    expect(amiodaronGive, findsOneWidget);
    expectNoScale(tester, amiodaronTitle);
    expectNoScale(tester, amiodaronState);
    expectNoScale(tester, amiodaronDose);
    expectNoScale(tester, amiodaronGive);
    expectInsideViewport(tester, amiodaronTitle);
    expectInsideViewport(tester, amiodaronState);
    expectInsideViewport(tester, amiodaronDose);
    expectInsideViewport(tester, amiodaronGive);

    await tester.tap(amiodaronGive);
    await tester.pumpAndSettle();

    expect(find.text('erwägen'), findsNothing);
    final amiodaronLastDose = find.text('Amiodaron · Letzte Gabe 01:00');
    expect(amiodaronLastDose, findsOneWidget);
    expectNoScale(tester, amiodaronLastDose);
    expectInsideViewport(tester, amiodaronLastDose);
    expect(tester.takeException(), isNull);
  }, skip: kIsWeb);
}

Future<void> recordSchock(WidgetTester tester) async {
  await tester.tap(find.text('Aktionen'));
  await tester.pumpAndSettle();

  final schock = find.text('Schock erfassen');
  await tester.ensureVisible(schock);
  await tester.pumpAndSettle();
  await tester.tap(schock);
  await tester.pumpAndSettle();
}

void expectNoScale(WidgetTester tester, Finder finder) {
  final localSize = tester.getSize(finder);
  final rect = tester.getRect(finder);

  expect(
    rect.width,
    closeTo(localSize.width, 0.5),
    reason: '$finder is horizontally scaled down',
  );
  expect(
    rect.height,
    closeTo(localSize.height, 0.5),
    reason: '$finder is vertically scaled down',
  );
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
