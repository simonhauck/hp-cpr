package de.simonhauck.hp_cpr

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "de.simonhauck.hp_cpr/haptics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Haptic feedback only vibrates while this system setting is on.
                    "isHapticFeedbackEnabled" -> result.success(
                        Settings.System.getInt(
                            contentResolver,
                            Settings.System.HAPTIC_FEEDBACK_ENABLED,
                            1,
                        ) != 0,
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
