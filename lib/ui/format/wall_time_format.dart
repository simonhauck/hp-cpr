/// Formats a wall-clock time as `HH:MM:SS`.
String formatWallTime(DateTime time) {
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}:'
      '${twoDigits(time.second)}';
}

/// Formats a wall-clock time as `HH:MM`.
String formatWallTimeMinutes(DateTime time) {
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}

/// Formats the date of a wall-clock time as `dd.MM.yyyy`.
String formatWallDate(DateTime time) {
  return '${twoDigits(time.day)}.${twoDigits(time.month)}.'
      '${time.year.toString().padLeft(4, '0')}';
}

/// Formats a wall-clock time with date as `dd.MM.yyyy, HH:mm`.
String formatWallDateTime(DateTime time) {
  return '${formatWallDate(time)}, ${formatWallTimeMinutes(time)}';
}

/// Pads a number to two digits.
String twoDigits(int value) => value.toString().padLeft(2, '0');
