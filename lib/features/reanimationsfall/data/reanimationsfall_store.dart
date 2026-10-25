import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_state_json.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';

/// The local store for active, completed, and discarded Reanimationsfälle.
abstract interface class ReanimationsfallStore {
  Future<List<ReanimationsfallState>> load();

  /// Adds the state or replaces the state with the same id.
  Future<void> save(ReanimationsfallState state);

  Future<void> delete(String id);
}

/// An in-memory store used by tests.
class InMemoryReanimationsfallStore implements ReanimationsfallStore {
  final Map<String, ReanimationsfallState> _states = {};

  @override
  Future<List<ReanimationsfallState>> load() async =>
      List.unmodifiable(_states.values);

  @override
  Future<void> save(ReanimationsfallState state) async {
    _states[state.id] = state;
  }

  @override
  Future<void> delete(String id) async {
    _states.remove(id);
  }
}

/// The production store backed by `shared_preferences`.
class SharedPreferencesReanimationsfallStore implements ReanimationsfallStore {
  const SharedPreferencesReanimationsfallStore({this.key = _defaultKey});

  static const String _defaultKey = 'reanimationsfaelle';

  final String key;

  @override
  Future<List<ReanimationsfallState>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in decoded)
          reanimationsfallStateFromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      // A damaged or unreadable store must not prevent the app from starting.
      return const [];
    }
  }

  @override
  Future<void> save(ReanimationsfallState state) async {
    final states = List<ReanimationsfallState>.of(await load());
    final index = states.indexWhere((stored) => stored.id == state.id);
    if (index == -1) {
      states.add(state);
    } else {
      states[index] = state;
    }
    await _write(states);
  }

  @override
  Future<void> delete(String id) async {
    final states = List<ReanimationsfallState>.of(await load());
    states.removeWhere((state) => state.id == id);
    await _write(states);
  }

  Future<void> _write(List<ReanimationsfallState> states) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([
        for (final state in states) reanimationsfallStateToJson(state),
      ]),
    );
  }
}
