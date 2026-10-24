import 'package:hp_cpr/core/clock.dart';

/// A controllable clock for tests.
///
/// Wall-clock and monotonic time advance independently so tests can model a
/// device clock jump without changing the elapsed time of a case.
class FakeClock implements AppClock {
  FakeClock({DateTime? wallTime})
    : _wallTime = wallTime ?? DateTime(2026, 10, 25, 8);

  DateTime _wallTime;
  Duration _monotonic = Duration.zero;

  @override
  DateTime now() => _wallTime;

  @override
  Duration monotonicNow() => _monotonic;

  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'must not be negative');
    }
    _wallTime = _wallTime.add(duration);
    _monotonic += duration;
  }

  void advanceWallClockOnly(Duration duration) {
    _wallTime = _wallTime.add(duration);
  }
}
