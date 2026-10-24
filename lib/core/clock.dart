/// Time sources for the app.
///
/// The Reanimationsdauer is derived from the monotonic source so that
/// wall-clock changes do not distort the timer.
abstract interface class AppClock {
  /// The current wall-clock time, used to record the Startzeit.
  DateTime now();

  /// A monotonically increasing duration since the app started.
  Duration monotonicNow();
}

/// The production clock.
class SystemClock implements AppClock {
  SystemClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  DateTime now() => DateTime.now();

  @override
  Duration monotonicNow() => _stopwatch.elapsed;
}
