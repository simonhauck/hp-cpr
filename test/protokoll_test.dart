import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';

import 'support/fake_clock.dart';

void main() {
  ProtokollEintrag single(
    ReanimationsfallSnapshot snapshot,
    ProtokollEintragTyp typ,
  ) => snapshot.protokoll.eintraege.singleWhere((e) => e.typ == typ);

  List<ProtokollEintrag> allOf(
    ReanimationsfallSnapshot snapshot,
    ProtokollEintragTyp typ,
  ) => snapshot.protokoll.eintraege.where((e) => e.typ == typ).toList();

  test('gives every recorded event a stable unique id', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordSchock();
    reanimationsfall.recordAdrenalin();
    reanimationsfall.recordNotiz('Notiz');
    reanimationsfall.recordTemperatur(36.5);

    final ids = reanimationsfall
        .snapshot()
        .protokoll
        .eintraege
        .map((e) => e.ref.id)
        .toList();
    expect(ids.toSet(), hasLength(ids.length));

    final state = reanimationsfall.exportState();
    final restored = Reanimationsfall.restore(clock: clock, state: state);
    clock.advance(const Duration(seconds: 5));
    restored.recordSchock();

    final restoredIds = restored
        .snapshot()
        .protokoll
        .eintraege
        .map((e) => e.ref.id)
        .toList();
    expect(restoredIds.toSet(), hasLength(restoredIds.length));
  });

  test('removes a live Schock and recomputes the shock count and hints', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    for (var i = 0; i < 3; i++) {
      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordSchock();
    }
    reanimationsfall.enterAnalysephase();
    reanimationsfall.completeRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
    );

    expect(reanimationsfall.snapshot().schockAnzahl, 3);
    expect(
      reanimationsfall.snapshot().amiodaronHinweis,
      AmiodaronHinweis.ersteGabe,
    );
    expect(reanimationsfall.snapshot().istErsteAdrenalinGabeFaellig, isTrue);

    final removed = allOf(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.schock,
    ).first;
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: removed.ref),
    );

    final snapshot = reanimationsfall.snapshot();
    expect(snapshot.schockAnzahl, 2);
    expect(snapshot.amiodaronHinweis, AmiodaronHinweis.keine);
    expect(snapshot.istErsteAdrenalinGabeFaellig, isFalse);
    expect(
      snapshot.protokoll.eintraege.where(
        (e) => e.typ == ProtokollEintragTyp.schock,
      ),
      hasLength(2),
    );
    final audit = snapshot.protokoll.alleEintraege.singleWhere(
      (e) => e.ref == removed.ref,
    );
    expect(audit.istEntfernt, isTrue);
    expect(audit.istWiederherstellbar, isTrue);
  });

  test('recomputes the AHA first Adrenalin hint after a shock removal', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(
      clock: clock,
      leitlinienprofil: Leitlinienprofil.aha2025,
    );
    for (var i = 0; i < 2; i++) {
      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordSchock();
    }
    reanimationsfall.enterAnalysephase();
    reanimationsfall.completeRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
    );
    expect(reanimationsfall.snapshot().istErsteAdrenalinGabeFaellig, isTrue);

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(
        ziel: allOf(
          reanimationsfall.snapshot(),
          ProtokollEintragTyp.schock,
        ).first.ref,
      ),
    );
    expect(reanimationsfall.snapshot().istErsteAdrenalinGabeFaellig, isFalse);
  });

  test('corrects a live Schock time and energy and clears the energy', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordSchock(energieJoule: 200);

    final schock = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.schock,
    );
    reanimationsfall.applyProtokollKorrektur(
      SchockKorrigiert(
        ziel: schock.ref,
        zeitpunkt: const Duration(seconds: 5),
        energieJoule: 150,
      ),
    );

    var effective = reanimationsfall.snapshot().schocks.single;
    expect(effective.zeitpunkt, const Duration(seconds: 5));
    expect(effective.energieJoule, 150);

    reanimationsfall.applyProtokollKorrektur(
      SchockKorrigiert(ziel: schock.ref, zeitpunkt: const Duration(seconds: 6)),
    );

    effective = reanimationsfall.snapshot().schocks.single;
    expect(effective.zeitpunkt, const Duration(seconds: 6));
    expect(effective.energieJoule, isNull);
    expect(
      reanimationsfall
          .snapshot()
          .protokoll
          .alleEintraege
          .singleWhere((e) => e.ref == schock.ref)
          .originalDaten,
      isA<SchockEreignis>().having(
        (e) => e.energieJoule,
        'original energy',
        200,
      ),
    );
    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        SchockKorrigiert(
          ziel: schock.ref,
          zeitpunkt: const Duration(seconds: 6),
          energieJoule: 0,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('corrects and removes a live Adrenalin dose', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();
    reanimationsfall.completeRhythmusanalyse(RhythmusanalyseErgebnis.asystolie);
    clock.advance(const Duration(minutes: 3));
    reanimationsfall.recordAdrenalin();

    final gabe = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.adrenalin,
    );
    reanimationsfall.applyProtokollKorrektur(
      AdrenalinKorrigiert(
        ziel: gabe.ref,
        zeitpunkt: const Duration(minutes: 2),
        dosisMg: 2,
      ),
    );

    var snapshot = reanimationsfall.snapshot();
    expect(snapshot.letzteAdrenalinGabe!.dosisMg, 2);
    expect(snapshot.adrenalinSeitLetzterGabe, const Duration(minutes: 1));
    expect(
      snapshot.adrenalinZeitfensterZustand,
      AdrenalinZeitfensterZustand.wartet,
    );

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: gabe.ref),
    );
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.letzteAdrenalinGabe, isNull);
    expect(snapshot.istErsteAdrenalinGabeFaellig, isTrue);

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragWiederhergestellt(ziel: gabe.ref),
    );
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.letzteAdrenalinGabe!.dosisMg, 2);
    expect(snapshot.adrenalinSeitLetzterGabe, const Duration(minutes: 1));
  });

  test('uses the corrected latest Adrenalin dose for the Zeitfenster', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(minutes: 1));
    reanimationsfall.recordAdrenalin();
    final first = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.adrenalin,
    );
    clock.advance(const Duration(minutes: 1));
    reanimationsfall.recordAdrenalin();
    clock.advance(const Duration(minutes: 2));

    reanimationsfall.applyProtokollKorrektur(
      AdrenalinKorrigiert(
        ziel: first.ref,
        zeitpunkt: const Duration(minutes: 4),
        dosisMg: 2,
      ),
    );

    final snapshot = reanimationsfall.snapshot();
    expect(snapshot.letzteAdrenalinGabe!.id, first.ref.id);
    expect(snapshot.letzteAdrenalinGabe!.dosisMg, 2);
    expect(snapshot.adrenalinSeitLetzterGabe, Duration.zero);
  });

  test('corrects and removes a live Amiodaron dose', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    for (var i = 0; i < 3; i++) {
      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordSchock();
    }
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordAmiodaron();

    final gabe = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.amiodaron,
    );
    reanimationsfall.applyProtokollKorrektur(
      AmiodaronKorrigiert(
        ziel: gabe.ref,
        zeitpunkt: const Duration(seconds: 10),
        dosisMg: 150,
      ),
    );
    expect(reanimationsfall.snapshot().letzteAmiodaronGabe!.dosisMg, 150);
    expect(
      reanimationsfall.snapshot().letzteAmiodaronGabe!.zeitpunkt,
      const Duration(seconds: 10),
    );

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: gabe.ref),
    );
    expect(
      reanimationsfall.snapshot().amiodaronHinweis,
      AmiodaronHinweis.ersteGabe,
    );
    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        AmiodaronKorrigiert(
          ziel: gabe.ref,
          zeitpunkt: const Duration(seconds: 10),
          dosisMg: 0,
        ),
      ),
      throwsStateError,
    );

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragWiederhergestellt(ziel: gabe.ref),
    );
    expect(reanimationsfall.snapshot().letzteAmiodaronGabe!.dosisMg, 150);
  });

  test('records Amiodaron doses from the effective dose count', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    for (var i = 0; i < 3; i++) {
      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordSchock();
    }
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordAmiodaron();
    final first = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.amiodaron,
    );
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: first.ref),
    );

    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordAmiodaron();
    expect(reanimationsfall.snapshot().amiodaronGaben.single.dosisMg, 300);

    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordAmiodaron();
    expect(reanimationsfall.snapshot().amiodaronGaben.map((e) => e.dosisMg), [
      300,
      150,
    ]);

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(
        ziel: reanimationsfall
            .snapshot()
            .protokoll
            .eintraege
            .firstWhere(
              (e) =>
                  e.typ == ProtokollEintragTyp.amiodaron &&
                  (e.daten as AmiodaronGabe).dosisMg == 300,
            )
            .ref,
      ),
    );
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordAmiodaron();
    expect(reanimationsfall.snapshot().amiodaronGaben.map((e) => e.dosisMg), [
      150,
      150,
    ]);
  });

  test('corrects, removes, and restores a live Messwert and Notiz', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordTemperatur(36.5, notiz: 'rektal');
    reanimationsfall.recordNotiz('Erste Notiz');

    final messwert = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.messwert,
    );
    reanimationsfall.applyProtokollKorrektur(
      MesswertKorrigiert(
        ziel: messwert.ref,
        ersatz: TemperaturMesswert(
          id: messwert.ref.id,
          zeitpunkt: const Duration(seconds: 5),
          celsius: 37.2,
          notiz: 'oral',
        ),
      ),
    );
    var snapshot = reanimationsfall.snapshot();
    final effective = snapshot.messwerte.single as TemperaturMesswert;
    expect(effective.celsius, 37.2);
    expect(effective.notiz, 'oral');
    expect(effective.zeitpunkt, const Duration(seconds: 5));

    final notiz = single(snapshot, ProtokollEintragTyp.notiz);
    reanimationsfall.applyProtokollKorrektur(
      NotizKorrigiert(
        ziel: notiz.ref,
        zeitpunkt: const Duration(seconds: 6),
        text: 'Korrigierte Notiz',
      ),
    );
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.notizen.single.text, 'Korrigierte Notiz');
    expect(snapshot.notizen.single.zeitpunkt, const Duration(seconds: 6));

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: messwert.ref),
    );
    expect(reanimationsfall.snapshot().messwerte, isEmpty);
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragWiederhergestellt(ziel: messwert.ref),
    );
    expect(
      reanimationsfall.snapshot().messwerte.single,
      isA<TemperaturMesswert>(),
    );

    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        MesswertKorrigiert(
          ziel: messwert.ref,
          ersatz: BlutzuckerMesswert(
            id: messwert.ref.id,
            zeitpunkt: const Duration(seconds: 5),
            mgDl: 100,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects structural corrections while the case is open', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();
    reanimationsfall.completeRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
    );

    final rhythmusanalyse = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.rhythmusanalyse,
    );
    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        RhythmusanalyseKorrigiert(
          ziel: rhythmusanalyse.ref,
          zeitpunkt: Duration.zero,
          ergebnis: RhythmusanalyseErgebnis.pulsloseKammertachykardie,
        ),
      ),
      throwsStateError,
    );
    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        ProtokollEintragEntfernt(ziel: rhythmusanalyse.ref),
      ),
      throwsStateError,
    );
  });

  test('rebuilds CPR duration after a completed ROSC correction', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(minutes: 2));
    reanimationsfall.enterAnalysephase();
    clock.advance(const Duration(minutes: 1));
    reanimationsfall.completeRhythmusanalyse(RhythmusanalyseErgebnis.rosc);
    clock.advance(const Duration(minutes: 1));
    reanimationsfall.resumeResuscitation();
    clock.advance(const Duration(minutes: 1));
    reanimationsfall.endReanimationsfall(Beendigungsgrund.uebergabe);

    var snapshot = reanimationsfall.snapshot();
    expect(snapshot.cprDauer, const Duration(minutes: 4));
    expect(snapshot.abschnitte, hasLength(2));

    final rosc = single(snapshot, ProtokollEintragTyp.rosc);
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: rosc.ref),
    );
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.roscEreignisse, isEmpty);
    expect(snapshot.cprDauer, const Duration(minutes: 5));
    expect(snapshot.abschnitte, hasLength(1));
    expect(
      snapshot.rhythmusanalyseEintraege.where(
        (e) => e.ergebnis == RhythmusanalyseErgebnis.rosc,
      ),
      isEmpty,
    );

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragWiederhergestellt(ziel: rosc.ref),
    );
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.cprDauer, const Duration(minutes: 4));

    reanimationsfall.applyProtokollKorrektur(
      RoscKorrigiert(
        ziel: rosc.ref,
        zeitpunkt: const Duration(minutes: 2, seconds: 30),
      ),
    );
    snapshot = reanimationsfall.snapshot();
    expect(
      snapshot.roscEreignisse.single.zeitpunkt,
      const Duration(minutes: 2, seconds: 30),
    );
    expect(snapshot.cprDauer, const Duration(minutes: 3, seconds: 30));
    expect(
      snapshot.rhythmusanalyseEintraege.single.zeitpunkt,
      const Duration(minutes: 2, seconds: 30),
    );

    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        RoscKorrigiert(ziel: rosc.ref, zeitpunkt: const Duration(minutes: 6)),
      ),
      throwsArgumentError,
    );
    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        RoscKorrigiert(
          ziel: rosc.ref,
          zeitpunkt: const Duration(minutes: 4, seconds: 30),
        ),
      ),
      throwsArgumentError,
    );

    final wiederbeginn = single(snapshot, ProtokollEintragTyp.wiederbeginn);
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: wiederbeginn.ref),
    );
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.cprDauer, const Duration(minutes: 2, seconds: 30));
    expect(snapshot.abschnitte, hasLength(1));

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragWiederhergestellt(ziel: wiederbeginn.ref),
    );
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.cprDauer, const Duration(minutes: 3, seconds: 30));
    expect(snapshot.abschnitte, hasLength(2));
  });

  test('corrects a completed Rhythmusanalyse result but not to ROSC', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();
    reanimationsfall.completeRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
    );
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.endReanimationsfall(Beendigungsgrund.uebergabe);

    final rhythmusanalyse = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.rhythmusanalyse,
    );
    reanimationsfall.applyProtokollKorrektur(
      RhythmusanalyseKorrigiert(
        ziel: rhythmusanalyse.ref,
        zeitpunkt: const Duration(seconds: 5),
        ergebnis: RhythmusanalyseErgebnis.pulsloseKammertachykardie,
      ),
    );
    expect(
      reanimationsfall.snapshot().rhythmusanalyseEintraege.single.ergebnis,
      RhythmusanalyseErgebnis.pulsloseKammertachykardie,
    );
    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        RhythmusanalyseKorrigiert(
          ziel: rhythmusanalyse.ref,
          zeitpunkt: const Duration(seconds: 5),
          ergebnis: RhythmusanalyseErgebnis.rosc,
        ),
      ),
      throwsArgumentError,
    );

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: rhythmusanalyse.ref),
    );
    expect(reanimationsfall.snapshot().rhythmusanalyseEintraege, isEmpty);
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragWiederhergestellt(ziel: rhythmusanalyse.ref),
    );
    expect(
      reanimationsfall.snapshot().rhythmusanalyseEintraege.single.ergebnis,
      RhythmusanalyseErgebnis.pulsloseKammertachykardie,
    );
  });

  test('allows clinical corrections on a Verworfen case', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordSchock();
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.restartDruckphase();
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.discardReanimationsfall();

    final snapshot = reanimationsfall.snapshot();
    final schock = single(snapshot, ProtokollEintragTyp.schock);
    final neustart = single(snapshot, ProtokollEintragTyp.druckphaseNeustart);

    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: schock.ref),
    );
    reanimationsfall.applyProtokollKorrektur(
      ZeitpunktKorrigiert(
        ziel: neustart.ref,
        zeitpunkt: const Duration(seconds: 20),
      ),
    );

    expect(reanimationsfall.snapshot().schocks, isEmpty);
    expect(
      reanimationsfall.snapshot().druckphaseNeustarts.single.zeitpunkt,
      const Duration(seconds: 20),
    );
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: neustart.ref),
    );
    expect(reanimationsfall.snapshot().druckphaseNeustarts, isEmpty);
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragWiederhergestellt(ziel: neustart.ref),
    );
    expect(
      reanimationsfall.snapshot().druckphaseNeustarts.single.zeitpunkt,
      const Duration(seconds: 20),
    );
    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        ProtokollEintragEntfernt(
          ziel: const ProtokollEintragRef(
            typ: ProtokollEintragTyp.reanimationsfallEnde,
            id: 'reanimationsfall-ende',
          ),
        ),
      ),
      throwsStateError,
    );
  });

  test('shows one ROSC entry and hides its paired Rhythmusanalyse', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();
    reanimationsfall.completeRhythmusanalyse(RhythmusanalyseErgebnis.rosc);

    final snapshot = reanimationsfall.snapshot();
    expect(
      snapshot.protokoll.eintraege.where(
        (e) => e.typ == ProtokollEintragTyp.rosc,
      ),
      hasLength(1),
    );
    expect(
      snapshot.protokoll.eintraege.where(
        (e) => e.typ == ProtokollEintragTyp.rhythmusanalyse,
      ),
      isEmpty,
    );
    expect(
      snapshot.rhythmusanalyseEintraege.single.ergebnis,
      RhythmusanalyseErgebnis.rosc,
    );

    final rosc = single(snapshot, ProtokollEintragTyp.rosc);
    final roscEvent = rosc.daten as RoscEreignis;
    expect(roscEvent.rhythmusanalyseId, isNotNull);
  });

  test('renumbers shocks after a removal', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    for (var i = 0; i < 3; i++) {
      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordSchock();
    }

    final shocks = allOf(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.schock,
    );
    reanimationsfall.applyProtokollKorrektur(
      ProtokollEintragEntfernt(ziel: shocks[1].ref),
    );

    final remaining = allOf(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.schock,
    );
    expect(remaining.map((e) => e.nummer), [1, 2]);
  });

  test('rejects a live correction after the current case time', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.recordSchock();
    final schock = single(
      reanimationsfall.snapshot(),
      ProtokollEintragTyp.schock,
    );

    expect(
      () => reanimationsfall.applyProtokollKorrektur(
        SchockKorrigiert(
          ziel: schock.ref,
          zeitpunkt: const Duration(seconds: 20),
        ),
      ),
      throwsArgumentError,
    );
  });
}
