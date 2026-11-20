import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/ui/format/wall_time_format.dart';

void main() {
  test('a date is shown as dd.MM.yyyy with zero-padded day and month', () {
    expect(formatWallDate(DateTime(2026, 11, 20, 12, 3)), '20.11.2026');
    expect(formatWallDate(DateTime(2026, 1, 5)), '05.01.2026');
  });

  test('a date and time is shown as dd.MM.yyyy, HH:mm', () {
    expect(
      formatWallDateTime(DateTime(2026, 11, 20, 12, 3, 45)),
      '20.11.2026, 12:03',
    );
    expect(formatWallDateTime(DateTime(2026, 1, 5, 7, 5)), '05.01.2026, 07:05');
    expect(formatWallDateTime(DateTime(2026, 1, 5, 0, 0)), '05.01.2026, 00:00');
  });
}
