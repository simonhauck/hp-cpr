/// Formats a wall-clock time as `HH:MM:SS`.
String formatWallTime(DateTime time) {
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}:'
      '${twoDigits(time.second)}';
}

/// Formats a wall-clock time as `HH:MM`.
String formatWallTimeMinutes(DateTime time) {
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}

/// Pads a number to two digits.
String twoDigits(int value) => value.toString().padLeft(2, '0');
