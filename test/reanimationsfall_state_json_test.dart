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
      soundEnabled: true,
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
    ]) {
      expect(encoded.containsKey(removed), isFalse, reason: removed);
    }
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
    expect(decoded.startzeit, state.startzeit);
    expect(decoded.startzeitUtc, state.startzeitUtc);
    expect(decoded.utcOffsetMinutes, state.utcOffsetMinutes);
    expect(decoded.leitlinienprofil, Leitlinienprofil.aha2025);
    expect(decoded.vibrationEnabled, isFalse);
    expect(decoded.soundEnabled, isTrue);
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
    expect(decoded.abschnitte, hasLength(2));
    expect(decoded.abschnitte.last.ende, isNotNull);

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
    expect(decoded.abschnitte.single.ende, const Duration(seconds: 30));

    final restored = Reanimationsfall.restore(
      clock: FakeClock(wallTime: clock.now()),
      state: decoded,
    );
    final snapshot = restored.snapshot();
    expect(snapshot.istVerworfen, isTrue);
    expect(snapshot.verworfenAm, const Duration(seconds: 30));
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
}
