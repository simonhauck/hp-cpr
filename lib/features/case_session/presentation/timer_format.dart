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

/// Formats a duration as `MM:SS` or `H:MM:SS` for the case elapsed time.
String formatCaseElapsed(Duration duration) {
  if (duration.inHours == 0) return formatElapsed(duration);

  final minutes = _twoDigits(duration.inMinutes.remainder(60));
  final seconds = _twoDigits(duration.inSeconds.remainder(60));
  return '${duration.inHours}:$minutes:$seconds';
}

/// Formats a wall-clock time as `HH:MM:SS`.
String formatWallTime(DateTime time) {
  return '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}:'
      '${_twoDigits(time.second)}';
}

String _minutesAndSeconds(int totalSeconds) {
  return '${_twoDigits(totalSeconds ~/ 60)}:${_twoDigits(totalSeconds % 60)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
