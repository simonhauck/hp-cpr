import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';

/// Loads, restores, and persists Reanimationsfälle for the app shell.
class ReanimationsfallSession {
  const ReanimationsfallSession({required this.store, required this.clock});

  final ReanimationsfallStore store;
  final AppClock clock;

  /// Restores the most recent active Reanimationsfall, if there is one.
  Future<Reanimationsfall?> loadActive() async {
    final states = await store.load();
    final active = [
      for (final state in states)
        if (state.zustand == ReanimationsfallZustand.laufend ||
            state.zustand == ReanimationsfallZustand.rosc)
          state,
    ]..sort((a, b) => b.startzeitUtc.compareTo(a.startzeitUtc));

    if (active.isEmpty) return null;
    return Reanimationsfall.restore(clock: clock, state: active.first);
  }

  /// Saves the current state, replacing the previous state of the same case.
  Future<void> persist(Reanimationsfall reanimationsfall) {
    return store.save(reanimationsfall.exportState());
  }

  /// The completed and Verworfene Reanimationsfälle, newest first.
  Future<List<ReanimationsfallState>> loadLog() async {
    final states = await store.load();
    return [
      for (final state in states)
        if (state.zustand == ReanimationsfallZustand.beendet ||
            state.zustand == ReanimationsfallZustand.verworfen)
          state,
    ]..sort((a, b) => b.startzeitUtc.compareTo(a.startzeitUtc));
  }

  /// Reconstructs the summary snapshot of a stored case.
  ReanimationsfallSnapshot snapshotFor(ReanimationsfallState state) {
    return Reanimationsfall.restore(clock: clock, state: state).snapshot();
  }

  Future<void> delete(String id) => store.delete(id);
}
