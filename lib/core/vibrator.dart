import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Signals a due action to the Zeitnehmer by vibration.
abstract interface class Vibrator {
  Future<void> vibrate();

  /// Whether the device's haptic feedback setting allows vibration.
  ///
  /// Null when the platform cannot tell, such as on web.
  Future<bool?> isSystemHapticsEnabled();
}

/// The production vibrator backed by the platform's haptic feedback.
///
/// Does nothing on web and never throws: a missing vibration motor must not
/// interrupt the Reanimationsfall.
class HapticVibrator implements Vibrator {
  const HapticVibrator();

  static const _channel = MethodChannel('de.simonhauck.hp_cpr/haptics');

  @override
  Future<void> vibrate() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      // Best effort only.
    }
  }

  @override
  Future<bool?> isSystemHapticsEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMethod<bool>('isHapticFeedbackEnabled');
    } catch (_) {
      return null;
    }
  }
}
