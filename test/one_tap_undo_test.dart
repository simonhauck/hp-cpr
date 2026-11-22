import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';

import 'support/fake_clock.dart';

/// The references one-tap commands return so the UI can undo them (#66).
void main() {
  late FakeClock clock;
  late Reanimationsfall fall;

  setUp(() {
    clock = FakeClock();
    fall = Reanimationsfall.start(clock: clock);
  });

  void undo(Iterable<ProtokollEintragRef> refs) {
    for (final ref in refs) {
      fall.applyProtokollKorrektur(ProtokollEintragEntfernt(ziel: ref));
    }
  }

  ProtokollEintrag eintrag(ProtokollEintragRef ref) =>
      fall.snapshot().protokoll.alleEintraege.singleWhere((e) => e.ref == ref);

  test('each one-tap command returns the entry it recorded', () {
    expect(fall.recordAdrenalin().typ, ProtokollEintragTyp.adrenalin);
    expect(fall.recordSchock().typ, ProtokollEintragTyp.schock);
    expect(
      fall.restartDruckphase().typ,
      ProtokollEintragTyp.druckphaseNeustart,
    );
    expect(
      fall.enterAnalysephase().typ,
      ProtokollEintragTyp.analysephaseBeginn,
    );
    expect(fall.skipRhythmusanalyse().typ, ProtokollEintragTyp.ueberspringung);
    fall.enterAnalysephase();
    expect(
      fall
          .completeRhythmusanalyse(RhythmusanalyseErgebnis.asystolie)
          .map((ref) => ref.typ),
      [ProtokollEintragTyp.rhythmusanalyse],
    );
  });

  test('undo keeps the original entry in the full Protokoll', () {
    final ref = fall.recordAdrenalin();
    undo([ref]);

    expect(fall.snapshot().adrenalinGaben, isEmpty);
    expect(eintrag(ref).istEntfernt, isTrue);
  });

  test('undoing a shockable result with a Schock returns to the '
      'Analysephase', () {
    fall.enterAnalysephase();
    final refs = fall.completeRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
      schockAbgegeben: true,
    );
    expect(refs.map((ref) => ref.typ), [
      ProtokollEintragTyp.rhythmusanalyse,
      ProtokollEintragTyp.schock,
    ]);

    undo(refs);

    final snapshot = fall.snapshot();
    expect(snapshot.phase, Reanimationsphase.analysephase);
    expect(snapshot.schockAnzahl, 0);
  });

  test('undoing a ROSC result returns to the running Analysephase', () {
    fall.enterAnalysephase();
    final refs = fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.rosc);
    expect(refs.map((ref) => ref.typ), [ProtokollEintragTyp.rosc]);
    expect(fall.snapshot().istRosc, isTrue);

    undo(refs);

    final snapshot = fall.snapshot();
    expect(snapshot.istLaufend, isTrue);
    expect(snapshot.phase, Reanimationsphase.analysephase);
    expect(
      snapshot.protokoll.eintraege.where(
        (e) => e.typ == ProtokollEintragTyp.rhythmusanalyse,
      ),
      isEmpty,
    );
  });
}
