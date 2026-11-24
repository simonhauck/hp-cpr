import 'package:flutter/foundation.dart';

/// Asks the start page to start a Reanimationsfall in Demo-Modus.
///
/// The start page is the only place that creates Reanimationsfälle, so the
/// tutorial opened from the menu signals it here instead of starting one.
class DemoStartRequest extends ChangeNotifier {
  void request() => notifyListeners();
}
