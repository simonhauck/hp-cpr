import 'package:flutter_test/flutter_test.dart';

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
}
