import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/guideline/domain/guideline_profile.dart';

/// The active phase of a Reanimationsfall.
enum CasePhase { druckphase }

/// One Reanimationsfall, from the Startzeit onwards.
///
/// Time zero is the first compression. Elapsed time is derived from the
/// monotonic clock. On resume, the wall clock is used only to recover an
/// interval in which the device was suspended.
class CaseSession {
  CaseSession.start({
    required AppClock clock,
    this.profile = GuidelineProfile.erc2025,
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

  /// The guideline profile snapshotted when the case started.
  final GuidelineProfile profile;

  /// The corrected time zero of the case.
  final DateTime startzeit;

  /// Recovers time that passed while the device was suspended.
  ///
  /// A monotonic clock can stop during device sleep. On resume, a larger
  /// wall-clock delta is trusted to restore the missing interval. The wall
  /// clock never shortens elapsed time, so a backwards clock change is ignored.
  void reconcileWithWallClock() {
    final wallElapsed = _clock.now().difference(startzeit);
    final elapsed = _clock.monotonicNow() - _monotonicOffsetFromStart;
    if (wallElapsed > elapsed) {
      _monotonicOffsetFromStart = _clock.monotonicNow() - wallElapsed;
    }
  }

  CaseSessionView snapshot() {
    final elapsed = _clock.monotonicNow() - _monotonicOffsetFromStart;
    final cycle = profile.compressionCycle;
    final isAnalysisDue = elapsed >= cycle;

    return CaseSessionView(
      phase: CasePhase.druckphase,
      profile: profile,
      startzeit: startzeit,
      elapsed: elapsed,
      compressionRemaining: isAnalysisDue ? Duration.zero : cycle - elapsed,
      analysisOverdue: isAnalysisDue ? elapsed - cycle : Duration.zero,
      isAnalysisDue: isAnalysisDue,
    );
  }
}

/// A read-only view of a [CaseSession] at one point in time.
class CaseSessionView {
  const CaseSessionView({
    required this.phase,
    required this.profile,
    required this.startzeit,
    required this.elapsed,
    required this.compressionRemaining,
    required this.analysisOverdue,
    required this.isAnalysisDue,
  });

  final CasePhase phase;
  final GuidelineProfile profile;
  final DateTime startzeit;
  final Duration elapsed;
  final Duration compressionRemaining;

  /// How long the Rhythmusanalyse has been due; zero before 0:00.
  final Duration analysisOverdue;
  final bool isAnalysisDue;
}
