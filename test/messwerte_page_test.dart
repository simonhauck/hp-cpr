import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/messwerte/presentation/messwerte_page.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

import 'support/fake_clock.dart';
import 'support/fake_vibrator.dart';

void main() {
  testWidgets('sorts Messwerte and Notizen by time and shows both times', (
    tester,
  ) async {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final session = ReanimationsfallSession(
      store: InMemoryReanimationsfallStore(),
      clock: clock,
    );
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordTemperatur(36.5);
    reanimationsfall.recordNotiz('Erste Notiz');
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordHerzfrequenz(88);
    reanimationsfall.recordNotiz('Zweite Notiz');
    clock.advance(const Duration(seconds: 40));

    // Move the earliest entries behind the later ones.
    final snapshot = reanimationsfall.snapshot();
    final temperatur = snapshot.messwerte.first;
    final erste = snapshot.protokoll.eintraege.firstWhere(
      (e) => e.typ == ProtokollEintragTyp.notiz,
    );
    reanimationsfall.applyProtokollKorrektur(
      MesswertKorrigiert(
        ziel: ProtokollEintragRef(
          typ: ProtokollEintragTyp.messwert,
          id: temperatur.id,
        ),
        ersatz: TemperaturMesswert(
          id: temperatur.id,
          zeitpunkt: const Duration(seconds: 50),
          celsius: 36.5,
        ),
      ),
    );
    reanimationsfall.applyProtokollKorrektur(
      NotizKorrigiert(
        ziel: erste.ref,
        zeitpunkt: const Duration(seconds: 50),
        text: 'Erste Notiz',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MesswertePage(
          routes: AppRoutes(
            settings: AppSettings(),
            clock: clock,
            vibrator: FakeVibrator(),
            session: session,
          ),
          reanimationsfall: reanimationsfall,
          session: session,
        ),
      ),
    );

    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    expect(top('88 /min'), lessThan(top('36,5 °C')));
    expect(top('Zweite Notiz'), lessThan(top('Erste Notiz')));
    // Case time over wall time, as in the Protokoll.
    expect(find.text('00:50'), findsWidgets);
    expect(find.text('08:00:50'), findsWidgets);
  });
}
