import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the tutorial has been shown on this device.
abstract interface class TutorialStore {
  Future<bool> hasSeen();

  Future<void> markSeen();
}

/// An in-memory store used by tests.
class InMemoryTutorialStore implements TutorialStore {
  InMemoryTutorialStore({this.seen = false});

  bool seen;

  @override
  Future<bool> hasSeen() async => seen;

  @override
  Future<void> markSeen() async {
    seen = true;
  }
}

/// The production store backed by `shared_preferences`.
class SharedPreferencesTutorialStore implements TutorialStore {
  const SharedPreferencesTutorialStore({this.key = _defaultKey});

  static const String _defaultKey = 'tutorial_seen';

  final String key;

  @override
  Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      // An unreadable store must never put the tutorial in front of a case.
      return true;
    }
  }

  @override
  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {
      // Showing the tutorial again later is harmless.
    }
  }
}
