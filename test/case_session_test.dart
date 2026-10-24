import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/case_session/domain/case_session.dart';
import 'package:hp_cpr/features/guideline/domain/guideline_profile.dart';

import 'support/fake_clock.dart';

void main() {
  test('starts the Druckphase at two minutes with the first compression as '
      'Startzeit', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8, 30));
    final session = CaseSession.start(clock: clock);

    final view = session.snapshot();

    expect(view.startzeit, DateTime(2026, 10, 25, 8, 30));
    expect(view.elapsed, Duration.zero);
    expect(view.phase, CasePhase.druckphase);
    expect(view.compressionRemaining, const Duration(minutes: 2));
    expect(view.isAnalysisDue, isFalse);
    expect(view.profile, GuidelineProfile.erc2025);
  });

  test('counts the compression cycle down while the Druckphase runs', () {
    final clock = FakeClock();
    final session = CaseSession.start(clock: clock);

    clock.advance(const Duration(seconds: 30));

    final view = session.snapshot();
    expect(view.elapsed, const Duration(seconds: 30));
    expect(view.compressionRemaining, const Duration(seconds: 90));
    expect(view.isAnalysisDue, isFalse);
  });

  test(
    'makes the Rhythmusanalyse due at 0:00 and counts the overdue time up',
    () {
      final clock = FakeClock();
      final session = CaseSession.start(clock: clock);

      clock.advance(const Duration(minutes: 2));
      final due = session.snapshot();

      expect(due.isAnalysisDue, isTrue);
      expect(due.phase, CasePhase.druckphase);
      expect(due.compressionRemaining, Duration.zero);
      expect(due.analysisOverdue, Duration.zero);

      clock.advance(const Duration(seconds: 5));
      final overdue = session.snapshot();

      expect(overdue.isAnalysisDue, isTrue);
      expect(overdue.elapsed, const Duration(minutes: 2, seconds: 5));
      expect(overdue.analysisOverdue, const Duration(seconds: 5));
    },
  );

  test('backdates the Startzeit and starts the Druckphase at the matching '
      'elapsed offset', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8, 30));
    final session = CaseSession.start(
      clock: clock,
      backdate: const Duration(minutes: 1),
    );

    final view = session.snapshot();

    expect(view.startzeit, DateTime(2026, 10, 25, 8, 29));
    expect(view.elapsed, const Duration(minutes: 1));
    expect(view.compressionRemaining, const Duration(minutes: 1));
    expect(view.isAnalysisDue, isFalse);
  });

  test('starts a long-running case already due for the Rhythmusanalyse', () {
    final clock = FakeClock(wallTime: DateTime(2026, 10, 25, 8, 30));
    final session = CaseSession.start(
      clock: clock,
      backdate: const Duration(minutes: 5),
    );

    final view = session.snapshot();

    expect(view.startzeit, DateTime(2026, 10, 25, 8, 25));
    expect(view.elapsed, const Duration(minutes: 5));
    expect(view.isAnalysisDue, isTrue);
    expect(view.analysisOverdue, const Duration(minutes: 3));
  });

  test('keeps elapsed time accurate when the wall clock jumps', () {
    final clock = FakeClock();
    final session = CaseSession.start(clock: clock);

    clock.advance(const Duration(seconds: 45));
    clock.advanceWallClockOnly(const Duration(hours: 1));

    expect(session.snapshot().elapsed, const Duration(seconds: 45));
    expect(
      session.snapshot().compressionRemaining,
      const Duration(seconds: 75),
    );
  });

  test('recovers suspended time when the monotonic clock stopped', () {
    final clock = FakeClock();
    final session = CaseSession.start(clock: clock);

    clock.advanceWallClockOnly(const Duration(minutes: 3));
    session.reconcileWithWallClock();

    final view = session.snapshot();
    expect(view.elapsed, const Duration(minutes: 3));
    expect(view.isAnalysisDue, isTrue);
    expect(view.analysisOverdue, const Duration(minutes: 1));
  });

  test('never shortens elapsed time when the wall clock jumps backwards', () {
    final clock = FakeClock();
    final session = CaseSession.start(clock: clock);

    clock.advance(const Duration(seconds: 45));
    clock.advanceWallClockOnly(const Duration(hours: -1));
    session.reconcileWithWallClock();

    expect(session.snapshot().elapsed, const Duration(seconds: 45));
  });

  test('rejects a negative backdate', () {
    final clock = FakeClock();

    expect(
      () => CaseSession.start(
        clock: clock,
        backdate: const Duration(seconds: -1),
      ),
      throwsArgumentError,
    );
  });
}
