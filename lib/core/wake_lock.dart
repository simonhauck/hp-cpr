import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake while an active Reanimationsfall is displayed.
abstract interface class WakeLock {
  Future<void> enable();

  Future<void> disable();
}

/// The production wake lock backed by `wakelock_plus`.
class WakelockPlusWakeLock implements WakeLock {
  const WakelockPlusWakeLock();

  @override
  Future<void> enable() => _set(true);

  @override
  Future<void> disable() => _set(false);

  Future<void> _set(bool enabled) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Keeping the screen awake is best effort: an unsupported platform must
      // not interrupt the Reanimationsfall.
    }
  }
}
