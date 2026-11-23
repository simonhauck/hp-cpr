import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hp_cpr/features/about/presentation/about_page.dart';
import 'package:hp_cpr/features/impressum/presentation/impressum_page.dart';
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

  testWidgets('opens from the About page and shows the contact data', (
    tester,
  ) async {
    await pump(tester, AboutPage(routes: routes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impressum'));
    await tester.pumpAndSettle();

    expect(find.byType(ImpressumPage), findsOneWidget);
    expect(find.text('Angaben gemäß § 5 DDG'), findsOneWidget);
    expect(find.text('Simon Hauck'), findsOneWidget);
    expect(find.text('Marktstraße 3B'), findsOneWidget);
    expect(find.text('25451 Quickborn'), findsOneWidget);
    expect(find.text('Telefon: 017664479035'), findsOneWidget);
    expect(find.text('E-Mail: hp-cpr@simonhauck.de'), findsOneWidget);
  });
}
