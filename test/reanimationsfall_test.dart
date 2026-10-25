import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';

import 'support/fake_clock.dart';

void main() {
  test('starts the Druckphase at two minutes with the first compression as '
      'Startzeit', () {
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
    'makes the Rhythmusanalyse due at 0:00 and counts the overdue time up',
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
      expect(overdue.reanimationsdauer, const Duration(minutes: 2, seconds: 5));
      expect(overdue.rhythmusanalyseOverdue, const Duration(seconds: 5));
    },
  );

  test('entering the Analysephase pauses the compression timer and starts the '
      'pause counter', () {
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

  test(
    'uses the Leitlinienprofil-specific pause target for the overdue hint',
    () {
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
    },
  );

  test('records a two-step Rhythmusanalyse result with an optional note', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();

    reanimationsfall.recordRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
      notiz: '  VF seit drei Minuten  ',
    );

    final recorded = reanimationsfall.snapshot();
    expect(
      recorded.rhythmusanalyseErgebnis,
      RhythmusanalyseErgebnis.kammerflimmern,
    );
    expect(recorded.rhythmusanalyseNotiz, 'VF seit drei Minuten');

    reanimationsfall.setRhythmusanalyseNotiz('   ');
    expect(reanimationsfall.snapshot().rhythmusanalyseNotiz, isNull);
  });

  test('rejects a second result in the same Analysephase', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();
    reanimationsfall.recordRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
    );

    expect(
      () => reanimationsfall.recordRhythmusanalyse(
        RhythmusanalyseErgebnis.asystolie,
      ),
      throwsStateError,
    );
    expect(
      reanimationsfall.snapshot().rhythmusanalyseErgebnis,
      RhythmusanalyseErgebnis.kammerflimmern,
    );
  });

  test('requires a result or explicit Unklar before CPR continues', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();

    expect(reanimationsfall.continueCpr, throwsStateError);

    reanimationsfall.recordRhythmusanalyse(RhythmusanalyseErgebnis.unklar);
    reanimationsfall.continueCpr();

    expect(reanimationsfall.snapshot().phase, Reanimationsphase.druckphase);
    expect(
      reanimationsfall.snapshot().rhythmusanalyseErgebnis,
      RhythmusanalyseErgebnis.unklar,
    );
  });

  test('continuing CPR starts a fresh two-minute Druckphase', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(seconds: 30));
    reanimationsfall.enterAnalysephase();
    clock.advance(const Duration(seconds: 20));
    reanimationsfall.recordRhythmusanalyse(
      RhythmusanalyseErgebnis.pulsloseKammertachykardie,
    );
    reanimationsfall.continueCpr();

    final fresh = reanimationsfall.snapshot();
    expect(fresh.phase, Reanimationsphase.druckphase);
    expect(fresh.compressionRemaining, const Duration(minutes: 2));
    expect(fresh.pauseDuration, Duration.zero);

    clock.advance(const Duration(seconds: 10));
    expect(
      reanimationsfall.snapshot().compressionRemaining,
      const Duration(minutes: 1, seconds: 50),
    );
  });

  test('skipping the Rhythmusanalyse records the reason and starts a fresh '
      'two-minute Druckphase', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(minutes: 2, seconds: 15));
    reanimationsfall.enterAnalysephase();
    clock.advance(const Duration(seconds: 8));
    reanimationsfall.skipRhythmusanalyse(
      RhythmusanalyseUebersprungenGrund.keineZeit,
    );

    final skipped = reanimationsfall.snapshot();
    expect(skipped.phase, Reanimationsphase.druckphase);
    expect(skipped.compressionRemaining, const Duration(minutes: 2));
    final skip = skipped.letzteRhythmusanalyseUeberspringung;
    expect(skip, isNotNull);
    expect(skip!.grund, RhythmusanalyseUebersprungenGrund.keineZeit);
    expect(skip.zeitpunkt, const Duration(minutes: 2, seconds: 23));
    expect(skipped.pauseDuration, Duration.zero);
  });

  test('skipping without a reason is still recorded', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);
    reanimationsfall.enterAnalysephase();

    reanimationsfall.skipRhythmusanalyse();

    final skipped = reanimationsfall.snapshot();
    expect(skipped.phase, Reanimationsphase.druckphase);
    expect(skipped.uebersprungeneRhythmusanalysen, hasLength(1));
    final skip = skipped.letzteRhythmusanalyseUeberspringung;
    expect(skip, isNotNull);
    expect(skip!.grund, isNull);
    expect(skip.zeitpunkt, Duration.zero);
  });

  test('keeps every skipped Rhythmusanalyse', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    reanimationsfall.enterAnalysephase();
    reanimationsfall.skipRhythmusanalyse(
      RhythmusanalyseUebersprungenGrund.keineZeit,
    );
    clock.advance(const Duration(minutes: 2));
    reanimationsfall.enterAnalysephase();
    reanimationsfall.skipRhythmusanalyse(
      RhythmusanalyseUebersprungenGrund.sonstiges,
    );

    final skipped = reanimationsfall.snapshot();
    expect(skipped.uebersprungeneRhythmusanalysen, hasLength(2));
    expect(
      skipped.uebersprungeneRhythmusanalysen.first.grund,
      RhythmusanalyseUebersprungenGrund.keineZeit,
    );
    expect(
      skipped.uebersprungeneRhythmusanalysen.last.grund,
      RhythmusanalyseUebersprungenGrund.sonstiges,
    );
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

  test('backdates the Startzeit and starts the Druckphase at the matching '
      'elapsed offset', () {
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

  test('starts a long-running Reanimationsfall already due for the Rhythmusanalyse', () {
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

  test(
    'never shortens the Reanimationsdauer when the wall clock jumps backwards',
    () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 45));
      clock.advanceWallClockOnly(const Duration(hours: -1));
      reanimationsfall.reconcileWithWallClock();

      expect(
        reanimationsfall.snapshot().reanimationsdauer,
        const Duration(seconds: 45),
      );
    },
  );

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

  test(
    'records a Schock in the Druckphase and pauses the compression timer',
    () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);

      clock.advance(const Duration(seconds: 30));
      reanimationsfall.recordSchock();

      final paused = reanimationsfall.snapshot();
      expect(paused.isSchockpause, isTrue);
      expect(paused.phase, Reanimationsphase.druckphase);
      expect(paused.compressionRemaining, const Duration(seconds: 90));
      expect(paused.schockAnzahl, 1);
      expect(paused.schocks, hasLength(1));
      expect(paused.schocks.single.zeitpunkt, const Duration(seconds: 30));
      expect(paused.schocks.single.energieJoule, isNull);

      clock.advance(const Duration(seconds: 10));
      final frozen = reanimationsfall.snapshot();
      expect(frozen.compressionRemaining, const Duration(seconds: 90));
      expect(frozen.isRhythmusanalyseDue, isFalse);
    },
  );

  test('entering the Analysephase from a Schockpause keeps the frozen '
      'compression timer', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(seconds: 30));
    reanimationsfall.recordSchock();
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.enterAnalysephase();

    final entered = reanimationsfall.snapshot();
    expect(entered.phase, Reanimationsphase.analysephase);
    expect(entered.isSchockpause, isFalse);
    expect(entered.compressionRemaining, const Duration(seconds: 90));
    expect(entered.pauseDuration, Duration.zero);

    clock.advance(const Duration(seconds: 5));
    final paused = reanimationsfall.snapshot();
    expect(paused.pauseDuration, const Duration(seconds: 5));
    expect(paused.compressionRemaining, const Duration(seconds: 90));
  });

  test('continuing CPR after a Schock starts a fresh Druckphase', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    reanimationsfall.recordSchock();
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.continueCpr();

    final fresh = reanimationsfall.snapshot();
    expect(fresh.phase, Reanimationsphase.druckphase);
    expect(fresh.isSchockpause, isFalse);
    expect(fresh.compressionRemaining, const Duration(minutes: 2));

    clock.advance(const Duration(seconds: 10));
    expect(
      reanimationsfall.snapshot().compressionRemaining,
      const Duration(minutes: 1, seconds: 50),
    );
  });

  test('records a Schock in the Analysephase and keeps the result '
      'requirement', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(seconds: 45));
    reanimationsfall.enterAnalysephase();
    clock.advance(const Duration(seconds: 5));
    reanimationsfall.recordSchock(energieJoule: 200);

    final recorded = reanimationsfall.snapshot();
    expect(recorded.phase, Reanimationsphase.analysephase);
    expect(recorded.isSchockpause, isFalse);
    expect(recorded.schockAnzahl, 1);
    expect(recorded.schocks.single.energieJoule, 200);
    expect(recorded.pauseDuration, const Duration(seconds: 5));
    expect(reanimationsfall.continueCpr, throwsStateError);

    reanimationsfall.recordRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
    );
    reanimationsfall.continueCpr();
    expect(reanimationsfall.snapshot().phase, Reanimationsphase.druckphase);
  });

  test('undo marks the last Schock undone and keeps the original event', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    reanimationsfall.recordSchock();
    reanimationsfall.recordSchock();
    reanimationsfall.undoLastSchock();

    final afterUndo = reanimationsfall.snapshot();
    expect(afterUndo.isSchockpause, isTrue);
    expect(afterUndo.schockAnzahl, 1);
    expect(afterUndo.schocks, hasLength(2));
    expect(afterUndo.schocks.first.rueckgaengig, isFalse);
    expect(afterUndo.schocks.last.rueckgaengig, isTrue);
    expect(afterUndo.schockRueckgaengigkeiten, hasLength(1));
    expect(afterUndo.schockRueckgaengigkeiten.single.schockIndex, 1);

    reanimationsfall.undoLastSchock();
    final resumed = reanimationsfall.snapshot();
    expect(resumed.schockAnzahl, 0);
    expect(resumed.isSchockpause, isFalse);
    expect(resumed.compressionRemaining, const Duration(minutes: 2));
    expect(resumed.schockRueckgaengigkeiten, hasLength(2));
    expect(reanimationsfall.undoLastSchock, throwsStateError);
  });

  test('undo resumes the cycle when the Schock that opened the pause is '
      'undone', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(seconds: 30));
    reanimationsfall.recordSchock();
    reanimationsfall.continueCpr();

    clock.advance(const Duration(seconds: 30));
    reanimationsfall.recordSchock();
    clock.advance(const Duration(seconds: 10));
    reanimationsfall.undoLastSchock();

    final resumed = reanimationsfall.snapshot();
    expect(resumed.schockAnzahl, 1);
    expect(resumed.isSchockpause, isFalse);
    expect(resumed.compressionRemaining, const Duration(seconds: 90));

    clock.advance(const Duration(seconds: 10));
    expect(
      reanimationsfall.snapshot().compressionRemaining,
      const Duration(seconds: 80),
    );
  });

  test('a Schock after the due time keeps the overdue Rhythmusanalyse while '
      'paused', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(minutes: 2, seconds: 5));
    reanimationsfall.recordSchock();

    final paused = reanimationsfall.snapshot();
    expect(paused.isSchockpause, isTrue);
    expect(paused.isRhythmusanalyseDue, isTrue);
    expect(paused.rhythmusanalyseOverdue, const Duration(seconds: 5));
    expect(paused.compressionRemaining, Duration.zero);

    clock.advance(const Duration(seconds: 10));
    expect(
      reanimationsfall.snapshot().rhythmusanalyseOverdue,
      const Duration(seconds: 5),
    );

    reanimationsfall.undoLastSchock();
    final resumed = reanimationsfall.snapshot();
    expect(resumed.isSchockpause, isFalse);
    expect(resumed.isRhythmusanalyseDue, isTrue);
    expect(resumed.rhythmusanalyseOverdue, const Duration(seconds: 5));

    clock.advance(const Duration(seconds: 1));
    expect(
      reanimationsfall.snapshot().rhythmusanalyseOverdue,
      const Duration(seconds: 6),
    );
  });

  test('Schock energy is optional and can be added later', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    reanimationsfall.recordSchock();
    expect(reanimationsfall.snapshot().schocks.single.energieJoule, isNull);

    reanimationsfall.setLastSchockEnergie(200);
    var snapshot = reanimationsfall.snapshot();
    expect(snapshot.schocks.single.energieJoule, 200);
    expect(snapshot.schocks.single.ereignis.energieJoule, isNull);
    expect(snapshot.schockKorrekturen, hasLength(1));
    expect(snapshot.schockKorrekturen.single.schockIndex, 0);
    expect(snapshot.schockKorrekturen.single.energieJoule, 200);

    reanimationsfall.setLastSchockEnergie(250);
    snapshot = reanimationsfall.snapshot();
    expect(snapshot.schocks.single.ereignis.energieJoule, isNull);
    expect(snapshot.schocks.single.energieJoule, 250);
    expect(snapshot.schockKorrekturen, hasLength(2));

    expect(() => reanimationsfall.setLastSchockEnergie(0), throwsArgumentError);
    expect(
      () => reanimationsfall.recordSchock(energieJoule: -1),
      throwsArgumentError,
    );
  });

  test('a non-shockable result makes the first Adrenalin dose due', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    reanimationsfall.enterAnalysephase();
    reanimationsfall.recordRhythmusanalyse(RhythmusanalyseErgebnis.asystolie);

    final snapshot = reanimationsfall.snapshot();
    expect(snapshot.istErsteAdrenalinGabeFaellig, isTrue);
    expect(
      snapshot.adrenalinZeitfensterZustand,
      AdrenalinZeitfensterZustand.keine,
    );
    expect(snapshot.adrenalinGaben, isEmpty);
    expect(snapshot.letzteAdrenalinGabe, isNull);

    reanimationsfall.continueCpr();
    expect(reanimationsfall.snapshot().istErsteAdrenalinGabeFaellig, isTrue);
  });

  test('a shockable result makes Adrenalin due at the Leitlinienprofil shock '
      'count', () {
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
      reanimationsfall.recordRhythmusanalyse(
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
  });

  test('undo clears the first Adrenalin hint when the shock threshold is no '
      'longer met', () {
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
      reanimationsfall.recordRhythmusanalyse(
        RhythmusanalyseErgebnis.kammerflimmern,
      );
      for (var schock = 0; schock < threshold; schock++) {
        reanimationsfall.recordSchock();
      }
      expect(reanimationsfall.snapshot().istErsteAdrenalinGabeFaellig, isTrue);

      reanimationsfall.undoLastSchock();
      final snapshot = reanimationsfall.snapshot();
      expect(
        snapshot.istErsteAdrenalinGabeFaellig,
        isFalse,
        reason: '$profil after undoing one of $threshold Schocks',
      );
      expect(snapshot.schockAnzahl, threshold - 1);
      expect(
        snapshot.adrenalinZeitfensterZustand,
        AdrenalinZeitfensterZustand.keine,
      );
    }
  });

  test('recording an Adrenalin dose starts and restarts the 3-5 minute '
      'window', () {
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

    clock.advance(const Duration(minutes: 3));
    expect(
      reanimationsfall.snapshot().adrenalinZeitfensterZustand,
      AdrenalinZeitfensterZustand.faellig,
    );
  });

  test('the Adrenalin Zeitfenster continues during the Analysephase', () {
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

  test('suggests the first 300 mg dose after the third Schock without '
      'recording it', () {
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

  test('records the first 300 mg dose and suppresses the hint until the second '
      'trigger', () {
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

  test('keeps the Rhythmusanalyse history and appends note corrections', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    reanimationsfall.enterAnalysephase();
    reanimationsfall.recordRhythmusanalyse(
      RhythmusanalyseErgebnis.kammerflimmern,
      notiz: 'VF',
    );
    reanimationsfall.setRhythmusanalyseNotiz('VF seit zwei Minuten');
    reanimationsfall.continueCpr();

    clock.advance(const Duration(minutes: 2));
    reanimationsfall.enterAnalysephase();
    reanimationsfall.recordRhythmusanalyse(RhythmusanalyseErgebnis.asystolie);

    final snapshot = reanimationsfall.snapshot();
    final entries = snapshot.rhythmusanalyseEintraege;
    expect(entries, hasLength(2));
    expect(entries.first.ergebnis, RhythmusanalyseErgebnis.kammerflimmern);
    expect(entries.first.notiz, 'VF');
    expect(entries.last.ergebnis, RhythmusanalyseErgebnis.asystolie);
    expect(entries.last.notiz, isNull);

    expect(snapshot.rhythmusanalyseNotizKorrekturen, hasLength(1));
    expect(snapshot.rhythmusanalyseNotizKorrekturen.single.eintragIndex, 0);
    expect(
      snapshot.rhythmusanalyseNotizKorrekturen.single.notiz,
      'VF seit zwei Minuten',
    );
  });

  test(
    'records ROSC, ends the Reanimationsabschnitt, and keeps the case open',
    () {
      final clock = FakeClock();
      final reanimationsfall = Reanimationsfall.start(clock: clock);
      reanimationsfall.recordAdrenalin();

      clock.advance(const Duration(seconds: 60));
      reanimationsfall.recordRosc();

      final rosc = reanimationsfall.snapshot();
      expect(rosc.zustand, ReanimationsfallZustand.rosc);
      expect(rosc.istRosc, isTrue);
      expect(rosc.istBeendet, isFalse);
      expect(rosc.abschnitte, hasLength(1));
      expect(rosc.abschnitte.single.ende, const Duration(seconds: 60));
      expect(rosc.cprDauer, const Duration(seconds: 60));
      expect(rosc.roscEreignisse.single.zeitpunkt, const Duration(seconds: 60));
      expect(rosc.ende, isNull);
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
    },
  );

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

  test('records ROSC from the Analysephase and keeps the result history', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    clock.advance(const Duration(seconds: 10));
    reanimationsfall.enterAnalysephase();
    clock.advance(const Duration(seconds: 5));
    reanimationsfall.recordRhythmusanalyse(RhythmusanalyseErgebnis.rosc);

    final rosc = reanimationsfall.snapshot();
    expect(rosc.zustand, ReanimationsfallZustand.rosc);
    expect(
      rosc.rhythmusanalyseEintraege.single.ergebnis,
      RhythmusanalyseErgebnis.rosc,
    );
    expect(rosc.abschnitte.single.ende, const Duration(seconds: 15));
    expect(reanimationsfall.continueCpr, throwsStateError);
  });

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
      () => reanimationsfall.recordBlutdruck(systolisch: 80, diastolisch: 120),
      throwsArgumentError,
    );
    expect(() => reanimationsfall.recordHerzfrequenz(-1), throwsArgumentError);
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

  test('undoing a Schock below the trigger removes the Amiodaron hint', () {
    final clock = FakeClock();
    final reanimationsfall = Reanimationsfall.start(clock: clock);

    for (var i = 0; i < 3; i++) {
      reanimationsfall.recordSchock();
    }
    expect(
      reanimationsfall.snapshot().amiodaronHinweis,
      AmiodaronHinweis.ersteGabe,
    );

    reanimationsfall.undoLastSchock();

    final snapshot = reanimationsfall.snapshot();
    expect(snapshot.schockAnzahl, 2);
    expect(snapshot.amiodaronHinweis, AmiodaronHinweis.keine);
    expect(snapshot.amiodaronGaben, isEmpty);
  });
}
