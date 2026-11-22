import 'package:hp_cpr/core/vibrator.dart';

class FakeVibrator implements Vibrator {
  int calls = 0;
  bool? systemHapticsEnabled = true;

  @override
  Future<void> vibrate() async {
    calls++;
  }

  @override
  Future<bool?> isSystemHapticsEnabled() async => systemHapticsEnabled;
}
