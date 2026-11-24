import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hp_cpr/app.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';
import 'package:hp_cpr/features/settings/data/disclaimer_store.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/features/tutorial/data/tutorial_store.dart';
import 'package:hp_cpr/features/tutorial/presentation/tutorial_page.dart';

import 'support/fake_clock.dart';
import 'support/fake_vibrator.dart';
import 'support/fake_wake_lock.dart';
import 'support/roboto_font.dart';

void main() {
  setUpAll(loadRobotoFont);

  late InMemoryReanimationsfallStore store;
  late AppSettings settings;

  setUp(() {
    store = InMemoryReanimationsfallStore();
    settings = AppSettings();
    PackageInfo.setMockInitialValues(
      appName: 'HP-CPR',
      packageName: 'de.simonhauck.hp_cpr',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDown(() => settings.dispose());

  Future<void> pumpApp(
    WidgetTester tester,
    TutorialStore tutorialStore, {
    DisclaimerStore? disclaimerStore,
  }) async {
    await tester.pumpWidget(
      HpCprApp(
        key: UniqueKey(),
        clock: FakeClock(wallTime: DateTime(2026, 10, 25, 8)),
        settings: settings,
        wakeLock: FakeWakeLock(),
        vibrator: FakeVibrator(),
        store: store,
        disclaimerStore: disclaimerStore ?? InMemoryDisclaimerStore(),
        tutorialStore: tutorialStore,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToLastPage(WidgetTester tester) async {
    while (find.text('Weiter').evaluate().isNotEmpty) {
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> openTutorialFromDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menü öffnen').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Anleitung'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the tutorial on the first launch only', (tester) async {
    final tutorialStore = InMemoryTutorialStore();
    await pumpApp(tester, tutorialStore);

    expect(find.byType(TutorialPage), findsOneWidget);
    expect(find.text('Willkommen bei HP-CPR'), findsOneWidget);

    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();

    expect(find.byType(TutorialPage), findsNothing);
    expect(find.text('Jetzt starten'), findsOneWidget);
    expect(await tutorialStore.hasSeen(), isTrue);

    await pumpApp(tester, tutorialStore);
    expect(find.byType(TutorialPage), findsNothing);
  });

  testWidgets('shows the tutorial after the Rechtlicher Hinweis', (
    tester,
  ) async {
    await pumpApp(
      tester,
      InMemoryTutorialStore(),
      disclaimerStore: InMemoryDisclaimerStore(acknowledged: false),
    );

    expect(find.text('Rechtlicher Hinweis'), findsOneWidget);
    expect(find.byType(TutorialPage), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Verstanden'));
    await tester.pumpAndSettle();

    expect(find.byType(TutorialPage), findsOneWidget);
  });

  testWidgets('pages through to the demo button with Weiter and swipes', (
    tester,
  ) async {
    await pumpApp(tester, InMemoryTutorialStore());

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Fall starten'), findsOneWidget);

    await goToLastPage(tester);

    expect(find.text('Gefahrlos ausprobieren'), findsOneWidget);
    expect(find.text('Demo-Fall starten'), findsOneWidget);
    expect(find.text('Überspringen').hitTestable(), findsNothing);
  });

  testWidgets('starts a demo case from the last page without enabling the '
      'Demo-Modus setting', (tester) async {
    await pumpApp(tester, InMemoryTutorialStore());
    await goToLastPage(tester);

    await tester.tap(find.text('Demo-Fall starten'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TutorialPage), findsNothing);
    expect(find.text('+30 s'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);
    expect(settings.demoMode, isFalse);
  });

  testWidgets('closes with Später and starts no case', (tester) async {
    await pumpApp(tester, InMemoryTutorialStore());
    await goToLastPage(tester);

    await tester.tap(find.text('Später'));
    await tester.pumpAndSettle();

    expect(find.text('Jetzt starten'), findsOneWidget);
    expect(await store.load(), isEmpty);
  });

  testWidgets('opens from the menu and starts a demo case from there', (
    tester,
  ) async {
    await pumpApp(tester, InMemoryTutorialStore(seen: true));
    expect(find.byType(TutorialPage), findsNothing);

    await openTutorialFromDrawer(tester);
    expect(find.byType(TutorialPage), findsOneWidget);

    await goToLastPage(tester);
    await tester.tap(find.text('Demo-Fall starten'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TutorialPage), findsNothing);
    expect(find.text('+30 s'), findsOneWidget);
  });

  testWidgets('offers no demo case while a case is active', (tester) async {
    await pumpApp(tester, InMemoryTutorialStore(seen: true));
    await tester.tap(find.text('Jetzt starten'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await openTutorialFromDrawer(tester);
    await goToLastPage(tester);

    expect(find.text('Demo-Fall starten'), findsNothing);
    expect(find.textContaining('laufende Reanimationsfall'), findsOneWidget);

    await tester.tap(find.text('Fertig'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TutorialPage), findsNothing);
    expect(find.text('+30 s'), findsNothing);
    expect(await store.load(), hasLength(1));
  });
}
