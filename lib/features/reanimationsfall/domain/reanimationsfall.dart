import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';

/// The current part of a Reanimationsfall.
enum Reanimationsphase { druckphase }

/// A Reanimationsfall, from the Startzeit onwards.
///
/// Time zero is the first compression. The Reanimationsdauer is derived from
/// the monotonic clock. On resume, the wall clock is used only to recover an
/// interval in which the device was suspended.
class Reanimationsfall {
  Reanimationsfall.start({
    required AppClock clock,
    this.leitlinienprofil = Leitlinienprofil.erc2025,
    Duration backdate = Duration.zero,
  }) : _clock = clock,
       _monotonicOffsetFromStart = clock.monotonicNow() - backdate,
       startzeit = clock.now().subtract(backdate) {
    if (backdate.isNegative) {
      throw ArgumentError.value(backdate, 'backdate', 'must not be negative');
    }
  }

  final AppClock _clock;
  Duration _monotonicOffsetFromStart;

  /// The Leitlinienprofil snapshotted when the Reanimationsfall started.
  final Leitlinienprofil leitlinienprofil;

  /// The corrected time zero of the Reanimationsfall.
  final DateTime startzeit;

  /// Recovers time that passed while the device was suspended.
  ///
  /// A monotonic clock can stop during device sleep. On resume, a larger
  /// wall-clock delta is trusted to restore the missing interval. The wall
  /// clock never shortens the Reanimationsdauer, so a backwards clock change
  /// is ignored.
  void reconcileWithWallClock() {
    final wallElapsed = _clock.now().difference(startzeit);
    final elapsed = _clock.monotonicNow() - _monotonicOffsetFromStart;
    if (wallElapsed > elapsed) {
      _monotonicOffsetFromStart = _clock.monotonicNow() - wallElapsed;
    }
  }

  ReanimationsfallSnapshot snapshot() {
    final elapsed = _clock.monotonicNow() - _monotonicOffsetFromStart;
    final cycle = leitlinienprofil.compressionCycle;
    final isRhythmusanalyseDue = elapsed >= cycle;

    return ReanimationsfallSnapshot(
      phase: Reanimationsphase.druckphase,
      leitlinienprofil: leitlinienprofil,
      startzeit: startzeit,
      reanimationsdauer: elapsed,
      compressionRemaining: isRhythmusanalyseDue
          ? Duration.zero
          : cycle - elapsed,
      rhythmusanalyseOverdue: isRhythmusanalyseDue
          ? elapsed - cycle
          : Duration.zero,
      isRhythmusanalyseDue: isRhythmusanalyseDue,
    );
  }
}

/// A read-only snapshot of a [Reanimationsfall].
class ReanimationsfallSnapshot {
  const ReanimationsfallSnapshot({
    required this.phase,
    required this.leitlinienprofil,
    required this.startzeit,
    required this.reanimationsdauer,
    required this.compressionRemaining,
    required this.rhythmusanalyseOverdue,
    required this.isRhythmusanalyseDue,
  });

  final Reanimationsphase phase;
  final Leitlinienprofil leitlinienprofil;
  final DateTime startzeit;
  final Duration reanimationsdauer;
  final Duration compressionRemaining;

  /// How long the Rhythmusanalyse has been due; zero before 0:00.
  final Duration rhythmusanalyseOverdue;
  final bool isRhythmusanalyseDue;
}
