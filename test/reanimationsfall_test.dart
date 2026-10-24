import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
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
