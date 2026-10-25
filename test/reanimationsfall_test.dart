import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';

import 'support/fake_clock.dart';

void main() {
  group('Druckphase', () {
    test('starts at two minutes with the first compression as Startzeit', () {
      final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8, 30));
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      final snapshot = reanimationsfall.snapshot();

      expect(snapshot.startzeit, DateTime(2026, 10, 25, 8, 30));
      expect(snapshot.reanimationsdauer, Duration.zero);
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.compressionRemaining, const Duration(minutes: 2));
      expect(snapshot.isRhythmusanalyseDue, isFalse);
      expect(snapshot.leitlinienprofil, Leitlinienprofil.erc2025);
    });

    test('counts the compression cycle down while the Druckphase runs', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 30));

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.reanimationsdauer, const Duration(seconds: 30));
      expect(snapshot.compressionRemaining, const Duration(seconds: 90));
      expect(snapshot.isRhythmusanalyseDue, isFalse);
    });

    test(
      'makes the Rhythmusanalyse due at 0:00 and counts overdue time up',
      () {
        final clock = FakeClock();
        final reanimationsfall = Reanimationsfall.start(clock: clock);

        clock.advance(const Duration(minutes: 2));
        final due = reanimationsfall.snapshot();

        expect(due.isRhythmusanalyseDue, isTrue);
        expect(due.phase, Reanimationsphase.druckphase);
        expect(due.compressionRemaining, Duration.zero);
        expect(due.rhythmusanalyseOverdue, Duration.zero);

        clock.advance(const Duration(seconds: 5));
        final overdue = reanimationsfall.snapshot();

        expect(overdue.isRhythmusanalyseDue, isTrue);
        expect(
          overdue.reanimationsdauer,
          const Duration(minutes: 2, seconds: 5),
        );
        expect(overdue.rhythmusanalyseOverdue, const Duration(seconds: 5));
      },
    );

    test('backdates the Startzeit and starts at the matching cycle offset', () {
      final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8, 30));
      final reanimationsfall = Reanimationsfall.start(
        clock: clock,
        backdate: const Duration(minutes: 1),
      );

      final snapshot = reanimationsfall.snapshot();

      expect(snapshot.startzeit, DateTime(2026, 10, 25, 8, 29));
      expect(snapshot.reanimationsdauer, const Duration(minutes: 1));
      expect(snapshot.compressionRemaining, const Duration(minutes: 1));
      expect(snapshot.isRhythmusanalyseDue, isFalse);
    });

    test('starts a long-running case already due for the Rhythmusanalyse', () {
      final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8, 30));
      final reanimationsfall = Reanimationsfall.start(
        clock: clock,
        backdate: const Duration(minutes: 5),
      );

      final snapshot = reanimationsfall.snapshot();

      expect(snapshot.startzeit, DateTime(2026, 10, 25, 8, 25));
      expect(snapshot.reanimationsdauer, const Duration(minutes: 5));
      expect(snapshot.isRhythmusanalyseDue, isTrue);
      expect(snapshot.rhythmusanalyseOverdue, const Duration(minutes: 3));
    });

    test('rejects a negative backdate', () {
      final clock = FakeClock();

      expect(
        () => Reanimationsfall.start(
          clock: clock,
          backdate: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('snapshots the alert settings per Reanimationsfall', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(
        clock: clock,
        vibrationEnabled: false,
        soundEnabled: true,
      );

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.vibrationEnabled, isFalse);
      expect(snapshot.soundEnabled, isTrue);
    });
  });

  group('Analysephase', () {
    test('pauses the compression timer and starts the pause counter', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 45));
      reanimationsfall.enterAnalysephase();

      final paused = reanimationsfall.snapshot();
      expect(paused.phase, Reanimationsphase.analysephase);
      expect(paused.compressionRemaining, const Duration(seconds: 75));
      expect(paused.pauseDuration, Duration.zero);
      expect(paused.isPauseOverdue, isFalse);

      clock.advance(const Duration(seconds: 30));
      final later = reanimationsfall.snapshot();

      expect(later.compressionRemaining, const Duration(seconds: 75));
      expect(later.pauseDuration, const Duration(seconds: 30));
    });

    test('uses the Leitlinienprofil-specific pause target', () {
      for (final (profil, target) in [
        (Leitlinienprofil.erc2025, const Duration(seconds: 5)),
        (Leitlinienprofil.aha2025, const Duration(seconds: 10)),
      ]) {
        final clock = FakeClock();
        final reanimationsfall = Reanimationsfall.start(
          clock: clock,
          leitlinienprofil: profil,
        );
        reanimationsfall.enterAnalysephase();

        clock.advance(target);
        final atTarget = reanimationsfall.snapshot();
        expect(atTarget.isPauseOverdue, isFalse, reason: '$profil');

        clock.advance(const Duration(seconds: 1));
        final overdue = reanimationsfall.snapshot();
        expect(overdue.isPauseOverdue, isTrue, reason: '$profil');
        expect(
          overdue.pauseDuration,
          target + const Duration(seconds: 1),
          reason: '$profil',
        );
      }
    });

    test('rejects entering the Analysephase twice', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.enterAnalysephase();

      expect(reanimationsfall.enterAnalysephase, throwsStateError);
    });

    test('completeRhythmusanalyse records a shockable result without a shock '
        'and starts a fresh two-minute Druckphase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 45));
      reanimationsfall.enterAnalysephase();
      clock.advance(const Duration(seconds: 5));
      reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.kammerflimmern,
      );

      final resumed = reanimationsfall.snapshot();
      expect(resumed.phase, Reanimationsphase.druckphase);
      expect(resumed.compressionRemaining, const Duration(minutes: 2));
      expect(resumed.pauseDuration, Duration.zero);
      expect(resumed.rhythmusanalyseEintraege, hasLength(1));
      expect(
        resumed.rhythmusanalyseEintraege.single.ergebnis,
        RhythmusanalyseErgebnis.kammerflimmern,
      );
      expect(
        resumed.rhythmusanalyseEintraege.single.zeitpunkt,
        const Duration(seconds: 50),
      );
      expect(resumed.schockAnzahl, 0);

      clock.advance(const Duration(seconds: 10));
      expect(
        reanimationsfall.snapshot().compressionRemaining,
        const Duration(minutes: 1, seconds: 50),
      );
    });

    test('completeRhythmusanalyse records the result before the shock and '
        'starts a fresh two-minute Druckphase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 30));
      reanimationsfall.enterAnalysephase();
      clock.advance(const Duration(seconds: 5));
      reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.pulsloseKammertachykardie,
        schockAbgegeben: true,
      );

      final resumed = reanimationsfall.snapshot();
      expect(resumed.phase, Reanimationsphase.druckphase);
      expect(resumed.compressionRemaining, const Duration(minutes: 2));
      expect(resumed.schockAnzahl, 1);
      expect(resumed.schocks.single.zeitpunkt, const Duration(seconds: 35));
      expect(resumed.schocks.single.energieJoule, isNull);
      expect(
        resumed.rhythmusanalyseEintraege.single.zeitpunkt,
        const Duration(seconds: 35),
      );
    });

    test('completeRhythmusanalyse records a non-shockable result and makes '
        'the first Adrenalin dose due', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.enterAnalysephase();
      reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.asystolie,
      );

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.phase, Reanimationsphase.druckphase);
      expect(snapshot.istErsteAdrenalinGabeFaellig, isTrue);
      expect(
        snapshot.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.keine,
      );
      expect(snapshot.adrenalinGaben, isEmpty);
      expect(snapshot.letzteAdrenalinGabe, isNull);
    });

    test(
      'completeRhythmusanalyse records Unklar without a note and resumes',
      () {
        final clock = FakeClock();
        final reanimationsfall = Reanimationsfall.start(clock: clock);

        reanimationsfall.enterAnalysephase();
        reanimationsfall.completeRhythmusanalyse(
          RhythmusanalyseErgebnis.unklar,
        );

        final snapshot = reanimationsfall.snapshot();
        expect(snapshot.phase, Reanimationsphase.druckphase);
        expect(
          snapshot.rhythmusanalyseEintraege.single.ergebnis,
          RhythmusanalyseErgebnis.unklar,
        );
      },
    );

    test(
      'completeRhythmusanalyse rejects a shock for a non-shockable result',
      () {
        final clock = FakeClock();
        final reanimationsfall = Reanimationsfall.start(clock: clock);
        reanimationsfall.enterAnalysephase();

        expect(
          () => reanimationsfall.completeRhythmusanalyse(
            RhythmusanalyseErgebnis.asystolie,
            schockAbgegeben: true,
          ),
          throwsArgumentError,
        );
        expect(
          reanimationsfall.snapshot().phase,
          Reanimationsphase.analysephase,
        );
        expect(reanimationsfall.snapshot().rhythmusanalyseEintraege, isEmpty);
      },
    );

    test('completeRhythmusanalyse rejects a shock for Unklar', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.enterAnalysephase();

      expect(
        () => reanimationsfall.completeRhythmusanalyse(
          RhythmusanalyseErgebnis.unklar,
          schockAbgegeben: true,
        ),
        throwsArgumentError,
      );
    });

    test('completeRhythmusanalyse requires the Analysephase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      expect(
        () => reanimationsfall.completeRhythmusanalyse(
          RhythmusanalyseErgebnis.kammerflimmern,
        ),
        throwsStateError,
      );
    });

    test('completeRhythmusanalyse rejects a second result in the same '
        'Analysephase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.enterAnalysephase();
      reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.kammerflimmern,
      );

      expect(
        () => reanimationsfall.completeRhythmusanalyse(
          RhythmusanalyseErgebnis.asystolie,
        ),
        throwsStateError,
      );
      expect(
        reanimationsfall.snapshot().rhythmusanalyseEintraege,
        hasLength(1),
      );
    });

    test('skipping records the skip without a reason and starts a fresh '
        'two-minute Druckphase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(minutes: 2, seconds: 15));
      reanimationsfall.enterAnalysephase();
      clock.advance(const Duration(seconds: 8));
      reanimationsfall.skipRhythmusanalyse();

      final skipped = reanimationsfall.snapshot();
      expect(skipped.phase, Reanimationsphase.druckphase);
      expect(skipped.compressionRemaining, const Duration(minutes: 2));
      final skip = skipped.letzteRhythmusanalyseUeberspringung;
      expect(skip, isNotNull);
      expect(skip!.zeitpunkt, const Duration(minutes: 2, seconds: 23));
      expect(skipped.pauseDuration, Duration.zero);
    });

    test('keeps every skipped Rhythmusanalyse', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.enterAnalysephase();
      reanimationsfall.skipRhythmusanalyse();
      clock.advance(const Duration(minutes: 2));
      reanimationsfall.enterAnalysephase();
      reanimationsfall.skipRhythmusanalyse();

      final skipped = reanimationsfall.snapshot();
      expect(skipped.uebersprungeneRhythmusanalysen, hasLength(2));
    });

    test('skipping requires the Analysephase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      expect(reanimationsfall.skipRhythmusanalyse, throwsStateError);
    });

    test('recovers suspended time while the Analysephase is paused', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.enterAnalysephase();

      clock.advanceWallClockOnly(const Duration(seconds: 12));
      reanimationsfall.reconcileWithWallClock();

      final paused = reanimationsfall.snapshot();
      expect(paused.phase, Reanimationsphase.analysephase);
      expect(paused.pauseDuration, const Duration(seconds: 12));
      expect(paused.isPauseOverdue, isTrue);
      expect(paused.compressionRemaining, const Duration(minutes: 2));
    });
  });

  group('Schock', () {
    test('a manual Schock in the Druckphase records the event without pausing '
        'the compression timer', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 30));
      reanimationsfall.recordSchock();

      final running = reanimationsfall.snapshot();
      expect(running.phase, Reanimationsphase.druckphase);
      expect(running.schockAnzahl, 1);
      expect(running.schocks.single.zeitpunkt, const Duration(seconds: 30));
      expect(running.schocks.single.energieJoule, isNull);
      expect(running.compressionRemaining, const Duration(seconds: 90));

      clock.advance(const Duration(seconds: 10));
      expect(
        reanimationsfall.snapshot().compressionRemaining,
        const Duration(seconds: 80),
      );
      expect(reanimationsfall.snapshot().isRhythmusanalyseDue, isFalse);
    });

    test('a manual Schock after the due time keeps the overdue analysis', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(minutes: 2, seconds: 5));
      reanimationsfall.recordSchock();

      final running = reanimationsfall.snapshot();
      expect(running.isRhythmusanalyseDue, isTrue);
      expect(running.rhythmusanalyseOverdue, const Duration(seconds: 5));
      expect(running.compressionRemaining, Duration.zero);

      clock.advance(const Duration(seconds: 10));
      expect(
        reanimationsfall.snapshot().rhythmusanalyseOverdue,
        const Duration(seconds: 15),
      );
    });

    test(
      'a manual Schock in the Analysephase keeps the result requirement',
      () {
        final clock = FakeClock();
        final reanimationsfall = Reanimationsfall.start(clock: clock);

        clock.advance(const Duration(seconds: 45));
        reanimationsfall.enterAnalysephase();
        clock.advance(const Duration(seconds: 5));
        reanimationsfall.recordSchock();

        final recorded = reanimationsfall.snapshot();
        expect(recorded.phase, Reanimationsphase.analysephase);
        expect(recorded.schockAnzahl, 1);
        expect(recorded.pauseDuration, const Duration(seconds: 5));
        expect(recorded.rhythmusanalyseEintraege, isEmpty);

        reanimationsfall.completeRhythmusanalyse(
          RhythmusanalyseErgebnis.kammerflimmern,
        );
        expect(reanimationsfall.snapshot().phase, Reanimationsphase.druckphase);
      },
    );

    test('records an optional energy on the Schock event', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.recordSchock(energieJoule: 200);

      expect(reanimationsfall.snapshot().schocks.single.energieJoule, 200);
      expect(
        () => reanimationsfall.recordSchock(energieJoule: 0),
        throwsArgumentError,
      );
    });

    test('rejects a Schock after ROSC', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.recordRosc();

      expect(reanimationsfall.recordSchock, throwsStateError);
    });
  });

  group('DruckphaseNeustart', () {
    test('resets only the compression cycle and records an event', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.recordAdrenalin();
      reanimationsfall.recordSchock();
      reanimationsfall.recordSchock();
      reanimationsfall.recordSchock();
      clock.advance(const Duration(seconds: 90));
      reanimationsfall.restartDruckphase();

      final restarted = reanimationsfall.snapshot();
      expect(restarted.phase, Reanimationsphase.druckphase);
      expect(restarted.kannDruckphaseNeuStarten, isTrue);
      expect(restarted.compressionRemaining, const Duration(minutes: 2));
      expect(restarted.druckphaseNeustarts, hasLength(1));
      expect(
        restarted.druckphaseNeustarts.single.zeitpunkt,
        const Duration(seconds: 90),
      );
      expect(restarted.cprDauer, const Duration(seconds: 90));
      expect(restarted.adrenalinSeitLetzterGabe, const Duration(seconds: 90));
      expect(
        restarted.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.wartet,
      );
      expect(restarted.amiodaronHinweis, AmiodaronHinweis.ersteGabe);

      clock.advance(const Duration(seconds: 10));
      expect(
        reanimationsfall.snapshot().compressionRemaining,
        const Duration(minutes: 1, seconds: 50),
      );
    });

    test('requires the Druckphase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      expect(reanimationsfall.snapshot().kannDruckphaseNeuStarten, isTrue);

      reanimationsfall.enterAnalysephase();
      expect(reanimationsfall.snapshot().kannDruckphaseNeuStarten, isFalse);
      expect(reanimationsfall.restartDruckphase, throwsStateError);
    });

    test('requires the running case', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.recordRosc();

      expect(reanimationsfall.snapshot().kannDruckphaseNeuStarten, isFalse);
      expect(reanimationsfall.restartDruckphase, throwsStateError);
    });
  });

  group('Adrenalin', () {
    test('recording a dose starts and restarts the 3-5 minute window', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordAdrenalin();

      var snapshot = reanimationsfall.snapshot();
      expect(snapshot.adrenalinGaben, hasLength(1));
      expect(
        snapshot.adrenalinGaben.single.zeitpunkt,
        const Duration(seconds: 10),
      );
      expect(snapshot.adrenalinGaben.single.dosisMg, 1);
      expect(snapshot.letzteAdrenalinGabe, isNotNull);
      expect(snapshot.adrenalinSeitLetzterGabe, Duration.zero);
      expect(
        snapshot.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.wartet,
      );

      clock.advance(const Duration(minutes: 2, seconds: 59));
      expect(
        reanimationsfall.snapshot().adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.wartet,
      );

      clock.advance(const Duration(seconds: 1));
      snapshot = reanimationsfall.snapshot();
      expect(snapshot.adrenalinSeitLetzterGabe, const Duration(minutes: 3));
      expect(
        snapshot.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.faellig,
      );

      clock.advance(const Duration(minutes: 2));
      expect(
        reanimationsfall.snapshot().adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.faellig,
      );

      clock.advance(const Duration(seconds: 1));
      expect(
        reanimationsfall.snapshot().adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.ueberfaellig,
      );

      reanimationsfall.recordAdrenalin();
      snapshot = reanimationsfall.snapshot();
      expect(snapshot.adrenalinGaben, hasLength(2));
      expect(
        snapshot.letzteAdrenalinGabe!.zeitpunkt,
        const Duration(minutes: 5, seconds: 11),
      );
      expect(snapshot.adrenalinSeitLetzterGabe, Duration.zero);
      expect(
        snapshot.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.wartet,
      );
    });

    test('the Zeitfenster continues during the Analysephase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.recordAdrenalin();
      clock.advance(const Duration(minutes: 1));
      reanimationsfall.enterAnalysephase();
      clock.advance(const Duration(minutes: 2));

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.pauseDuration, const Duration(minutes: 2));
      expect(snapshot.adrenalinSeitLetzterGabe, const Duration(minutes: 3));
      expect(
        snapshot.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.faellig,
      );
    });

    test(
      'a shockable result makes Adrenalin due at the profile shock count',
      () {
        for (final (profil, threshold) in [
          (Leitlinienprofil.aha2025, 2),
          (Leitlinienprofil.erc2025, 3),
        ]) {
          final clock = FakeClock();
          final reanimationsfall = Reanimationsfall.start(
            clock: clock,
            leitlinienprofil: profil,
          );

          reanimationsfall.enterAnalysephase();
          reanimationsfall.completeRhythmusanalyse(
            RhythmusanalyseErgebnis.kammerflimmern,
          );

          for (var schock = 1; schock < threshold; schock++) {
            reanimationsfall.recordSchock();
            expect(
              reanimationsfall.snapshot().istErsteAdrenalinGabeFaellig,
              isFalse,
              reason: '$profil after $schock Schocks',
            );
          }

          reanimationsfall.recordSchock();
          final snapshot = reanimationsfall.snapshot();
          expect(
            snapshot.istErsteAdrenalinGabeFaellig,
            isTrue,
            reason: '$profil at $threshold Schocks',
          );
          expect(snapshot.adrenalinGaben, isEmpty);
        }
      },
    );
  });

  group('Amiodaron', () {
    test('does not suggest Amiodaron before the third Schock', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      expect(
        reanimationsfall.snapshot().amiodaronHinweis,
        AmiodaronHinweis.keine,
      );

      reanimationsfall.recordSchock();
      reanimationsfall.recordSchock();

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.schockAnzahl, 2);
      expect(snapshot.amiodaronHinweis, AmiodaronHinweis.keine);
      expect(snapshot.amiodaronGaben, isEmpty);
    });

    test('suggests the first 300 mg dose after the third Schock', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.recordSchock();
      reanimationsfall.recordSchock();
      reanimationsfall.recordSchock();

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.amiodaronHinweis, AmiodaronHinweis.ersteGabe);
      expect(snapshot.amiodaronHinweis.dosisMg, 300);
      expect(snapshot.amiodaronGaben, isEmpty);
      expect(snapshot.letzteAmiodaronGabe, isNull);
    });

    test('records the first 300 mg dose and suppresses the hint until the '
        'second trigger', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      for (var i = 0; i < 3; i++) {
        reanimationsfall.recordSchock();
      }
      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordAmiodaron();

      final afterFirstDose = reanimationsfall.snapshot();
      expect(afterFirstDose.amiodaronGaben, hasLength(1));
      expect(afterFirstDose.amiodaronGaben.single.dosisMg, 300);
      expect(
        afterFirstDose.amiodaronGaben.single.zeitpunkt,
        const Duration(seconds: 10),
      );
      expect(afterFirstDose.letzteAmiodaronGabe!.dosisMg, 300);
      expect(afterFirstDose.amiodaronHinweis, AmiodaronHinweis.keine);

      reanimationsfall.recordSchock();
      reanimationsfall.recordSchock();

      final secondHint = reanimationsfall.snapshot();
      expect(secondHint.schockAnzahl, 5);
      expect(secondHint.amiodaronHinweis, AmiodaronHinweis.zweiteGabe);
      expect(secondHint.amiodaronHinweis.dosisMg, 150);

      clock.advance(const Duration(minutes: 1));
      reanimationsfall.recordAmiodaron();

      final afterSecondDose = reanimationsfall.snapshot();
      expect(afterSecondDose.amiodaronGaben, hasLength(2));
      expect(afterSecondDose.amiodaronGaben.last.dosisMg, 150);
      expect(
        afterSecondDose.amiodaronGaben.last.zeitpunkt,
        const Duration(minutes: 1, seconds: 10),
      );
      expect(afterSecondDose.amiodaronHinweis, AmiodaronHinweis.keine);
      expect(reanimationsfall.recordAmiodaron, throwsStateError);
    });

    test('the second Amiodaron trigger follows the Leitlinienprofil', () {
      for (final (profil, trigger) in [
        (Leitlinienprofil.aha2025, 4),
        (Leitlinienprofil.erc2025, 5),
      ]) {
        final clock = FakeClock();
        final reanimationsfall = Reanimationsfall.start(
          clock: clock,
          leitlinienprofil: profil,
        );

        for (var i = 0; i < 3; i++) {
          reanimationsfall.recordSchock();
        }
        reanimationsfall.recordAmiodaron();

        for (var schock = 4; schock < trigger; schock++) {
          reanimationsfall.recordSchock();
          expect(
            reanimationsfall.snapshot().amiodaronHinweis,
            AmiodaronHinweis.keine,
            reason: '$profil after $schock Schocks',
          );
        }

        reanimationsfall.recordSchock();
        expect(
          reanimationsfall.snapshot().amiodaronHinweis,
          AmiodaronHinweis.zweiteGabe,
          reason: '$profil at $trigger Schocks',
        );
      }
    });

    test('never suggests a second dose before the first one is recorded', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      for (var i = 0; i < 5; i++) {
        reanimationsfall.recordSchock();
      }

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.amiodaronHinweis, AmiodaronHinweis.ersteGabe);
      expect(snapshot.amiodaronHinweis.dosisMg, 300);
      expect(snapshot.amiodaronGaben, isEmpty);
    });
  });

  group('Rhythmusanalyse history', () {
    test('keeps the result history across cycles', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      reanimationsfall.enterAnalysephase();
      reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.kammerflimmern,
      );

      clock.advance(const Duration(minutes: 2));
      reanimationsfall.enterAnalysephase();
      reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.asystolie,
      );

      final snapshot = reanimationsfall.snapshot();
      final entries = snapshot.rhythmusanalyseEintraege;
      expect(entries, hasLength(2));
      expect(entries.first.ergebnis, RhythmusanalyseErgebnis.kammerflimmern);
      expect(entries.last.ergebnis, RhythmusanalyseErgebnis.asystolie);
    });
  });

  group('ROSC', () {
    test('records ROSC from the Analysephase and ends the segment', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 10));
      reanimationsfall.enterAnalysephase();
      clock.advance(const Duration(seconds: 5));
      reanimationsfall.completeRhythmusanalyse(RhythmusanalyseErgebnis.rosc);

      final rosc = reanimationsfall.snapshot();
      expect(rosc.zustand, ReanimationsfallZustand.rosc);
      expect(rosc.istRosc, isTrue);
      expect(rosc.abschnitte.single.ende, const Duration(seconds: 15));
      expect(
        rosc.rhythmusanalyseEintraege.single.ergebnis,
        RhythmusanalyseErgebnis.rosc,
      );
      expect(rosc.compressionRemaining, Duration.zero);
    });

    test('rejects a shock with ROSC', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.enterAnalysephase();

      expect(
        () => reanimationsfall.completeRhythmusanalyse(
          RhythmusanalyseErgebnis.rosc,
          schockAbgegeben: true,
        ),
        throwsArgumentError,
      );
      expect(reanimationsfall.snapshot().istLaufend, isTrue);
    });

    test('records ROSC directly and stops the arrest timers', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.recordAdrenalin();

      clock.advance(const Duration(seconds: 60));
      reanimationsfall.recordRosc();

      final rosc = reanimationsfall.snapshot();
      expect(rosc.zustand, ReanimationsfallZustand.rosc);
      expect(rosc.abschnitte.single.ende, const Duration(seconds: 60));
      expect(rosc.cprDauer, const Duration(seconds: 60));
      expect(rosc.roscEreignisse.single.zeitpunkt, const Duration(seconds: 60));
      expect(rosc.isRhythmusanalyseDue, isFalse);
      expect(rosc.isPauseOverdue, isFalse);
      expect(rosc.amiodaronHinweis, AmiodaronHinweis.keine);

      expect(reanimationsfall.recordSchock, throwsStateError);
      expect(reanimationsfall.enterAnalysephase, throwsStateError);
      expect(reanimationsfall.recordAdrenalin, throwsStateError);
      expect(reanimationsfall.recordRosc, throwsStateError);

      clock.advance(const Duration(minutes: 1));
      final later = reanimationsfall.snapshot();
      expect(later.reanimationsdauer, const Duration(minutes: 2));
      expect(later.cprDauer, const Duration(seconds: 60));
      expect(later.adrenalinSeitLetzterGabe, const Duration(minutes: 2));
      expect(later.letzteAdrenalinGabe, isNotNull);
    });

    test('a Reanimationswiederbeginn starts a new segment and a fresh '
        'Druckphase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 60));
      reanimationsfall.recordRosc();
      clock.advance(const Duration(seconds: 30));
      reanimationsfall.resumeResuscitation();

      final resumed = reanimationsfall.snapshot();
      expect(resumed.zustand, ReanimationsfallZustand.laufend);
      expect(resumed.phase, Reanimationsphase.druckphase);
      expect(resumed.compressionRemaining, const Duration(minutes: 2));
      expect(resumed.cprDauer, const Duration(seconds: 60));
      expect(resumed.abschnitte, hasLength(2));
      expect(resumed.abschnitte.last.start, const Duration(seconds: 90));
      expect(resumed.abschnitte.last.ende, isNull);
      expect(
        resumed.wiederbeginnEreignisse.single.zeitpunkt,
        const Duration(seconds: 90),
      );

      clock.advance(const Duration(seconds: 10));
      final running = reanimationsfall.snapshot();
      expect(running.cprDauer, const Duration(seconds: 70));
      expect(running.compressionRemaining, const Duration(seconds: 110));
      expect(reanimationsfall.resumeResuscitation, throwsStateError);
    });
  });

  group('Case lifecycle', () {
    test('ends the Reanimationsfall with a reason and freezes the timers', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 60));
      reanimationsfall.recordRosc();
      clock.advance(const Duration(seconds: 30));
      reanimationsfall.endReanimationsfall(Beendigungsgrund.uebergabe);

      final ended = reanimationsfall.snapshot();
      expect(ended.zustand, ReanimationsfallZustand.beendet);
      expect(ended.istBeendet, isTrue);
      expect(ended.ende!.grund, Beendigungsgrund.uebergabe);
      expect(ended.ende!.zeitpunkt, const Duration(seconds: 90));
      expect(ended.reanimationsdauer, const Duration(seconds: 90));
      expect(ended.cprDauer, const Duration(seconds: 60));
      expect(ended.abschnitte.single.ende, const Duration(seconds: 60));

      expect(reanimationsfall.recordSchock, throwsStateError);
      expect(reanimationsfall.resumeResuscitation, throwsStateError);
      expect(
        () => reanimationsfall.endReanimationsfall(Beendigungsgrund.abbruch),
        throwsStateError,
      );
    });

    test('ends the Reanimationsfall from the running Druckphase', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 30));
      reanimationsfall.endReanimationsfall(Beendigungsgrund.abbruch);

      final ended = reanimationsfall.snapshot();
      expect(ended.ende!.grund, Beendigungsgrund.abbruch);
      expect(ended.abschnitte.single.ende, const Duration(seconds: 30));
      expect(ended.cprDauer, const Duration(seconds: 30));
    });

    test('marks a case as Verworfen and keeps it open for documentation', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 30));
      reanimationsfall.recordSchock();
      reanimationsfall.discardReanimationsfall();

      final discarded = reanimationsfall.snapshot();
      expect(discarded.istVerworfen, isTrue);
      expect(discarded.verworfenAm, const Duration(seconds: 30));
      expect(discarded.schockAnzahl, 1);
      expect(() => reanimationsfall.recordSchock(), throwsStateError);
    });
  });

  group('Messwerte', () {
    test('records all four Messwerte with timestamps and notes', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 10));
      reanimationsfall.recordTemperatur(36.5, notiz: '  rektal  ');
      clock.advance(const Duration(seconds: 5));
      reanimationsfall.recordBlutzucker(120);
      clock.advance(const Duration(seconds: 5));
      reanimationsfall.recordBlutdruck(
        systolisch: 120,
        diastolisch: 80,
        notiz: 'links',
      );
      clock.advance(const Duration(seconds: 5));
      reanimationsfall.recordHerzfrequenz(88);
      clock.advance(const Duration(seconds: 5));
      reanimationsfall.recordNotiz('  Patient kalt  ');

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.messwerte, hasLength(4));

      final temperatur = snapshot.messwerte[0] as TemperaturMesswert;
      expect(temperatur.celsius, 36.5);
      expect(temperatur.zeitpunkt, const Duration(seconds: 10));
      expect(temperatur.notiz, 'rektal');

      final blutzucker = snapshot.messwerte[1] as BlutzuckerMesswert;
      expect(blutzucker.mgDl, 120);
      expect(blutzucker.zeitpunkt, const Duration(seconds: 15));
      expect(blutzucker.notiz, isNull);

      final blutdruck = snapshot.messwerte[2] as BlutdruckMesswert;
      expect(blutdruck.systolisch, 120);
      expect(blutdruck.diastolisch, 80);
      expect(blutdruck.zeitpunkt, const Duration(seconds: 20));
      expect(blutdruck.notiz, 'links');

      final herzfrequenz = snapshot.messwerte[3] as HerzfrequenzMesswert;
      expect(herzfrequenz.proMinute, 88);
      expect(herzfrequenz.zeitpunkt, const Duration(seconds: 25));

      expect(snapshot.notizen.single.text, 'Patient kalt');
      expect(snapshot.notizen.single.zeitpunkt, const Duration(seconds: 30));
    });

    test('rejects invalid Messwerte and empty notes', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      expect(() => reanimationsfall.recordTemperatur(0), throwsArgumentError);
      expect(() => reanimationsfall.recordBlutzucker(0), throwsArgumentError);
      expect(
        () =>
            reanimationsfall.recordBlutdruck(systolisch: 80, diastolisch: 120),
        throwsArgumentError,
      );
      expect(
        () => reanimationsfall.recordHerzfrequenz(-1),
        throwsArgumentError,
      );
      expect(() => reanimationsfall.recordNotiz('   '), throwsArgumentError);

      expect(reanimationsfall.snapshot().messwerte, isEmpty);
      expect(reanimationsfall.snapshot().notizen, isEmpty);
    });

    test('records Messwerte during ROSC but not after the case is closed', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      clock.advance(const Duration(seconds: 30));
      reanimationsfall.recordRosc();

      reanimationsfall.recordTemperatur(37.2);
      reanimationsfall.recordNotiz('Nach ROSC');

      expect(reanimationsfall.snapshot().messwerte, hasLength(1));
      expect(reanimationsfall.snapshot().notizen, hasLength(1));

      reanimationsfall.endReanimationsfall(Beendigungsgrund.uebergabe);

      expect(() => reanimationsfall.recordBlutzucker(100), throwsStateError);
      expect(() => reanimationsfall.recordNotiz('zu spät'), throwsStateError);
      expect(reanimationsfall.snapshot().messwerte, hasLength(1));
    });
  });

  group('Timing', () {
    test('keeps the Reanimationsdauer accurate when the wall clock jumps', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 45));
      clock.advanceWallClockOnly(const Duration(hours: 1));

      expect(
        reanimationsfall.snapshot().reanimationsdauer,
        const Duration(seconds: 45),
      );
      expect(
        reanimationsfall.snapshot().compressionRemaining,
        const Duration(seconds: 75),
      );
    });

    test('recovers suspended time when the monotonic clock stopped', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advanceWallClockOnly(const Duration(minutes: 3));
      reanimationsfall.reconcileWithWallClock();

      final snapshot = reanimationsfall.snapshot();
      expect(snapshot.reanimationsdauer, const Duration(minutes: 3));
      expect(snapshot.isRhythmusanalyseDue, isTrue);
      expect(snapshot.rhythmusanalyseOverdue, const Duration(minutes: 1));
    });

    test('never shortens the Reanimationsdauer when the wall clock jumps '
        'backwards', () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 45));
      clock.advanceWallClockOnly(const Duration(hours: -1));
      reanimationsfall.reconcileWithWallClock();

      expect(
        reanimationsfall.snapshot().reanimationsdauer,
        const Duration(seconds: 45),
      );
    });
  });
}
