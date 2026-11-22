import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';

import 'support/fake_clock.dart';

/// Structural Protokoll corrections during a running case (#57, ADR 0007).
void main() {
  late FakeClock clock;
  late Reanimationsfall fall;

  setUp(() {
    clock = FakeClock();
    fall = Reanimationsfall.start(clock: clock);
  });

  void advance(int seconds) => clock.advance(Duration(seconds: seconds));

  Duration s(int seconds) => Duration(seconds: seconds);

  ProtokollEintrag latest(ProtokollEintragTyp typ) =>
      fall.snapshot().protokoll.eintraege.lastWhere((e) => e.typ == typ);

  Iterable<ProtokollEintrag> visible(ProtokollEintragTyp typ) =>
      fall.snapshot().protokoll.eintraege.where((e) => e.typ == typ);

  void remove(ProtokollEintragTyp typ) => fall.applyProtokollKorrektur(
    ProtokollEintragEntfernt(ziel: latest(typ).ref),
  );

  void retime(ProtokollEintragTyp typ, Duration zeitpunkt) =>
      fall.applyProtokollKorrektur(
        ZeitpunktKorrigiert(ziel: latest(typ).ref, zeitpunkt: zeitpunkt),
      );

  test('records the Analysephase start as an editable Protokolleintrag', () {
    advance(90);
    fall.enterAnalysephase();

    final beginn = latest(ProtokollEintragTyp.analysephaseBeginn);
    expect(beginn.zeitpunkt, s(90));
    expect(beginn.daten, isA<AnalysephaseBeginn>());
    expect(beginn.istBearbeitbar, isTrue);
    expect(fall.snapshot().analysephaseBeginne, hasLength(1));
  });

  test('every structural entry is editable while the case is open', () {
    advance(30);
    fall.restartDruckphase();
    advance(90);
    fall.enterAnalysephase();
    fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.rosc);
    advance(30);
    fall.resumeResuscitation();

    final strukturell = fall.snapshot().protokoll.eintraege.where(
      (e) => e.typ.istStrukturell,
    );
    expect(strukturell, isNotEmpty);
    for (final eintrag in strukturell) {
      expect(eintrag.istBearbeitbar, isTrue, reason: eintrag.typ.name);
    }
  });

  group('removing the current Analysephase start', () {
    test('returns to the Druckphase and the earlier cycle continues', () {
      advance(30);
      fall.recordAdrenalin();
      advance(60);
      fall.enterAnalysephase();
      advance(20);

      var snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.analysephase);
      expect(snapshot.compressionRemaining, s(30));
      expect(snapshot.pauseDuration, s(20));

      remove(ProtokollEintragTyp.analysephaseBeginn);

      snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, s(10));
      expect(snapshot.pauseDuration, Duration.zero);
      expect(snapshot.isRhythmusanalyseDue, isFalse);
      // Record-only state is untouched.
      expect(snapshot.adrenalinSeitLetzterGabe, s(80));
      expect(
        snapshot.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.wartet,
      );

      advance(15);
      snapshot = fall.snapshot();
      expect(snapshot.isRhythmusanalyseDue, isTrue);
      expect(snapshot.rhythmusanalyseOverdue, s(5));
      expect(snapshot.compressionRemaining, Duration.zero);
    });

    test('keeps the original only in the Änderungsverlauf', () {
      advance(90);
      fall.enterAnalysephase();
      remove(ProtokollEintragTyp.analysephaseBeginn);

      final protokoll = fall.snapshot().protokoll;
      expect(
        protokoll.eintraege.where(
          (e) => e.typ == ProtokollEintragTyp.analysephaseBeginn,
        ),
        isEmpty,
      );
      final original = protokoll.alleEintraege.singleWhere(
        (e) => e.typ == ProtokollEintragTyp.analysephaseBeginn,
      );
      expect(original.istEntfernt, isTrue);
      expect(original.istWiederherstellbar, isTrue);
    });

    test('restoring it re-enters the Analysephase', () {
      advance(90);
      fall.enterAnalysephase();
      final ref = latest(ProtokollEintragTyp.analysephaseBeginn).ref;
      fall.applyProtokollKorrektur(ProtokollEintragEntfernt(ziel: ref));
      advance(10);
      fall.applyProtokollKorrektur(
        ProtokollEintragWiederhergestellt(ziel: ref),
      );

      final snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.analysephase);
      expect(snapshot.pauseDuration, s(10));
      expect(snapshot.compressionRemaining, s(30));
    });

    test('the recording commands keep working afterwards', () {
      advance(90);
      fall.enterAnalysephase();
      remove(ProtokollEintragTyp.analysephaseBeginn);
      advance(40);

      fall.enterAnalysephase();
      fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.asystolie);

      final snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, s(120));
      expect(visible(ProtokollEintragTyp.analysephaseBeginn), hasLength(1));
    });
  });

  group('Rhythmusanalyse result', () {
    test('removing the latest result returns to the Analysephase', () {
      advance(120);
      fall.enterAnalysephase();
      advance(10);
      fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.asystolie);
      advance(30);

      var snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, s(90));
      expect(snapshot.istErsteAdrenalinGabeFaellig, isTrue);

      remove(ProtokollEintragTyp.rhythmusanalyse);

      snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.analysephase);
      expect(snapshot.pauseDuration, s(40));
      expect(snapshot.isPauseOverdue, isTrue);
      expect(snapshot.compressionRemaining, Duration.zero);
      expect(snapshot.istErsteAdrenalinGabeFaellig, isFalse);

      fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.pea);
      snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, s(120));
      expect(snapshot.istErsteAdrenalinGabeFaellig, isTrue);
    });

    test('removing a result keeps its Schock as a separate entry', () {
      for (var i = 0; i < 2; i++) {
        advance(10);
        fall.recordSchock();
      }
      advance(100);
      fall.enterAnalysephase();
      fall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.kammerflimmern,
        schockAbgegeben: true,
      );

      var snapshot = fall.snapshot();
      expect(snapshot.schockAnzahl, 3);
      expect(snapshot.amiodaronHinweis, AmiodaronHinweis.ersteGabe);

      remove(ProtokollEintragTyp.rhythmusanalyse);

      snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.analysephase);
      expect(snapshot.schockAnzahl, 3);
      expect(snapshot.amiodaronHinweis, AmiodaronHinweis.ersteGabe);

      remove(ProtokollEintragTyp.schock);
      snapshot = fall.snapshot();
      expect(snapshot.schockAnzahl, 2);
      expect(snapshot.amiodaronHinweis, AmiodaronHinweis.keine);
    });

    test('correcting the result updates the Adrenalin trigger', () {
      advance(120);
      fall.enterAnalysephase();
      advance(10);
      fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.unklar);
      expect(fall.snapshot().istErsteAdrenalinGabeFaellig, isFalse);

      fall.applyProtokollKorrektur(
        RhythmusanalyseKorrigiert(
          ziel: latest(ProtokollEintragTyp.rhythmusanalyse).ref,
          zeitpunkt: s(130),
          ergebnis: RhythmusanalyseErgebnis.asystolie,
        ),
      );

      final snapshot = fall.snapshot();
      expect(snapshot.istErsteAdrenalinGabeFaellig, isTrue);
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(
        visible(ProtokollEintragTyp.rhythmusanalyse).single.daten,
        isA<RhythmusanalyseEintrag>().having(
          (e) => e.ergebnis,
          'ergebnis',
          RhythmusanalyseErgebnis.asystolie,
        ),
      );
    });

    test('correcting the time restarts the cycle from the new time', () {
      advance(120);
      fall.enterAnalysephase();
      advance(10);
      fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.unklar);
      advance(30);
      expect(fall.snapshot().compressionRemaining, s(90));

      fall.applyProtokollKorrektur(
        RhythmusanalyseKorrigiert(
          ziel: latest(ProtokollEintragTyp.rhythmusanalyse).ref,
          zeitpunkt: s(125),
          ergebnis: RhythmusanalyseErgebnis.unklar,
        ),
      );

      expect(fall.snapshot().compressionRemaining, s(85));
    });

    test('rejects a time before its Analysephase start', () {
      advance(120);
      fall.enterAnalysephase();
      advance(10);
      fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.unklar);

      expect(
        () => fall.applyProtokollKorrektur(
          RhythmusanalyseKorrigiert(
            ziel: latest(ProtokollEintragTyp.rhythmusanalyse).ref,
            zeitpunkt: s(115),
            ergebnis: RhythmusanalyseErgebnis.unklar,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => retime(ProtokollEintragTyp.analysephaseBeginn, s(131)),
        throwsArgumentError,
      );
    });
  });

  group('Überspringung', () {
    setUp(() {
      advance(120);
      fall.enterAnalysephase();
      advance(5);
      fall.skipRhythmusanalyse();
      advance(30);
    });

    test('removing it returns to the Analysephase', () {
      expect(fall.snapshot().compressionRemaining, s(90));

      remove(ProtokollEintragTyp.ueberspringung);

      final snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.analysephase);
      expect(snapshot.pauseDuration, s(35));
    });

    test('restoring it resumes the Druckphase', () {
      final ref = latest(ProtokollEintragTyp.ueberspringung).ref;
      fall.applyProtokollKorrektur(ProtokollEintragEntfernt(ziel: ref));
      fall.applyProtokollKorrektur(
        ProtokollEintragWiederhergestellt(ziel: ref),
      );

      final snapshot = fall.snapshot();
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, s(90));
    });

    test('correcting its time moves the cycle start', () {
      retime(ProtokollEintragTyp.ueberspringung, s(122));
      expect(fall.snapshot().compressionRemaining, s(87));
    });
  });

  group('DruckphaseNeustart', () {
    setUp(() {
      advance(60);
      fall.restartDruckphase();
      advance(30);
    });

    test('removing it continues the earlier cycle', () {
      expect(fall.snapshot().compressionRemaining, s(90));
      remove(ProtokollEintragTyp.druckphaseNeustart);
      expect(fall.snapshot().compressionRemaining, s(30));
    });

    test('restoring it restarts the cycle again', () {
      final ref = latest(ProtokollEintragTyp.druckphaseNeustart).ref;
      fall.applyProtokollKorrektur(ProtokollEintragEntfernt(ziel: ref));
      fall.applyProtokollKorrektur(
        ProtokollEintragWiederhergestellt(ziel: ref),
      );
      expect(fall.snapshot().compressionRemaining, s(90));
    });

    test('correcting its time moves the cycle start', () {
      retime(ProtokollEintragTyp.druckphaseNeustart, s(40));
      expect(fall.snapshot().compressionRemaining, s(70));
    });

    test('rejects a time after the current moment', () {
      expect(
        () => retime(ProtokollEintragTyp.druckphaseNeustart, s(91)),
        throwsArgumentError,
      );
    });
  });

  group('ROSC', () {
    test('removing a manual ROSC continues the earlier Druckphase', () {
      advance(50);
      fall.recordRosc();
      advance(20);
      expect(fall.snapshot().zustand, ReanimationsfallZustand.rosc);

      remove(ProtokollEintragTyp.rosc);

      final snapshot = fall.snapshot();
      expect(snapshot.zustand, ReanimationsfallZustand.laufend);
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, s(50));
      expect(snapshot.abschnitte, hasLength(1));
    });

    test('removing a ROSC also removes the following Wiederbeginn', () {
      advance(120);
      fall.enterAnalysephase();
      advance(10);
      fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.rosc);
      advance(30);
      fall.resumeResuscitation();
      advance(30);

      remove(ProtokollEintragTyp.rosc);

      var snapshot = fall.snapshot();
      expect(snapshot.zustand, ReanimationsfallZustand.laufend);
      expect(visible(ProtokollEintragTyp.rosc), isEmpty);
      expect(visible(ProtokollEintragTyp.wiederbeginn), isEmpty);
      expect(visible(ProtokollEintragTyp.rhythmusanalyse), isEmpty);
      // The Analysephase that led to the ROSC result is open again.
      expect(snapshot.phase, Reanimationsphase.analysephase);
      expect(snapshot.pauseDuration, s(70));

      fall.applyProtokollKorrektur(
        ProtokollEintragWiederhergestellt(
          ziel: fall
              .snapshot()
              .protokoll
              .alleEintraege
              .singleWhere((e) => e.typ == ProtokollEintragTyp.rosc)
              .ref,
        ),
      );

      snapshot = fall.snapshot();
      expect(snapshot.zustand, ReanimationsfallZustand.laufend);
      expect(visible(ProtokollEintragTyp.rosc), hasLength(1));
      expect(visible(ProtokollEintragTyp.wiederbeginn), hasLength(1));
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, s(90));
      expect(snapshot.abschnitte, hasLength(2));
    });

    test('removing only the Wiederbeginn returns to the ROSC state', () {
      advance(50);
      fall.recordRosc();
      advance(20);
      fall.resumeResuscitation();
      advance(20);

      remove(ProtokollEintragTyp.wiederbeginn);

      final snapshot = fall.snapshot();
      expect(snapshot.zustand, ReanimationsfallZustand.rosc);
      expect(snapshot.compressionRemaining, Duration.zero);
      expect(snapshot.abschnitte, hasLength(1));
    });

    test('correcting a Wiederbeginn time moves the cycle start', () {
      advance(50);
      fall.recordRosc();
      advance(20);
      fall.resumeResuscitation();
      advance(20);

      retime(ProtokollEintragTyp.wiederbeginn, s(60));

      expect(fall.snapshot().compressionRemaining, s(90));
      expect(
        () => retime(ProtokollEintragTyp.wiederbeginn, s(40)),
        throwsArgumentError,
      );
    });
  });

  test('replaying an uncorrected Protokoll keeps the live state', () {
    advance(30);
    fall.restartDruckphase();
    advance(120);
    fall.enterAnalysephase();
    advance(10);
    fall.completeRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
      schockAbgegeben: true,
    );
    advance(60);
    fall.recordAdrenalin();
    advance(60);
    fall.enterAnalysephase();
    advance(10);
    fall.completeRhythmusanalyse(RhythmusanalyseErgebnis.asystolie);
    advance(100);
    fall.enterAnalysephase();
    advance(7);

    final before = fall.snapshot();
    // A same-time correction triggers the replay without changing history.
    retime(ProtokollEintragTyp.druckphaseNeustart, s(30));
    final after = fall.snapshot();

    expect(after.zustand, before.zustand);
    expect(after.phase, before.phase);
    expect(after.compressionRemaining, before.compressionRemaining);
    expect(after.pauseDuration, before.pauseDuration);
    expect(after.isRhythmusanalyseDue, before.isRhythmusanalyseDue);
    expect(
      after.istErsteAdrenalinGabeFaellig,
      before.istErsteAdrenalinGabeFaellig,
    );
    expect(
      after.adrenalinZeitfensterZustand,
      before.adrenalinZeitfensterZustand,
    );
    expect(after.amiodaronHinweis, before.amiodaronHinweis);
    expect(after.schockAnzahl, before.schockAnzahl);
  });

  test('structural corrections use Protokoll times after a Startzeit '
      'correction', () {
    advance(30);
    fall.restartDruckphase();
    advance(30);
    fall.applyProtokollKorrektur(
      const VorbehandlungKorrigiert(
        uebernahme: Duration.zero,
        laufzeitBeiUebernahme: Duration(minutes: 5),
      ),
    );

    final neustart = latest(ProtokollEintragTyp.druckphaseNeustart);
    expect(neustart.zeitpunkt, s(330));
    expect(fall.snapshot().compressionRemaining, s(90));

    retime(ProtokollEintragTyp.druckphaseNeustart, s(340));

    expect(latest(ProtokollEintragTyp.druckphaseNeustart).zeitpunkt, s(340));
    expect(fall.snapshot().compressionRemaining, s(100));
    // Structural entries cannot move before the Übernahme.
    expect(
      () => retime(ProtokollEintragTyp.druckphaseNeustart, s(290)),
      throwsArgumentError,
    );
  });

  test('a corrected live state survives export and restore', () {
    advance(90);
    fall.enterAnalysephase();
    advance(10);
    remove(ProtokollEintragTyp.analysephaseBeginn);

    final restored = Reanimationsfall.restore(
      clock: clock,
      state: fall.exportState(),
    );
    final snapshot = restored.snapshot();
    expect(snapshot.phase, Reanimationsphase.druckphase);
    expect(snapshot.compressionRemaining, s(20));
    expect(
      snapshot.protokoll.alleEintraege
          .singleWhere((e) => e.typ == ProtokollEintragTyp.analysephaseBeginn)
          .istEntfernt,
      isTrue,
    );
  });
}
