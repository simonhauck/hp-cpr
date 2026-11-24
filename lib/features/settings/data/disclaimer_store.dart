import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the first-start Rechtlicher Hinweis was acknowledged.
abstract interface class DisclaimerStore {
  Future<bool> isAcknowledged();

  Future<void> acknowledge();
}

/// An in-memory store used by tests.
class InMemoryDisclaimerStore implements DisclaimerStore {
  InMemoryDisclaimerStore({this._acknowledged = true});

  bool _acknowledged;

  @override
  Future<bool> isAcknowledged() async => _acknowledged;

  @override
  Future<void> acknowledge() async {
    _acknowledged = true;
  }
}

/// The production store backed by `shared_preferences`.
class SharedPreferencesDisclaimerStore implements DisclaimerStore {
  const SharedPreferencesDisclaimerStore({this.key = _defaultKey});

  static const String _defaultKey = 'rechtlicherHinweisAcknowledged';

  final String key;

  @override
  Future<bool> isAcknowledged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      // An unreadable store must not block the app; show the notice again.
      return false;
    }
  }

  @override
  Future<void> acknowledge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
