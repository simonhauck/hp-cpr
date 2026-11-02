import 'package:hp_cpr/ui/format/wall_time_format.dart';

export 'package:hp_cpr/ui/format/wall_time_format.dart';

/// Formats a countdown as `MM:SS`.
///
/// Partial seconds round up so a timer that has just started still reads its
/// full duration and never shows `00:00` before the deadline.
String formatCountdown(Duration remaining) {
  final totalSeconds =
      (remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil();
  return _minutesAndSeconds(totalSeconds);
}

/// Formats an elapsed duration as `MM:SS`, rounding partial seconds down.
String formatElapsed(Duration elapsed) {
  return _minutesAndSeconds(elapsed.inSeconds);
}

/// Formats a duration as `MM:SS` or `H:MM:SS` for the Reanimationsdauer.
String formatReanimationsdauer(Duration duration) {
  if (duration.inHours == 0) return formatElapsed(duration);

  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '${duration.inHours}:$minutes:$seconds';
}

String _minutesAndSeconds(int totalSeconds) {
  return '${twoDigits(totalSeconds ~/ 60)}:${twoDigits(totalSeconds % 60)}';
}
