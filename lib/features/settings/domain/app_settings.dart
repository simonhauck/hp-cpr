import 'package:flutter/foundation.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';

/// App-wide settings.
///
/// A Reanimationsfall snapshots the Leitlinienprofil when it starts, so
/// changing the setting later never rewrites an active or completed
/// Reanimationsfall.
class AppSettings extends ChangeNotifier {
  AppSettings({Leitlinienprofil leitlinienprofil = Leitlinienprofil.erc2025})
    : this._(leitlinienprofil);

  AppSettings._(this._leitlinienprofil);

  Leitlinienprofil _leitlinienprofil;

  Leitlinienprofil get leitlinienprofil => _leitlinienprofil;

  set leitlinienprofil(Leitlinienprofil value) {
    if (_leitlinienprofil == value) return;
    _leitlinienprofil = value;
    notifyListeners();
  }
}
