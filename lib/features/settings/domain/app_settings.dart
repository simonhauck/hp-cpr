import 'package:flutter/foundation.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';

/// App-wide settings.
///
/// A Reanimationsfall snapshots the Leitlinienprofil and Demo-Modus when it
/// starts, so changing a setting later never rewrites an active or completed
/// Reanimationsfall.
class AppSettings extends ChangeNotifier {
  AppSettings({
    Leitlinienprofil leitlinienprofil = Leitlinienprofil.erc2025,
    bool vibrationEnabled = true,
    bool soundEnabled = false,
    bool demoMode = false,
  }) : this._(leitlinienprofil, vibrationEnabled, soundEnabled, demoMode);

  AppSettings._(
    this._leitlinienprofil,
    this._vibrationEnabled,
    this._soundEnabled,
    this._demoMode,
  );

  Leitlinienprofil _leitlinienprofil;
  bool _vibrationEnabled;
  bool _soundEnabled;
  bool _demoMode;

  Leitlinienprofil get leitlinienprofil => _leitlinienprofil;

  set leitlinienprofil(Leitlinienprofil value) {
    if (_leitlinienprofil == value) return;
    _leitlinienprofil = value;
    notifyListeners();
  }

  bool get vibrationEnabled => _vibrationEnabled;

  set vibrationEnabled(bool value) {
    if (_vibrationEnabled == value) return;
    _vibrationEnabled = value;
    notifyListeners();
  }

  bool get soundEnabled => _soundEnabled;

  set soundEnabled(bool value) {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    notifyListeners();
  }

  /// Whether new Reanimationsfälle start in Demo-Modus.
  bool get demoMode => _demoMode;

  set demoMode(bool value) {
    if (_demoMode == value) return;
    _demoMode = value;
    notifyListeners();
  }
}
