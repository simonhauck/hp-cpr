import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';

void main() {
  test('defaults to ERC 2025, vibration on, and sound off', () {
    final settings = AppSettings();

    expect(settings.leitlinienprofil, Leitlinienprofil.erc2025);
    expect(settings.vibrationEnabled, isTrue);
    expect(settings.soundEnabled, isFalse);
  });

  test('notifies listeners only when a value changes', () {
    final settings = AppSettings();
    var notifications = 0;
    settings.addListener(() => notifications++);

    settings.leitlinienprofil = Leitlinienprofil.aha2025;
    settings.leitlinienprofil = Leitlinienprofil.aha2025;
    settings.vibrationEnabled = false;
    settings.vibrationEnabled = false;
    settings.soundEnabled = true;

    expect(notifications, 3);
    expect(settings.leitlinienprofil, Leitlinienprofil.aha2025);
    expect(settings.vibrationEnabled, isFalse);
    expect(settings.soundEnabled, isTrue);
  });
}
