import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';

void main() {
  test('a fresh countdown shows its full duration', () {
    expect(formatCountdown(const Duration(seconds: 120)), '02:00');
    expect(formatCountdown(const Duration(milliseconds: 119984)), '02:00');
  });

  test('a countdown rounds partial seconds up and never shows 00:00 early', () {
    expect(formatCountdown(const Duration(milliseconds: 500)), '00:01');
    expect(formatCountdown(const Duration(microseconds: 1)), '00:01');
    expect(formatCountdown(Duration.zero), '00:00');
  });

  test('elapsed time and the overdue count-up round partial seconds down', () {
    expect(formatElapsed(const Duration(milliseconds: 1999)), '00:01');
    expect(formatElapsed(const Duration(seconds: 65)), '01:05');
  });

  test(
    'Reanimationsdauer includes hours once the Reanimationsfall runs that long',
    () {
      expect(
        formatReanimationsdauer(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
    },
  );

  test('wall-clock time is shown with seconds', () {
    expect(formatWallTime(DateTime(2026, 10, 25, 7, 5, 9)), '07:05:09');
  });
}
