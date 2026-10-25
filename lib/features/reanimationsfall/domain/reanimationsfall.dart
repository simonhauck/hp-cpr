import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';

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
  bool _isSchockpause = false;
  bool _schockpauseWasDue = false;
  Duration _schockpauseOverdue = Duration.zero;
  int? _schockpauseOpeningSchockIndex;

  RhythmusanalyseErgebnis? _rhythmusanalyseErgebnis;
  String? _rhythmusanalyseNotiz;
  final List<RhythmusanalyseUeberspringung> _uebersprungeneRhythmusanalysen =
      [];
  final List<SchockEreignis> _schocks = [];
  final List<SchockRueckgaengig> _schockRueckgaengigkeiten = [];
  final List<AdrenalinGabe> _adrenalinGaben = [];
  RhythmusanalyseErgebnis? _adrenalinAusloesendesErgebnis;
  bool _ersteAdrenalinGabeFaellig = false;

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
    if (!_isSchockpause) {
      _compressionRemainingAtPause = _remainingInCycle(now);
    }

    _analysephaseStartOffset = now;
    _rhythmusanalyseErgebnis = null;
    _rhythmusanalyseNotiz = null;
    _isSchockpause = false;
    _schockpauseWasDue = false;
    _schockpauseOverdue = Duration.zero;
    _schockpauseOpeningSchockIndex = null;
    _phase = Reanimationsphase.analysephase;
  }

  /// Records a Schock with optional energy.
  ///
  /// A Schock in the Druckphase pauses the compression timer; the Zeitnehmer
  /// continues CPR explicitly. A Schock in the Analysephase leaves the paused
  /// phase and the result requirement unchanged.
  void recordSchock({int? energieJoule}) {
    _requireValidEnergie(energieJoule);

    final now = _monotonicNow();
    _schocks.add(
      SchockEreignis(
        zeitpunkt: now - _monotonicStartOffset,
        energieJoule: energieJoule,
      ),
    );

    if (_phase == Reanimationsphase.druckphase && !_isSchockpause) {
      final cycleElapsed = now - _compressionCycleStartOffset;
      final cycle = leitlinienprofil.compressionCycle;
      _schockpauseWasDue = cycleElapsed >= cycle;
      _schockpauseOverdue = _schockpauseWasDue
          ? cycleElapsed - cycle
          : Duration.zero;
      _compressionRemainingAtPause = _remainingInCycle(now);
      _schockpauseOpeningSchockIndex = _schocks.length - 1;
      _isSchockpause = true;
    }

    _updateAdrenalinGabeFaelligkeit();
  }

  /// Records an Adrenalin dose and starts a new Zeitfenster.
  void recordAdrenalin() {
    _adrenalinGaben.add(
      AdrenalinGabe(zeitpunkt: _monotonicNow() - _monotonicStartOffset),
    );
    _ersteAdrenalinGabeFaellig = false;
  }

  /// Marks the most recent active Schock as undone.
  void undoLastSchock() {
    final index = _lastActiveSchockIndex;
    if (index == -1) {
      throw StateError('no active Schock to undo');
    }

    final now = _monotonicNow();
    _schockRueckgaengigkeiten.add(
      SchockRueckgaengig(
        schockIndex: index,
        zeitpunkt: now - _monotonicStartOffset,
      ),
    );

    if (_phase == Reanimationsphase.druckphase &&
        _isSchockpause &&
        index == _schockpauseOpeningSchockIndex) {
      final cycle = leitlinienprofil.compressionCycle;
      final remaining = _compressionRemainingAtPause;
      _compressionCycleStartOffset =
          now - (cycle - remaining) - _schockpauseOverdue;
      _compressionRemainingAtPause = Duration.zero;
      _isSchockpause = false;
      _schockpauseWasDue = false;
      _schockpauseOverdue = Duration.zero;
      _schockpauseOpeningSchockIndex = null;
    }

    _updateAdrenalinGabeFaelligkeit();
  }

  /// Adds or replaces the energy of the most recent active Schock.
  void setLastSchockEnergie(int energieJoule) {
    _requireValidEnergie(energieJoule);

    final index = _lastActiveSchockIndex;
    if (index == -1) {
      throw StateError('no active Schock');
    }
    _schocks[index] = _schocks[index].copyWith(energieJoule: energieJoule);
  }

  int get _lastActiveSchockIndex {
    for (var index = _schocks.length - 1; index >= 0; index--) {
      final undone = _schockRueckgaengigkeiten.any(
        (entry) => entry.schockIndex == index,
      );
      if (!undone) return index;
    }
    return -1;
  }

  int get _aktiveSchockAnzahl =>
      _schocks.length - _schockRueckgaengigkeiten.length;

  void _updateAdrenalinGabeFaelligkeit() {
    if (_adrenalinGaben.isNotEmpty) {
      _ersteAdrenalinGabeFaellig = false;
      return;
    }

    final ergebnis = _adrenalinAusloesendesErgebnis;
    _ersteAdrenalinGabeFaellig = switch (ergebnis?.kategorie) {
      RhythmusanalyseKategorie.nichtSchockbar => true,
      RhythmusanalyseKategorie.schockbar =>
        _aktiveSchockAnzahl >= leitlinienprofil.adrenalinErsteGabeNachSchock,
      RhythmusanalyseKategorie.rosc ||
      RhythmusanalyseKategorie.unklar ||
      null => false,
    };
  }

  Duration _remainingInCycle(Duration now) {
    final cycle = leitlinienprofil.compressionCycle;
    final cycleElapsed = now - _compressionCycleStartOffset;
    return cycleElapsed >= cycle ? Duration.zero : cycle - cycleElapsed;
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
    _adrenalinAusloesendesErgebnis = ergebnis;
    _updateAdrenalinGabeFaelligkeit();
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

  /// Ends the Analysephase or a Schock pause and starts a fresh 2-minute
  /// Druckphase.
  ///
  /// In the Analysephase, a recorded result or an explicit `unklar` is
  /// required first. A Schock recorded in the Druckphase can be continued
  /// without a result.
  void continueCpr() {
    if (_phase == Reanimationsphase.analysephase) {
      if (_rhythmusanalyseErgebnis == null) {
        throw StateError('a Rhythmusanalyse result is required');
      }
      _startNextDruckphase();
      return;
    }

    if (_isSchockpause) {
      _startNextDruckphase();
      return;
    }

    throw StateError('CPR is already running');
  }

  ReanimationsfallSnapshot snapshot() {
    final now = _monotonicNow();
    final elapsed = now - _monotonicStartOffset;
    final cycle = leitlinienprofil.compressionCycle;
    final isDruckphase = _phase == Reanimationsphase.druckphase;
    final isSchockpause = isDruckphase && _isSchockpause;
    final cycleElapsed = now - _compressionCycleStartOffset;
    final isRhythmusanalyseDue =
        isDruckphase &&
        (isSchockpause ? _schockpauseWasDue : cycleElapsed >= cycle);
    final compressionRemaining = isDruckphase
        ? (isSchockpause
              ? _compressionRemainingAtPause
              : (isRhythmusanalyseDue ? Duration.zero : cycle - cycleElapsed))
        : _compressionRemainingAtPause;
    final rhythmusanalyseOverdue = isSchockpause
        ? _schockpauseOverdue
        : (isRhythmusanalyseDue ? cycleElapsed - cycle : Duration.zero);

    final analysephaseStart = _analysephaseStartOffset;
    final pauseDuration = analysephaseStart == null
        ? Duration.zero
        : now - analysephaseStart;
    final pauseTarget = leitlinienprofil.pauseTarget;
    final isPauseOverdue = pauseDuration > pauseTarget;

    final schocks = [
      for (var index = 0; index < _schocks.length; index++)
        SchockEintrag(
          ereignis: _schocks[index],
          rueckgaengig: _schockRueckgaengigkeiten.any(
            (entry) => entry.schockIndex == index,
          ),
        ),
    ];

    final letzteAdrenalinGabe = _adrenalinGaben.isEmpty
        ? null
        : _adrenalinGaben.last;
    final adrenalinSeitLetzterGabe = letzteAdrenalinGabe == null
        ? null
        : elapsed - letzteAdrenalinGabe.zeitpunkt;
    final adrenalinZeitfensterZustand = letzteAdrenalinGabe == null
        ? AdrenalinZeitfensterZustand.keine
        : _adrenalinZustand(adrenalinSeitLetzterGabe!);

    return ReanimationsfallSnapshot(
      phase: _phase,
      leitlinienprofil: leitlinienprofil,
      vibrationEnabled: vibrationEnabled,
      soundEnabled: soundEnabled,
      startzeit: startzeit,
      reanimationsdauer: elapsed,
      compressionRemaining: compressionRemaining,
      rhythmusanalyseOverdue: rhythmusanalyseOverdue,
      isRhythmusanalyseDue: isRhythmusanalyseDue,
      isSchockpause: isSchockpause,
      pauseDuration: pauseDuration,
      isPauseOverdue: isPauseOverdue,
      rhythmusanalyseErgebnis: _rhythmusanalyseErgebnis,
      rhythmusanalyseNotiz: _rhythmusanalyseNotiz,
      uebersprungeneRhythmusanalysen: List.unmodifiable(
        _uebersprungeneRhythmusanalysen,
      ),
      schocks: List.unmodifiable(schocks),
      schockRueckgaengigkeiten: List.unmodifiable(_schockRueckgaengigkeiten),
      adrenalinGaben: List.unmodifiable(_adrenalinGaben),
      adrenalinSeitLetzterGabe: adrenalinSeitLetzterGabe,
      adrenalinZeitfensterZustand: adrenalinZeitfensterZustand,
      istErsteAdrenalinGabeFaellig: _ersteAdrenalinGabeFaellig,
    );
  }

  AdrenalinZeitfensterZustand _adrenalinZustand(Duration seit) {
    if (seit < leitlinienprofil.adrenalinZeitfensterFruehestens) {
      return AdrenalinZeitfensterZustand.wartet;
    }
    if (seit <= leitlinienprofil.adrenalinZeitfensterSpaetestens) {
      return AdrenalinZeitfensterZustand.faellig;
    }
    return AdrenalinZeitfensterZustand.ueberfaellig;
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
    _isSchockpause = false;
    _schockpauseWasDue = false;
    _schockpauseOverdue = Duration.zero;
    _schockpauseOpeningSchockIndex = null;
  }

  static void _requireValidEnergie(int? energieJoule) {
    if (energieJoule != null && energieJoule <= 0) {
      throw ArgumentError.value(
        energieJoule,
        'energieJoule',
        'must be greater than zero',
      );
    }
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
    required this.isSchockpause,
    required this.pauseDuration,
    required this.isPauseOverdue,
    required this.rhythmusanalyseErgebnis,
    required this.rhythmusanalyseNotiz,
    required this.uebersprungeneRhythmusanalysen,
    required this.schocks,
    required this.schockRueckgaengigkeiten,
    required this.adrenalinGaben,
    required this.adrenalinSeitLetzterGabe,
    required this.adrenalinZeitfensterZustand,
    required this.istErsteAdrenalinGabeFaellig,
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

  /// Whether a Schock recorded in the Druckphase paused the compression timer.
  final bool isSchockpause;

  /// How long the Analysephase has paused the compression timer.
  final Duration pauseDuration;

  final bool isPauseOverdue;

  /// The result recorded in the current Analysephase, if any.
  final RhythmusanalyseErgebnis? rhythmusanalyseErgebnis;
  final String? rhythmusanalyseNotiz;

  /// Every skipped Rhythmusanalyse, including skips without a reason.
  final List<RhythmusanalyseUeberspringung> uebersprungeneRhythmusanalysen;

  /// Every recorded Schock, including the ones marked as undone.
  final List<SchockEintrag> schocks;

  /// Every undo entry for a Schock, kept as its own log record.
  final List<SchockRueckgaengig> schockRueckgaengigkeiten;

  /// Every recorded Adrenalin dose.
  final List<AdrenalinGabe> adrenalinGaben;

  /// The time since the last Adrenalin dose, or null before the first dose.
  final Duration? adrenalinSeitLetzterGabe;

  /// The state of the current Adrenalin Zeitfenster.
  final AdrenalinZeitfensterZustand adrenalinZeitfensterZustand;

  /// Whether the first Adrenalin dose is clinically due.
  final bool istErsteAdrenalinGabeFaellig;

  /// The most recent Adrenalin dose, if any.
  AdrenalinGabe? get letzteAdrenalinGabe {
    if (adrenalinGaben.isEmpty) return null;
    return adrenalinGaben.last;
  }

  /// The number of Schocks that have not been undone.
  int get schockAnzahl =>
      schocks.where((schock) => !schock.rueckgaengig).length;

  /// The most recent Schock that has not been undone, if any.
  SchockEintrag? get letzterAktiverSchock {
    for (final schock in schocks.reversed) {
      if (!schock.rueckgaengig) return schock;
    }
    return null;
  }

  /// The most recently skipped Rhythmusanalyse, if any.
  RhythmusanalyseUeberspringung? get letzteRhythmusanalyseUeberspringung {
    if (uebersprungeneRhythmusanalysen.isEmpty) return null;
    return uebersprungeneRhythmusanalysen.last;
  }
}
