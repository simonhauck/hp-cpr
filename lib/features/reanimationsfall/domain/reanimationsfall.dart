import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';

/// The current part of a Reanimationsfall.
enum Reanimationsphase { druckphase, analysephase }

/// A Reanimationsfall, from the Startzeit onwards.
///
/// Time zero is the first compression. The Reanimationsdauer is derived from
/// the monotonic clock. On resume, the wall clock is used only to recover an
/// interval in which the device was suspended.
class Reanimationsfall {
  Reanimationsfall.start({
    required AppClock clock,
    this.leitlinienprofil = Leitlinienprofil.erc2025,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    Duration backdate = Duration.zero,
  }) : _clock = clock,
       _monotonicStartOffset = clock.monotonicNow() - backdate,
       startzeit = clock.now().subtract(backdate) {
    if (backdate.isNegative) {
      throw ArgumentError.value(backdate, 'backdate', 'must not be negative');
    }
    _compressionCycleStartOffset = _monotonicStartOffset;
  }

  final AppClock _clock;
  Duration _monotonicAdjustment = Duration.zero;

  final Duration _monotonicStartOffset;

  /// The Leitlinienprofil snapshotted when the Reanimationsfall started.
  final Leitlinienprofil leitlinienprofil;

  /// Whether vibration was enabled when the Reanimationsfall started.
  final bool vibrationEnabled;

  /// Whether sound was enabled when the Reanimationsfall started.
  final bool soundEnabled;

  /// The corrected time zero of the Reanimationsfall.
  final DateTime startzeit;

  Reanimationsphase _phase = Reanimationsphase.druckphase;
  late Duration _compressionCycleStartOffset;
  Duration _compressionRemainingAtPause = Duration.zero;
  Duration? _analysephaseStartOffset;

  RhythmusanalyseErgebnis? _rhythmusanalyseErgebnis;
  String? _rhythmusanalyseNotiz;
  final List<RhythmusanalyseUeberspringung> _uebersprungeneRhythmusanalysen =
      [];

  /// The monotonic timeline shifted by intervals recovered from the wall clock.
  Duration _monotonicNow() => _clock.monotonicNow() + _monotonicAdjustment;

  /// Recovers time that passed while the device was suspended.
  ///
  /// A monotonic clock can stop during device sleep. On resume, a larger
  /// wall-clock delta is trusted to restore the missing interval. The wall
  /// clock never shortens the Reanimationsdauer, so a backwards clock change
  /// is ignored.
  void reconcileWithWallClock() {
    final wallElapsed = _clock.now().difference(startzeit);
    final elapsed = _monotonicNow() - _monotonicStartOffset;
    if (wallElapsed > elapsed) {
      _monotonicAdjustment += wallElapsed - elapsed;
    }
  }

  /// Pauses the compression timer and starts the Analysephase.
  void enterAnalysephase() {
    if (_phase != Reanimationsphase.druckphase) {
      throw StateError('already in the Analysephase');
    }

    final now = _monotonicNow();
    final cycle = leitlinienprofil.compressionCycle;
    final cycleElapsed = now - _compressionCycleStartOffset;
    _compressionRemainingAtPause = cycleElapsed >= cycle
        ? Duration.zero
        : cycle - cycleElapsed;
    _analysephaseStartOffset = now;
    _rhythmusanalyseErgebnis = null;
    _rhythmusanalyseNotiz = null;
    _phase = Reanimationsphase.analysephase;
  }

  /// Records the Rhythmusanalyse result with an optional note.
  void recordRhythmusanalyse(
    RhythmusanalyseErgebnis ergebnis, {
    String? notiz,
  }) {
    _requireAnalysephase();
    if (_rhythmusanalyseErgebnis != null) {
      throw StateError('a Rhythmusanalyse result is already recorded');
    }
    _rhythmusanalyseErgebnis = ergebnis;
    _rhythmusanalyseNotiz = _normalizeNotiz(notiz);
  }

  /// Adds or replaces the optional note of the recorded result.
  void setRhythmusanalyseNotiz(String? notiz) {
    _requireAnalysephase();
    if (_rhythmusanalyseErgebnis == null) {
      throw StateError('no Rhythmusanalyse result recorded');
    }
    _rhythmusanalyseNotiz = _normalizeNotiz(notiz);
  }

  /// Records a skipped Rhythmusanalyse and starts a fresh Druckphase.
  void skipRhythmusanalyse([RhythmusanalyseUebersprungenGrund? grund]) {
    _requireAnalysephase();
    if (_rhythmusanalyseErgebnis != null) {
      throw StateError('a Rhythmusanalyse result is already recorded');
    }
    _uebersprungeneRhythmusanalysen.add(
      RhythmusanalyseUeberspringung(
        zeitpunkt: _monotonicNow() - _monotonicStartOffset,
        grund: grund,
      ),
    );
    _startNextDruckphase();
  }

