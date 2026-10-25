import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_state_json.dart';
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
    for (var i = 0; i < 3; i++) {
      reanimationsfall.recordSchock();
    }
    clock.advance(const Duration(seconds: 5));
    reanimationsfall.enterAnalysephase();
    reanimationsfall.recordRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
      notiz: 'VF',
    );
    reanimationsfall.continueCpr();
    clock.advance(const Duration(minutes: 1));
    reanimationsfall.recordRosc();
    clock.advance(const Duration(seconds: 20));
    reanimationsfall.resumeResuscitation();
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.endReanimationsfall(Beendigungsgrund.uebergabe);

    final state = reanimationsfall.exportState();
    final decoded = reanimationsfallStateFromJson(
      jsonDecode(jsonEncode(reanimationsfallStateToJson(state)))
          as Map<String, dynamic>,
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
    expect(decoded.schocks, hasLength(3));
    expect(decoded.adrenalinGaben, hasLength(1));
    expect(decoded.rhythmusanalyseEintraege.single.notiz, 'VF');
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
    expect(snapshot.schockAnzahl, 3);
    expect(snapshot.adrenalinGaben, hasLength(1));
    expect(snapshot.roscEreignisse, hasLength(1));
    expect(snapshot.wiederbeginnEreignisse, hasLength(1));
    expect(snapshot.rhythmusanalyseEintraege.single.notiz, 'VF');
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
