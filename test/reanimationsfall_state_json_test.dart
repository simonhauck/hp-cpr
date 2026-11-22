import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_state_json.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';

import 'support/fake_clock.dart';

void main() {
  test('round-trips an ended case with events, phases, and ROSC', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(
      clock: clock,
      leitlinienprofil: Leitlinienprofil.aha2025,
      vibrationEnabled: false,
    );

    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordAdrenalin();
    reanimationsfall.recordTemperatur(36.5, notiz: 'rektal');
    reanimationsfall.recordBlutzucker(120);
    reanimationsfall.recordBlutdruck(systolisch: 120, diastolisch: 80);
    reanimationsfall.recordHerzfrequenz(88);
    reanimationsfall.recordNotiz('Nach ROSC');
    for (var i = 0; i < 3; i++) {
      reanimationsfall.recordSchock();
    }
    clock.advance(const Duration(seconds: 5));
    reanimationsfall.enterAnalysephase();
    reanimationsfall.completeRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
      schockAbgegeben: true,
    );
    clock.advance(const Duration(minutes: 1));
    reanimationsfall.restartDruckphase();
    clock.advance(const Duration(minutes: 2));
    reanimationsfall.enterAnalysephase();
    reanimationsfall.skipRhythmusanalyse();
    clock.advance(const Duration(seconds: 20));
    reanimationsfall.recordRosc();
    clock.advance(const Duration(seconds: 20));
    reanimationsfall.resumeResuscitation();
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.endReanimationsfall(Beendigungsgrund.uebergabe);

    final state = reanimationsfall.exportState();
    final encoded = reanimationsfallStateToJson(state);
    for (final removed in [
      'isSchockpause',
      'schockpauseWasDue',
      'schockpauseOverdue',
      'schockpauseOpeningSchockIndex',
      'rhythmusanalyseNotiz',
      'schockRueckgaengigkeiten',
      'schockKorrekturen',
      'rhythmusanalyseNotizKorrekturen',
      'soundEnabled',
    ]) {
      expect(encoded.containsKey(removed), isFalse, reason: removed);
    }
    // Cases stored before the sound option was removed still carry the key.
    encoded['soundEnabled'] = true;
    expect(
      ((encoded['uebersprungeneRhythmusanalysen'] as List<dynamic>).first
              as Map<String, dynamic>)
          .containsKey('grund'),
      isFalse,
    );
    expect(
      ((encoded['rhythmusanalyseEintraege'] as List<dynamic>).first
              as Map<String, dynamic>)
          .containsKey('notiz'),
      isFalse,
    );
    final decoded = reanimationsfallStateFromJson(
      jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
    );

    expect(decoded.id, state.id);
    expect(decoded.erfassteUebernahme, state.erfassteUebernahme);
    expect(decoded.erfassteUebernahmeUtc, state.erfassteUebernahmeUtc);
    expect(decoded.startzeit, state.startzeit);
    expect(decoded.startzeitUtc, state.startzeitUtc);
    expect(decoded.utcOffsetMinutes, state.utcOffsetMinutes);
    expect(decoded.leitlinienprofil, Leitlinienprofil.aha2025);
    expect(decoded.vibrationEnabled, isFalse);
    expect(decoded.zustand, ReanimationsfallZustand.beendet);
    expect(decoded.ende!.grund, Beendigungsgrund.uebergabe);
    expect(decoded.schocks, hasLength(4));
    expect(decoded.adrenalinGaben, hasLength(1));
    expect(
      decoded.rhythmusanalyseEintraege.single.ergebnis,
      RhythmusanalyseErgebnis.kammerflimmern,
    );
    expect(decoded.druckphaseNeustarts, hasLength(1));
    expect(decoded.messwerte, hasLength(4));
    expect(decoded.messwerte[0], isA<TemperaturMesswert>());
    expect((decoded.messwerte[0] as TemperaturMesswert).notiz, 'rektal');
    expect((decoded.messwerte[1] as BlutzuckerMesswert).mgDl, 120);
    expect((decoded.messwerte[2] as BlutdruckMesswert).diastolisch, 80);
    expect((decoded.messwerte[3] as HerzfrequenzMesswert).proMinute, 88);
    expect(decoded.notizen.single.text, 'Nach ROSC');
    expect(decoded.roscEreignisse, hasLength(1));
    expect(decoded.wiederbeginnEreignisse, hasLength(1));
    expect(encoded.containsKey('abschnitte'), isFalse);
    expect(decoded.nextEreignisId, state.nextEreignisId);
    expect(decoded.korrekturen, isEmpty);

    final restored = Reanimationsfall.restore(
      clock: FakeClock(wallTime: clock.now()),
      state: decoded,
    );
    final snapshot = restored.snapshot();

    expect(snapshot.zustand, ReanimationsfallZustand.beendet);
    expect(snapshot.cprDauer, reanimationsfall.snapshot().cprDauer);
    expect(snapshot.schockAnzahl, 4);
    expect(snapshot.schocks.last.energieJoule, isNull);
    expect(snapshot.druckphaseNeustarts, hasLength(1));
    expect(snapshot.rhythmusanalyseEintraege, hasLength(1));
    expect(snapshot.adrenalinGaben, hasLength(1));
    expect(snapshot.roscEreignisse, hasLength(1));
    expect(snapshot.wiederbeginnEreignisse, hasLength(1));
    expect(snapshot.messwerte, hasLength(4));
    expect(snapshot.notizen.single.text, 'Nach ROSC');
    expect(snapshot.startzeit, state.startzeit);
    expect(snapshot.abschnitte, hasLength(2));
    expect(snapshot.abschnitte.last.ende, isNotNull);
  });

  test('round-trips a Verworfen case', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.recordSchock();
    clock.advance(const Duration(seconds: 30));
    reanimationsfall.discardReanimationsfall();

    final state = reanimationsfall.exportState();
    final decoded = reanimationsfallStateFromJson(
      jsonDecode(jsonEncode(reanimationsfallStateToJson(state)))
          as Map<String, dynamic>,
    );

    expect(decoded.zustand, ReanimationsfallZustand.verworfen);
    expect(decoded.verworfenAm, const Duration(seconds: 30));

    final restored = Reanimationsfall.restore(
      clock: FakeClock(wallTime: clock.now()),
      state: decoded,
    );
    final snapshot = restored.snapshot();
    expect(snapshot.istVerworfen, isTrue);
    expect(snapshot.verworfenAm, const Duration(seconds: 30));
    expect(snapshot.abschnitte.single.ende, const Duration(seconds: 30));
    expect(snapshot.cprDauer, const Duration(seconds: 30));
  });

  test('keeps an active Analysephase after a restart', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 30));
    reanimationsfall.enterAnalysephase();
    clock.advance(const Duration(seconds: 5));

    final decoded = reanimationsfallStateFromJson(
      jsonDecode(
        jsonEncode(reanimationsfallStateToJson(reanimationsfall.exportState())),
      ) as Map<String, dynamic>,
    );
    final restartClock = FakeClock(
      wallTime: clock.now().add(const Duration(seconds: 10)),
    );
    final restored = Reanimationsfall.restore(
      clock: restartClock,
      state: decoded,
    );

    final snapshot = restored.snapshot();
    expect(snapshot.phase, Reanimationsphase.analysephase);
    expect(snapshot.reanimationsdauer, const Duration(seconds: 45));
    expect(snapshot.pauseDuration, const Duration(seconds: 15));
    expect(snapshot.compressionRemaining, const Duration(seconds: 90));
  });

  test('round-trips Demo-Modus and its simulated offset', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(
      clock: clock,
      demoMode: true,
    );
    reanimationsfall.advanceDemoTime(const Duration(seconds: 30));
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.advanceDemoTime(const Duration(seconds: 30));

    final state = reanimationsfall.exportState();
    expect(state.demoMode, isTrue);
    expect(state.demoOffset, const Duration(seconds: 60));

    final decoded = reanimationsfallStateFromJson(
      jsonDecode(jsonEncode(reanimationsfallStateToJson(state)))
          as Map<String, dynamic>,
    );
    expect(decoded.demoMode, isTrue);
    expect(decoded.demoOffset, const Duration(seconds: 60));

    final restored = Reanimationsfall.restore(
      clock: FakeClock(wallTime: clock.now()),
      state: decoded,
    );
    final snapshot = restored.snapshot();
    expect(snapshot.demoMode, isTrue);
    expect(snapshot.reanimationsdauer, const Duration(minutes: 1, seconds: 10));
    expect(snapshot.compressionRemaining, const Duration(seconds: 50));

    restored.advanceDemoTime(const Duration(seconds: 30));
    expect(
      restored.snapshot().reanimationsdauer,
      const Duration(minutes: 1, seconds: 40),
    );
    expect(
      restored.snapshot().compressionRemaining,
      const Duration(seconds: 20),
    );
  });

  test('round-trips Protokoll corrections and stable ids', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordSchock(energieJoule: 200);
    reanimationsfall.recordAdrenalin();
    reanimationsfall.recordNotiz('Notiz');
    reanimationsfall.recordTemperatur(36.5);

    final state = reanimationsfall.exportState();
    final encoded = reanimationsfallStateToJson(state);
    expect(encoded.containsKey('nextEreignisId'), isTrue);
    expect(encoded.containsKey('korrekturen'), isTrue);
    expect(
      (encoded['schocks'] as List<dynamic>).single as Map<String, dynamic>,
      containsPair('id', isA<String>()),
    );

    final snapshot = reanimationsfall.snapshot();
    final schock = snapshot.protokoll.eintraege.singleWhere(
      (e) => e.typ == ProtokollEintragTyp.schock,
    );
    final notiz = snapshot.protokoll.eintraege.singleWhere(
      (e) => e.typ == ProtokollEintragTyp.notiz,
    );
    reanimationsfall.applyProtokollKorrektur(
      SchockKorrigiert(
        ziel: schock.ref,
        zeitpunkt: const Duration(seconds: 5),
        energieJoule: 150,
      ),
    );
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: notiz.ref),
    );

    final decoded = reanimationsfallStateFromJson(
      jsonDecode(
        jsonEncode(reanimationsfallStateToJson(reanimationsfall.exportState())),
      ) as Map<String, dynamic>,
    );
    expect(decoded.korrekturen, hasLength(2));

    final restored = Reanimationsfall.restore(
      clock: FakeClock(wallTime: clock.now()),
      state: decoded,
    );
    final restoredSnapshot = restored.snapshot();
    expect(restoredSnapshot.schocks.single.energieJoule, 150);
    expect(
      restoredSnapshot.schocks.single.zeitpunkt,
      const Duration(seconds: 5),
    );
    expect(restoredSnapshot.notizen, isEmpty);
    expect(
      restoredSnapshot.protokoll.alleEintraege
          .singleWhere((e) => e.ref == notiz.ref)
          .istEntfernt,
      isTrue,
    );
  });

  test('round-trips a corrected Analysephasenbeginn', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(minutes: 2));
    reanimationsfall.enterAnalysephase();

    final beginn = reanimationsfall.snapshot().protokoll.eintraege.singleWhere(
      (e) => e.typ == ProtokollEintragTyp.analysephaseBeginn,
    );
    reanimationsfall.applyProtokollKorrektur(
      ZeitpunktKorrigiert(
        ziel: beginn.ref,
        zeitpunkt: const Duration(minutes: 1, seconds: 50),
      ),
    );

    final decoded = reanimationsfallStateFromJson(
      jsonDecode(
        jsonEncode(reanimationsfallStateToJson(reanimationsfall.exportState())),
      ) as Map<String, dynamic>,
    );
    expect(decoded.analysephaseBeginne, hasLength(1));

    final restored = Reanimationsfall.restore(
      clock: FakeClock(wallTime: clock.now()),
      state: decoded,
    );
    final restoredSnapshot = restored.snapshot();
    expect(restoredSnapshot.analysephaseBeginne, hasLength(1));
    final restoredBeginn = restoredSnapshot.protokoll.eintraege.singleWhere(
      (e) => e.typ == ProtokollEintragTyp.analysephaseBeginn,
    );
    expect(restoredBeginn.zeitpunkt, const Duration(minutes: 1, seconds: 50));
  });

  test('decodes a missing analysephaseBeginne key to an empty list', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final encoded = reanimationsfallStateToJson(
      Reanimationsfall.start(clock: clock).exportState(),
    )..remove('analysephaseBeginne');

    expect(reanimationsfallStateFromJson(encoded).analysephaseBeginne, isEmpty);
  });

  test('defaults missing Demo-Modus fields for older states', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final state = Reanimationsfall.start(clock: clock).exportState();
    final encoded = reanimationsfallStateToJson(state)
      ..remove('demoMode')
      ..remove('demoOffset');

    final decoded = reanimationsfallStateFromJson(encoded);

    expect(decoded.demoMode, isFalse);
    expect(decoded.demoOffset, Duration.zero);
  });

  test('round-trips the Übernahme and the Vorbehandlung so the corrected '
      'times survive a restart', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 30));
    reanimationsfall.recordSchock();
    clock.advance(const Duration(seconds: 30));
    reanimationsfall.correctVorbehandlung(
      uebernahme: DateTime(2026, 10, 25, 7, 59),
      laufzeitBeiUebernahme: const Duration(minutes: 3),
    );
    final before = reanimationsfall.snapshot();

    final encoded = reanimationsfallStateToJson(reanimationsfall.exportState());
    final decoded = reanimationsfallStateFromJson(
      jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
    );

    expect(decoded.erfassteUebernahme, DateTime(2026, 10, 25, 8));
    expect(decoded.startzeit, DateTime(2026, 10, 25, 7, 56));
    final korrektur = decoded.korrekturen.single as VorbehandlungKorrigiert;
    expect(korrektur.uebernahme, const Duration(minutes: -1));
    expect(korrektur.laufzeitBeiUebernahme, const Duration(minutes: 3));

    final restored = Reanimationsfall.restore(clock: clock, state: decoded);
    final after = restored.snapshot();

    expect(after.startzeit, DateTime(2026, 10, 25, 7, 56));
    expect(after.uebernahme, DateTime(2026, 10, 25, 7, 59));
    expect(after.reanimationsdauer, before.reanimationsdauer);
    expect(after.compressionRemaining, before.compressionRemaining);
    expect(after.schocks.single.zeitpunkt, before.schocks.single.zeitpunkt);
    expect(after.zeigeVorbehandlungErfassen, isFalse);
    expect(
      after.protokoll.eintraege.map((e) => e.typ),
      contains(ProtokollEintragTyp.uebernahme),
    );
  });

  test('round-trips the Vorbehandlung counts and Notiz', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.correctVorbehandlung(
      uebernahme: DateTime(2026, 10, 25, 8),
      laufzeitBeiUebernahme: const Duration(minutes: 3),
      schocks: 3,
      adrenalin: 2,
      amiodaron: 1,
      notiz: 'Larynxtubus',
    );

    final encoded = reanimationsfallStateToJson(reanimationsfall.exportState());
    final decoded = reanimationsfallStateFromJson(
      jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
    );
    final restored = Reanimationsfall.restore(clock: clock, state: decoded);

    final korrektur = decoded.korrekturen.single as VorbehandlungKorrigiert;
    expect(korrektur.schocks, 3);
    expect(korrektur.adrenalin, 2);
    expect(korrektur.amiodaron, 1);
    expect(korrektur.notiz, 'Larynxtubus');
    final snapshot = restored.snapshot();
    expect(snapshot.schockAnzahl, 3);
    expect(snapshot.vorbehandlung.adrenalin, 2);
    expect(snapshot.amiodaronAnzahl, 1);
  });

  test('decodes a Vorbehandlung without counts to zero and no Notiz', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.correctVorbehandlung(
      uebernahme: DateTime(2026, 10, 25, 8),
      laufzeitBeiUebernahme: const Duration(minutes: 3),
      schocks: 2,
    );
    final encoded = reanimationsfallStateToJson(reanimationsfall.exportState());
    final korrektur =
        (encoded['korrekturen'] as List).single as Map<String, dynamic>;
    for (final key in ['schocks', 'adrenalin', 'amiodaron', 'notiz']) {
      korrektur.remove(key);
    }

    final decoded = reanimationsfallStateFromJson(encoded);

    final vorbehandlung = decoded.korrekturen.single as VorbehandlungKorrigiert;
    expect(vorbehandlung.vorbehandlung.istLeer, isTrue);
    expect(vorbehandlung.laufzeitBeiUebernahme, const Duration(minutes: 3));
  });

  test('falls back to the Startzeit for states without an Übernahme', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8));
    final state = Reanimationsfall.start(clock: clock).exportState();
    final encoded = reanimationsfallStateToJson(state);
    encoded['startzeit'] = encoded.remove('erfassteUebernahme');
    encoded['startzeitUtc'] = encoded.remove('erfassteUebernahmeUtc');
    // A state stored while the prompt could still be dismissed still decodes.
    encoded['vorbehandlungHinweisAusgeblendet'] = true;

    final decoded = reanimationsfallStateFromJson(encoded);

    expect(decoded.erfassteUebernahme, DateTime(2026, 10, 25, 8));
    expect(decoded.startzeit, DateTime(2026, 10, 25, 8));
  });
}
