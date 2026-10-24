import 'package:flutter/foundation.dart';

import 'package:hp_cpr/features/guideline/domain/guideline_profile.dart';

/// App-wide settings.
///
/// A case snapshots the guideline profile when it starts, so changing the
/// setting later never rewrites an active or completed Reanimationsfall.
class AppSettings extends ChangeNotifier {
  AppSettings({GuidelineProfile guidelineProfile = GuidelineProfile.erc2025})
    : this._(guidelineProfile);

  AppSettings._(this._guidelineProfile);

  GuidelineProfile _guidelineProfile;

  GuidelineProfile get guidelineProfile => _guidelineProfile;

  set guidelineProfile(GuidelineProfile value) {
    if (_guidelineProfile == value) return;
    _guidelineProfile = value;
    notifyListeners();
  }
}
