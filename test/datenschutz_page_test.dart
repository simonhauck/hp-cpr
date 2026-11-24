import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hp_cpr/features/about/presentation/about_page.dart';
import 'package:hp_cpr/features/datenschutz/presentation/datenschutz_page.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

import 'support/fake_clock.dart';
import 'support/fake_vibrator.dart';
import 'support/roboto_font.dart';

/// Serves the bundled assets from disk so loading completes in fake time.
class _DiskAssetBundle extends CachingAssetBundle {
  // The default loadString decodes large assets in an isolate, which never
  // completes in fake time.
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();

  @override
  Future<ByteData> load(String key) async {
    final bytes = File(key).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  // The tests serve the bundled files from disk, which the web test runner
  // cannot read.
  group('Datenschutz page', () {
    setUpAll(loadRobotoFont);

    late AppRoutes routes;

    setUp(() {
      final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
      routes = AppRoutes(
        settings: AppSettings(),
        clock: clock,
        vibrator: FakeVibrator(),
        session: ReanimationsfallSession(
          store: InMemoryReanimationsfallStore(),
          clock: clock,
        ),
      );
      PackageInfo.setMockInitialValues(
        appName: 'HP-CPR',
        packageName: 'de.simonhauck.hp_cpr',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    Future<void> pump(WidgetTester tester, Widget home) {
      return tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: DefaultAssetBundle(bundle: _DiskAssetBundle(), child: home),
        ),
      );
    }

    testWidgets('opens from the About page and shows the heading', (
      tester,
    ) async {
      await pump(tester, AboutPage(routes: routes));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Datenschutz'));
      await tester.pumpAndSettle();

      expect(find.byType(DatenschutzPage), findsOneWidget);
      expect(find.text('Datenschutzerklärung'), findsOneWidget);
      expect(find.text('Simon Hauck'), findsNothing);
    });

    testWidgets('shows the app variant without the web-only sections', (
      tester,
    ) async {
      await pump(tester, DatenschutzPage(routes: routes, isWeb: false));
      await tester.pumpAndSettle();

      expect(find.text('Datenschutzerklärung'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Speicherung von Daten auf Ihrem Gerät'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('Google Fonts'), findsNothing);
    });

    testWidgets('shows the web variant with the web-only sections', (
      tester,
    ) async {
      await pump(tester, DatenschutzPage(routes: routes, isWeb: true));
      await tester.pumpAndSettle();

      expect(find.text('Datenschutzerklärung'), findsOneWidget);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position;
      for (var i = 0; i < 3; i++) {
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
      }
      expect(find.textContaining('Google Fonts'), findsWidgets);
    });

    testWidgets('opens links with the link opener', (tester) async {
      final opened = <Uri>[];
      await pump(
        tester,
        DatenschutzPage(
          routes: routes,
          isWeb: false,
          linkOpener: (uri) async => opened.add(uri),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('Quellcode:', findRichText: true),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tapOnText(
        find.textRange.ofSubstring('https://github.com/simonhauck/hp-cpr'),
      );
      await tester.pump();

      expect(opened, [Uri.parse('https://github.com/simonhauck/hp-cpr')]);
    });
  }, skip: kIsWeb);
}