  /// Ends the Analysephase and starts a fresh 2-minute Druckphase.
  ///
  /// A recorded result or an explicit `unklar` is required first.
  void continueCpr() {
    _requireAnalysephase();
    if (_rhythmusanalyseErgebnis == null) {
      throw StateError('a Rhythmusanalyse result is required');
    }
    _startNextDruckphase();
  }

  ReanimationsfallSnapshot snapshot() {
    final now = _monotonicNow();
    final elapsed = now - _monotonicStartOffset;
    final cycle = leitlinienprofil.compressionCycle;
    final isDruckphase = _phase == Reanimationsphase.druckphase;
    final cycleElapsed = now - _compressionCycleStartOffset;
    final isRhythmusanalyseDue = isDruckphase && cycleElapsed >= cycle;
    final compressionRemaining = isDruckphase
        ? (isRhythmusanalyseDue ? Duration.zero : cycle - cycleElapsed)
        : _compressionRemainingAtPause;

    final analysephaseStart = _analysephaseStartOffset;
    final pauseDuration = analysephaseStart == null
        ? Duration.zero
        : now - analysephaseStart;
    final pauseTarget = leitlinienprofil.pauseTarget;
    final isPauseOverdue = pauseDuration > pauseTarget;

    return ReanimationsfallSnapshot(
      phase: _phase,
      leitlinienprofil: leitlinienprofil,
      vibrationEnabled: vibrationEnabled,
      soundEnabled: soundEnabled,
      startzeit: startzeit,
      reanimationsdauer: elapsed,
      compressionRemaining: compressionRemaining,
      rhythmusanalyseOverdue: isRhythmusanalyseDue
          ? cycleElapsed - cycle
          : Duration.zero,
      isRhythmusanalyseDue: isRhythmusanalyseDue,
      pauseDuration: pauseDuration,
      isPauseOverdue: isPauseOverdue,
      rhythmusanalyseErgebnis: _rhythmusanalyseErgebnis,
      rhythmusanalyseNotiz: _rhythmusanalyseNotiz,
      uebersprungeneRhythmusanalysen: List.unmodifiable(
        _uebersprungeneRhythmusanalysen,
      ),
    );
  }

  void _requireAnalysephase() {
    if (_phase != Reanimationsphase.analysephase) {
      throw StateError('not in the Analysephase');
    }
  }

  void _startNextDruckphase() {
    _phase = Reanimationsphase.druckphase;
    _compressionCycleStartOffset = _monotonicNow();
    _compressionRemainingAtPause = Duration.zero;
    _analysephaseStartOffset = null;
  }

  static String? _normalizeNotiz(String? notiz) {
    final trimmed = notiz?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// A read-only snapshot of a [Reanimationsfall].
class ReanimationsfallSnapshot {
  const ReanimationsfallSnapshot({
    required this.phase,
    required this.leitlinienprofil,
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.startzeit,
    required this.reanimationsdauer,
    required this.compressionRemaining,
    required this.rhythmusanalyseOverdue,
    required this.isRhythmusanalyseDue,
    required this.pauseDuration,
    required this.isPauseOverdue,
    required this.rhythmusanalyseErgebnis,
    required this.rhythmusanalyseNotiz,
    required this.uebersprungeneRhythmusanalysen,
  });

  final Reanimationsphase phase;
  final Leitlinienprofil leitlinienprofil;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final DateTime startzeit;
  final Duration reanimationsdauer;
  final Duration compressionRemaining;

  /// How long the Rhythmusanalyse has been due; zero before 0:00.
  final Duration rhythmusanalyseOverdue;
  final bool isRhythmusanalyseDue;

  /// How long the Analysephase has paused the compression timer.
  final Duration pauseDuration;

  final bool isPauseOverdue;

  /// The result recorded in the current Analysephase, if any.
  final RhythmusanalyseErgebnis? rhythmusanalyseErgebnis;
  final String? rhythmusanalyseNotiz;

  /// Every skipped Rhythmusanalyse, including skips without a reason.
  final List<RhythmusanalyseUeberspringung> uebersprungeneRhythmusanalysen;

  /// The most recently skipped Rhythmusanalyse, if any.
  RhythmusanalyseUeberspringung? get letzteRhythmusanalyseUeberspringung {
    if (uebersprungeneRhythmusanalysen.isEmpty) return null;
    return uebersprungeneRhythmusanalysen.last;
  }
}
