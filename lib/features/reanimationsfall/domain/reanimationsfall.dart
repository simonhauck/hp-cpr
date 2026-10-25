import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';

/// The current part of a Reanimationsfall.
enum Reanimationsphase { druckphase, analysephase }

/// The lifecycle state of a Reanimationsfall.
enum ReanimationsfallZustand { laufend, rosc, beendet, verworfen }

/// Why the Zeitnehmer ended the Reanimationsfall.
enum Beendigungsgrund { uebergabe, abbruch, sonstiges }

/// One continuous resuscitation segment of a Reanimationsfall.
///
/// A segment starts with the first compression or a Reanimationswiederbeginn
/// and ends with ROSC or the end of the Reanimationsfall.
class Reanimationsabschnitt {
  const Reanimationsabschnitt({
    required this.index,
    required this.start,
    this.ende,
  });

  final int index;

  /// The elapsed time since the Startzeit when the segment started.
  final Duration start;

  /// The elapsed time since the Startzeit when the segment ended, if it did.
  final Duration? ende;

  Reanimationsabschnitt copyWith({Duration? ende}) {
    return Reanimationsabschnitt(index: index, start: start, ende: ende);
  }

  /// The segment duration up to [now] for an open segment.
  Duration dauerBis(Duration now) => (ende ?? now) - start;
}

/// A recorded ROSC event.
class RoscEreignis {
  const RoscEreignis({required this.zeitpunkt});

  final Duration zeitpunkt;
}

/// A recorded Reanimationswiederbeginn after ROSC.
class Reanimationswiederbeginn {
  const Reanimationswiederbeginn({required this.zeitpunkt});

  final Duration zeitpunkt;
}

/// A manual reset of the current Druckphase to a fresh 2-minute cycle.
class DruckphaseNeustart {
  const DruckphaseNeustart({required this.zeitpunkt});

  /// The elapsed time since the Startzeit when the cycle was reset.
  final Duration zeitpunkt;
}

/// The end of a Reanimationsfall, including its reason.
class ReanimationsfallEnde {
  const ReanimationsfallEnde({required this.zeitpunkt, required this.grund});

  final Duration zeitpunkt;
  final Beendigungsgrund grund;
}

/// A Reanimationsfall, from the Startzeit onwards.
///
/// Time zero is the first compression. The Reanimationsdauer is derived from
/// the monotonic clock. On resume, the wall clock is used only to recover an
/// interval in which the device was suspended.
class Reanimationsfall {
  static int _nextId = 0;

  Reanimationsfall.start({
    required AppClock clock,
    this.leitlinienprofil = Leitlinienprofil.erc2025,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    Duration backdate = Duration.zero,
  }) : _clock = clock,
       _monotonicStartOffset = clock.monotonicNow() - backdate,
       id =
           '${clock.now().microsecondsSinceEpoch}-'
           '${clock.monotonicNow().inMicroseconds}-'
           '${_nextId++}',
       startzeit = clock.now().subtract(backdate),
       startzeitUtc = clock.now().toUtc().subtract(backdate),
       utcOffsetMinutes = clock
           .now()
           .subtract(backdate)
           .timeZoneOffset
           .inMinutes {
    if (backdate.isNegative) {
      throw ArgumentError.value(backdate, 'backdate', 'must not be negative');
    }
    _compressionCycleStartOffset = _monotonicStartOffset;
    _abschnitte.add(
      const Reanimationsabschnitt(index: 0, start: Duration.zero),
    );
  }

  /// Restores a Reanimationsfall from its persisted state.
  Reanimationsfall.restore({
    required AppClock clock,
    required ReanimationsfallState state,
  }) : _clock = clock,
       _monotonicStartOffset =
           clock.monotonicNow() -
           clock.now().toUtc().difference(state.startzeitUtc),
       id = state.id,
       leitlinienprofil = state.leitlinienprofil,
       vibrationEnabled = state.vibrationEnabled,
       soundEnabled = state.soundEnabled,
       startzeit = state.startzeit,
       startzeitUtc = state.startzeitUtc,
       utcOffsetMinutes = state.utcOffsetMinutes {
    _zustand = state.zustand;
    _phase = state.phase;
    _compressionCycleStartOffset =
        _monotonicStartOffset + state.compressionCycleStartOffset;
    _compressionRemainingAtPause = state.compressionRemainingAtPause;
    final analysephaseStart = state.analysephaseStartOffset;
    _analysephaseStartOffset = analysephaseStart == null
        ? null
        : _monotonicStartOffset + analysephaseStart;
    _adrenalinAusloesendesErgebnis = state.adrenalinAusloesendesErgebnis;
    _ende = state.ende;
    _verworfenAm = state.verworfenAm;
    _schocks.addAll(state.schocks);
    _adrenalinGaben.addAll(state.adrenalinGaben);
    _amiodaronGaben.addAll(state.amiodaronGaben);
    _uebersprungeneRhythmusanalysen.addAll(
      state.uebersprungeneRhythmusanalysen,
    );
    _rhythmusanalyseEintraege.addAll(state.rhythmusanalyseEintraege);
    _druckphaseNeustarts.addAll(state.druckphaseNeustarts);
    _messwerte.addAll(state.messwerte);
    _notizen.addAll(state.notizen);
    _roscEreignisse.addAll(state.roscEreignisse);
    _wiederbeginnEreignisse.addAll(state.wiederbeginnEreignisse);
    _abschnitte.addAll(state.abschnitte);
    _updateAdrenalinGabeFaelligkeit();
  }

  final AppClock _clock;
  Duration _monotonicAdjustment = Duration.zero;

  final Duration _monotonicStartOffset;

  /// The identity of this Reanimationsfall in the local store.
  final String id;

  /// The Leitlinienprofil snapshotted when the Reanimationsfall started.
  final Leitlinienprofil leitlinienprofil;

  /// Whether vibration was enabled when the Reanimationsfall started.
  final bool vibrationEnabled;

  /// Whether sound was enabled when the Reanimationsfall started.
  final bool soundEnabled;

  /// The corrected wall-clock time zero of the Reanimationsfall.
  final DateTime startzeit;

  /// The time zero as an absolute instant.
  final DateTime startzeitUtc;

  /// The device's UTC offset when the Reanimationsfall started.
  final int utcOffsetMinutes;

  ReanimationsfallZustand _zustand = ReanimationsfallZustand.laufend;
  final List<Reanimationsabschnitt> _abschnitte = [];
  final List<RoscEreignis> _roscEreignisse = [];
  final List<Reanimationswiederbeginn> _wiederbeginnEreignisse = [];
  ReanimationsfallEnde? _ende;
  Duration? _verworfenAm;
  final List<RhythmusanalyseEintrag> _rhythmusanalyseEintraege = [];
  final List<Messwert> _messwerte = [];
  final List<ReanimationsfallNotiz> _notizen = [];

  Reanimationsphase _phase = Reanimationsphase.druckphase;
  late Duration _compressionCycleStartOffset;
  Duration _compressionRemainingAtPause = Duration.zero;
  Duration? _analysephaseStartOffset;

  final List<RhythmusanalyseUeberspringung> _uebersprungeneRhythmusanalysen =
      [];
  final List<DruckphaseNeustart> _druckphaseNeustarts = [];
  final List<SchockEreignis> _schocks = [];
  final List<AdrenalinGabe> _adrenalinGaben = [];
  final List<AmiodaronGabe> _amiodaronGaben = [];
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
    final wallElapsed = _clock.now().toUtc().difference(startzeitUtc);
    final elapsed = _monotonicNow() - _monotonicStartOffset;
    if (wallElapsed > elapsed) {
      _monotonicAdjustment += wallElapsed - elapsed;
    }
  }

  /// Pauses the compression timer and starts the Analysephase.
  void enterAnalysephase() {
    _requireLaufend();
    if (_phase != Reanimationsphase.druckphase) {
      throw StateError('already in the Analysephase');
    }

    final now = _monotonicNow();
    _compressionRemainingAtPause = _remainingInCycle(now);
    _analysephaseStartOffset = now;
    _phase = Reanimationsphase.analysephase;
  }

  /// Records a Schock with optional energy.
  ///
  /// A Schock is a record-only event: it never pauses the compression timer
  /// and never changes the current phase.
  void recordSchock({int? energieJoule}) {
    _requireLaufend();
    _requireValidEnergie(energieJoule);

    _schocks.add(
      SchockEreignis(zeitpunkt: _elapsedOffset, energieJoule: energieJoule),
    );
    // The shock count still feeds the derived Adrenalin and Amiodaron hints.
    _updateAdrenalinGabeFaelligkeit();
  }

  /// Records an Adrenalin dose and starts a new Zeitfenster.
  void recordAdrenalin() {
    _requireLaufend();
    _adrenalinGaben.add(
      AdrenalinGabe(zeitpunkt: _monotonicNow() - _monotonicStartOffset),
    );
    _ersteAdrenalinGabeFaellig = false;
  }

  /// Records an Amiodaron dose.
  ///
  /// The first dose is 300 mg and the second 150 mg. The app never records a
  /// dose on its own; this command is only called when one was actually given.
  void recordAmiodaron() {
    _requireLaufend();
    if (_amiodaronGaben.length >= 2) {
      throw StateError('at most two Amiodaron doses are supported');
    }

    _amiodaronGaben.add(
      AmiodaronGabe(
        zeitpunkt: _monotonicNow() - _monotonicStartOffset,
        dosisMg: _amiodaronGaben.isEmpty
            ? AmiodaronHinweis.ersteGabe.dosisMg!
            : AmiodaronHinweis.zweiteGabe.dosisMg!,
      ),
    );
  }

  /// Records the Rhythmusanalyse result, optionally records a Schock, and
  /// starts the next Druckphase or enters ROSC.
  void completeRhythmusanalyse(
    RhythmusanalyseErgebnis ergebnis, {
    bool schockAbgegeben = false,
  }) {
    _requireLaufend();
    _requireAnalysephase();
    if (schockAbgegeben &&
        ergebnis.kategorie != RhythmusanalyseKategorie.schockbar) {
      throw ArgumentError.value(
        schockAbgegeben,
        'schockAbgegeben',
        'a Schock can only accompany a shockable result',
      );
    }

    final enteredRosc = _recordRhythmusanalyse(ergebnis);
    if (schockAbgegeben) {
      recordSchock();
    }
    if (enteredRosc) return;

    _startNextDruckphase();
  }

  bool _recordRhythmusanalyse(RhythmusanalyseErgebnis ergebnis) {
    _adrenalinAusloesendesErgebnis = ergebnis;
    _rhythmusanalyseEintraege.add(
      RhythmusanalyseEintrag(zeitpunkt: _elapsedOffset, ergebnis: ergebnis),
    );
    _updateAdrenalinGabeFaelligkeit();

    if (ergebnis == RhythmusanalyseErgebnis.rosc) {
      _recordRosc();
      return true;
    }
    return false;
  }

  /// Resets the current Druckphase to a fresh 2-minute cycle.
  ///
  /// This is a manual timing correction. It records an append-only
  /// [DruckphaseNeustart] event, starts no new Reanimationsabschnitt, and
  /// leaves the medication Zeitfenster untouched.
  void restartDruckphase() {
    _requireLaufend();
    if (_phase != Reanimationsphase.druckphase) {
      throw StateError('only the Druckphase can be restarted');
    }

    _druckphaseNeustarts.add(DruckphaseNeustart(zeitpunkt: _elapsedOffset));
    _resetCompressionCycle();
  }

  void _resetCompressionCycle() {
    _compressionCycleStartOffset = _monotonicNow();
    _compressionRemainingAtPause = Duration.zero;
  }

  void _updateAdrenalinGabeFaelligkeit() {
    if (_adrenalinGaben.isNotEmpty) {
      _ersteAdrenalinGabeFaellig = false;
      return;
    }

    final ergebnis = _adrenalinAusloesendesErgebnis;
    _ersteAdrenalinGabeFaellig = switch (ergebnis?.kategorie) {
      RhythmusanalyseKategorie.nichtSchockbar => true,
      RhythmusanalyseKategorie.schockbar =>
        _schocks.length >= leitlinienprofil.adrenalinErsteGabeNachSchock,
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

  /// Records a temperature in degrees Celsius.
  void recordTemperatur(double celsius, {String? notiz}) {
    _requireOpen();
    if (!celsius.isFinite || celsius <= 0) {
      throw ArgumentError.value(celsius, 'celsius', 'must be greater than 0');
    }
    _messwerte.add(
      TemperaturMesswert(
        zeitpunkt: _elapsedOffset,
        celsius: celsius,
        notiz: _normalizeNotiz(notiz),
      ),
    );
  }

  /// Records a blood sugar value in mg/dL.
  void recordBlutzucker(int mgDl, {String? notiz}) {
    _requireOpen();
    if (mgDl <= 0) {
      throw ArgumentError.value(mgDl, 'mgDl', 'must be greater than 0');
    }
    _messwerte.add(
      BlutzuckerMesswert(
        zeitpunkt: _elapsedOffset,
        mgDl: mgDl,
        notiz: _normalizeNotiz(notiz),
      ),
    );
  }

  /// Records a blood pressure in mmHg.
  void recordBlutdruck({
    required int systolisch,
    required int diastolisch,
    String? notiz,
  }) {
    _requireOpen();
    if (systolisch <= 0 || diastolisch <= 0 || systolisch <= diastolisch) {
      throw ArgumentError(
        'systolisch must be greater than diastolisch and both must be positive',
      );
    }
    _messwerte.add(
      BlutdruckMesswert(
        zeitpunkt: _elapsedOffset,
        systolisch: systolisch,
        diastolisch: diastolisch,
        notiz: _normalizeNotiz(notiz),
      ),
    );
  }

  /// Records a heart rate in beats per minute.
  void recordHerzfrequenz(int proMinute, {String? notiz}) {
    _requireOpen();
    if (proMinute <= 0) {
      throw ArgumentError.value(
        proMinute,
        'proMinute',
        'must be greater than 0',
      );
    }
    _messwerte.add(
      HerzfrequenzMesswert(
        zeitpunkt: _elapsedOffset,
        proMinute: proMinute,
        notiz: _normalizeNotiz(notiz),
      ),
    );
  }

  /// Records a free-text note.
  void recordNotiz(String text) {
    _requireOpen();
    final normalized = text.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
    _notizen.add(
      ReanimationsfallNotiz(zeitpunkt: _elapsedOffset, text: normalized),
    );
  }

  /// Records a skipped Rhythmusanalyse and starts a fresh Druckphase.
  void skipRhythmusanalyse() {
    _requireLaufend();
    _requireAnalysephase();
    _uebersprungeneRhythmusanalysen.add(
      RhythmusanalyseUeberspringung(zeitpunkt: _elapsedOffset),
    );
    _startNextDruckphase();
  }

  /// Records ROSC, ends the current Reanimationsabschnitt, and stops the
  /// arrest timers without closing the Reanimationsfall.
  void recordRosc() {
    _requireLaufend();
    _recordRosc();
  }

  /// Records a Reanimationswiederbeginn and starts a fresh Druckphase.
  void resumeResuscitation() {
    if (_zustand != ReanimationsfallZustand.rosc) {
      throw StateError('not in the ROSC state');
    }

    final now = _monotonicNow();
    final offset = now - _monotonicStartOffset;
    _wiederbeginnEreignisse.add(Reanimationswiederbeginn(zeitpunkt: offset));
    _abschnitte.add(
      Reanimationsabschnitt(index: _abschnitte.length, start: offset),
    );
    _zustand = ReanimationsfallZustand.laufend;
    _resetAfterArrest();
    _resetCompressionCycle();
  }

  /// Ends the Reanimationsfall with a reason.
  void endReanimationsfall(Beendigungsgrund grund) {
    if (_zustand == ReanimationsfallZustand.beendet ||
        _zustand == ReanimationsfallZustand.verworfen) {
      throw StateError('the Reanimationsfall has already ended');
    }

    final offset = _monotonicNow() - _monotonicStartOffset;
    if (_zustand == ReanimationsfallZustand.laufend) {
      _closeCurrentAbschnitt(offset);
    }
    _ende = ReanimationsfallEnde(zeitpunkt: offset, grund: grund);
    _zustand = ReanimationsfallZustand.beendet;
    _resetAfterArrest();
  }

  /// Marks the Reanimationsfall as Verworfen and stops the arrest timers.
  ///
  /// The case stays in the local Einsatzlog; this command never deletes it.
  void discardReanimationsfall() {
    if (_zustand == ReanimationsfallZustand.beendet ||
        _zustand == ReanimationsfallZustand.verworfen) {
      throw StateError('the Reanimationsfall has already ended');
    }

    final offset = _monotonicNow() - _monotonicStartOffset;
    if (_zustand == ReanimationsfallZustand.laufend) {
      _closeCurrentAbschnitt(offset);
    }
    _verworfenAm = offset;
    _zustand = ReanimationsfallZustand.verworfen;
    _resetAfterArrest();
  }

  void _recordRosc() {
    final offset = _monotonicNow() - _monotonicStartOffset;
    _roscEreignisse.add(RoscEreignis(zeitpunkt: offset));
    _closeCurrentAbschnitt(offset);
    _zustand = ReanimationsfallZustand.rosc;
    _resetAfterArrest();
  }

  void _resetAfterArrest() {
    _phase = Reanimationsphase.druckphase;
    _analysephaseStartOffset = null;
    _ersteAdrenalinGabeFaellig = false;
  }

  void _closeCurrentAbschnitt(Duration offset) {
    if (_abschnitte.isEmpty) return;
    final current = _abschnitte.last;
    if (current.ende != null) return;
    _abschnitte[_abschnitte.length - 1] = current.copyWith(ende: offset);
  }

  ReanimationsfallSnapshot snapshot() {
    final now = _monotonicNow();
    final elapsed = now - _monotonicStartOffset;
    final cycle = leitlinienprofil.compressionCycle;
    final isLaufend = _zustand == ReanimationsfallZustand.laufend;
    final isDruckphase = isLaufend && _phase == Reanimationsphase.druckphase;
    final cycleElapsed = now - _compressionCycleStartOffset;
    final isRhythmusanalyseDue = isDruckphase && cycleElapsed >= cycle;
    final compressionRemaining = !isLaufend
        ? Duration.zero
        : isDruckphase
        ? (isRhythmusanalyseDue ? Duration.zero : cycle - cycleElapsed)
        : _compressionRemainingAtPause;
    final rhythmusanalyseOverdue = isRhythmusanalyseDue
        ? cycleElapsed - cycle
        : Duration.zero;

    final analysephaseStart = _analysephaseStartOffset;
    final pauseDuration =
        isLaufend &&
            _phase == Reanimationsphase.analysephase &&
            analysephaseStart != null
        ? now - analysephaseStart
        : Duration.zero;
    final pauseTarget = leitlinienprofil.pauseTarget;
    final isPauseOverdue = isLaufend && pauseDuration > pauseTarget;
    final cprDauer = _abschnitte.fold(
      Duration.zero,
      (sum, abschnitt) => sum + abschnitt.dauerBis(elapsed),
    );

    final letzteAdrenalinGabe = _adrenalinGaben.isEmpty
        ? null
        : _adrenalinGaben.last;
    final adrenalinSeitLetzterGabe = letzteAdrenalinGabe == null
        ? null
        : elapsed - letzteAdrenalinGabe.zeitpunkt;
    final adrenalinZeitfensterZustand = letzteAdrenalinGabe == null
        ? AdrenalinZeitfensterZustand.keine
        : _adrenalinZustand(adrenalinSeitLetzterGabe!);
    final letzteAmiodaronGabe = _amiodaronGaben.isEmpty
        ? null
        : _amiodaronGaben.last;

    return ReanimationsfallSnapshot(
      zustand: _zustand,
      phase: _phase,
      leitlinienprofil: leitlinienprofil,
      vibrationEnabled: vibrationEnabled,
      soundEnabled: soundEnabled,
      startzeit: startzeit,
      reanimationsdauer: elapsed,
      cprDauer: cprDauer,
      abschnitte: List.unmodifiable(_abschnitte),
      roscEreignisse: List.unmodifiable(_roscEreignisse),
      wiederbeginnEreignisse: List.unmodifiable(_wiederbeginnEreignisse),
      ende: _ende,
      verworfenAm: _verworfenAm,
      compressionRemaining: compressionRemaining,
      rhythmusanalyseOverdue: rhythmusanalyseOverdue,
      isRhythmusanalyseDue: isRhythmusanalyseDue,
      pauseDuration: pauseDuration,
      isPauseOverdue: isPauseOverdue,
      rhythmusanalyseEintraege: List.unmodifiable(_rhythmusanalyseEintraege),
      druckphaseNeustarts: List.unmodifiable(_druckphaseNeustarts),
      messwerte: List.unmodifiable(_messwerte),
      notizen: List.unmodifiable(_notizen),
      uebersprungeneRhythmusanalysen: List.unmodifiable(
        _uebersprungeneRhythmusanalysen,
      ),
      schocks: List.unmodifiable(_schocks),
      adrenalinGaben: List.unmodifiable(_adrenalinGaben),
      adrenalinSeitLetzterGabe: adrenalinSeitLetzterGabe,
      adrenalinZeitfensterZustand: adrenalinZeitfensterZustand,
      istErsteAdrenalinGabeFaellig: isLaufend && _ersteAdrenalinGabeFaellig,
      amiodaronGaben: List.unmodifiable(_amiodaronGaben),
      letzteAmiodaronGabe: letzteAmiodaronGabe,
      amiodaronHinweis: isLaufend
          ? _amiodaronHinweis()
          : AmiodaronHinweis.keine,
    );
  }

  /// The contextual Amiodaron hint for the current Schock count.
  AmiodaronHinweis _amiodaronHinweis() {
    if (_amiodaronGaben.length >= 2) return AmiodaronHinweis.keine;

    final schockAnzahl = _schocks.length;
    if (_amiodaronGaben.isEmpty) {
      return schockAnzahl >= leitlinienprofil.amiodaronErsteGabeNachSchock
          ? AmiodaronHinweis.ersteGabe
          : AmiodaronHinweis.keine;
    }

    return schockAnzahl >= leitlinienprofil.amiodaronZweiteGabeNachSchock
        ? AmiodaronHinweis.zweiteGabe
        : AmiodaronHinweis.keine;
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

  void _requireLaufend() {
    if (_zustand != ReanimationsfallZustand.laufend) {
      throw StateError('the Reanimationsfall is not running');
    }
  }

  void _requireOpen() {
    if (_zustand == ReanimationsfallZustand.beendet ||
        _zustand == ReanimationsfallZustand.verworfen) {
      throw StateError('the Reanimationsfall is closed');
    }
  }

  Duration get _elapsedOffset => _monotonicNow() - _monotonicStartOffset;

  /// The serializable state used by the local store.
  ReanimationsfallState exportState() {
    final analysephaseStart = _analysephaseStartOffset;

    return ReanimationsfallState(
      id: id,
      startzeit: startzeit,
      startzeitUtc: startzeitUtc,
      utcOffsetMinutes: utcOffsetMinutes,
      leitlinienprofil: leitlinienprofil,
      vibrationEnabled: vibrationEnabled,
      soundEnabled: soundEnabled,
      zustand: _zustand,
      phase: _phase,
      compressionCycleStartOffset:
          _compressionCycleStartOffset - _monotonicStartOffset,
      compressionRemainingAtPause: _compressionRemainingAtPause,
      analysephaseStartOffset: analysephaseStart == null
          ? null
          : analysephaseStart - _monotonicStartOffset,
      adrenalinAusloesendesErgebnis: _adrenalinAusloesendesErgebnis,
      schocks: List.unmodifiable(_schocks),
      adrenalinGaben: List.unmodifiable(_adrenalinGaben),
      amiodaronGaben: List.unmodifiable(_amiodaronGaben),
      uebersprungeneRhythmusanalysen: List.unmodifiable(
        _uebersprungeneRhythmusanalysen,
      ),
      rhythmusanalyseEintraege: List.unmodifiable(_rhythmusanalyseEintraege),
      druckphaseNeustarts: List.unmodifiable(_druckphaseNeustarts),
      messwerte: List.unmodifiable(_messwerte),
      notizen: List.unmodifiable(_notizen),
      roscEreignisse: List.unmodifiable(_roscEreignisse),
      wiederbeginnEreignisse: List.unmodifiable(_wiederbeginnEreignisse),
      abschnitte: List.unmodifiable(_abschnitte),
      ende: _ende,
      verworfenAm: _verworfenAm,
    );
  }

  void _startNextDruckphase() {
    _phase = Reanimationsphase.druckphase;
    _resetCompressionCycle();
    _analysephaseStartOffset = null;
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
    required this.zustand,
    required this.phase,
    required this.leitlinienprofil,
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.startzeit,
    required this.reanimationsdauer,
    required this.cprDauer,
    required this.abschnitte,
    required this.roscEreignisse,
    required this.wiederbeginnEreignisse,
    required this.ende,
    required this.verworfenAm,
    required this.compressionRemaining,
    required this.rhythmusanalyseOverdue,
    required this.isRhythmusanalyseDue,
    required this.pauseDuration,
    required this.isPauseOverdue,
    required this.rhythmusanalyseEintraege,
    required this.druckphaseNeustarts,
    required this.messwerte,
    required this.notizen,
    required this.uebersprungeneRhythmusanalysen,
    required this.schocks,
    required this.adrenalinGaben,
    required this.adrenalinSeitLetzterGabe,
    required this.adrenalinZeitfensterZustand,
    required this.istErsteAdrenalinGabeFaellig,
    required this.amiodaronGaben,
    required this.letzteAmiodaronGabe,
    required this.amiodaronHinweis,
  });

  /// Whether the case is running, interrupted by ROSC, or ended.
  final ReanimationsfallZustand zustand;

  final Reanimationsphase phase;
  final Leitlinienprofil leitlinienprofil;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final DateTime startzeit;

  /// The time since the Startzeit, including ROSC pauses.
  final Duration reanimationsdauer;

  /// The total CPR time across all Reanimationsabschnitte.
  final Duration cprDauer;

  /// Every Reanimationsabschnitt, including the current one.
  final List<Reanimationsabschnitt> abschnitte;

  /// Every recorded ROSC event.
  final List<RoscEreignis> roscEreignisse;

  /// Every recorded Reanimationswiederbeginn.
  final List<Reanimationswiederbeginn> wiederbeginnEreignisse;

  /// The end of the Reanimationsfall, if it has ended.
  final ReanimationsfallEnde? ende;

  /// The time the Reanimationsfall was marked as Verworfen, if it was.
  final Duration? verworfenAm;

  final Duration compressionRemaining;

  /// How long the Rhythmusanalyse has been due; zero before 0:00.
  final Duration rhythmusanalyseOverdue;
  final bool isRhythmusanalyseDue;

  /// How long the Analysephase has paused the compression timer.
  final Duration pauseDuration;

  final bool isPauseOverdue;

  /// Every recorded Rhythmusanalyse result, including previous cycles.
  final List<RhythmusanalyseEintrag> rhythmusanalyseEintraege;

  /// Every manual reset of the Druckphase.
  final List<DruckphaseNeustart> druckphaseNeustarts;

  /// Every recorded Messwert.
  final List<Messwert> messwerte;

  /// Every recorded free-text note.
  final List<ReanimationsfallNotiz> notizen;

  /// Every skipped Rhythmusanalyse.
  final List<RhythmusanalyseUeberspringung> uebersprungeneRhythmusanalysen;

  /// Every recorded Schock.
  final List<SchockEreignis> schocks;

  /// Every recorded Adrenalin dose.
  final List<AdrenalinGabe> adrenalinGaben;

  /// The time since the last Adrenalin dose, or null before the first dose.
  final Duration? adrenalinSeitLetzterGabe;

  /// The state of the current Adrenalin Zeitfenster.
  final AdrenalinZeitfensterZustand adrenalinZeitfensterZustand;

  /// Whether the first Adrenalin dose is clinically due.
  final bool istErsteAdrenalinGabeFaellig;

  /// Every recorded Amiodaron dose.
  final List<AmiodaronGabe> amiodaronGaben;

  /// The most recent Amiodaron dose, if any.
  final AmiodaronGabe? letzteAmiodaronGabe;

  /// The contextual Amiodaron hint, or `keine` when no dose is suggested.
  final AmiodaronHinweis amiodaronHinweis;

  /// Whether the case is still running.
  bool get istLaufend => zustand == ReanimationsfallZustand.laufend;

  /// Whether the case is interrupted by ROSC.
  bool get istRosc => zustand == ReanimationsfallZustand.rosc;

  /// Whether the current Druckphase can be restarted manually.
  bool get kannDruckphaseNeuStarten =>
      istLaufend && phase == Reanimationsphase.druckphase;

  /// Whether the case has ended.
  bool get istBeendet => zustand == ReanimationsfallZustand.beendet;

  /// Whether the case was marked as Verworfen.
  bool get istVerworfen => zustand == ReanimationsfallZustand.verworfen;

  /// The most recent Adrenalin dose, if any.
  AdrenalinGabe? get letzteAdrenalinGabe {
    if (adrenalinGaben.isEmpty) return null;
    return adrenalinGaben.last;
  }

  /// The number of recorded Schocks.
  int get schockAnzahl => schocks.length;

  /// The most recently skipped Rhythmusanalyse, if any.
  RhythmusanalyseUeberspringung? get letzteRhythmusanalyseUeberspringung {
    if (uebersprungeneRhythmusanalysen.isEmpty) return null;
    return uebersprungeneRhythmusanalysen.last;
  }
}

/// The serializable state of a Reanimationsfall.
///
/// Event times and phase offsets are relative to the Startzeit so that the
/// state can be restored with a fresh monotonic clock.
class ReanimationsfallState {
  const ReanimationsfallState({
    required this.id,
    required this.startzeit,
    required this.startzeitUtc,
    required this.utcOffsetMinutes,
    required this.leitlinienprofil,
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.zustand,
    required this.phase,
    required this.compressionCycleStartOffset,
    required this.compressionRemainingAtPause,
    required this.analysephaseStartOffset,
    required this.adrenalinAusloesendesErgebnis,
    required this.schocks,
    required this.adrenalinGaben,
    required this.amiodaronGaben,
    required this.uebersprungeneRhythmusanalysen,
    required this.rhythmusanalyseEintraege,
    required this.druckphaseNeustarts,
    required this.messwerte,
    required this.notizen,
    required this.roscEreignisse,
    required this.wiederbeginnEreignisse,
    required this.abschnitte,
    required this.ende,
    required this.verworfenAm,
  });

  final String id;
  final DateTime startzeit;
  final DateTime startzeitUtc;
  final int utcOffsetMinutes;
  final Leitlinienprofil leitlinienprofil;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final ReanimationsfallZustand zustand;
  final Reanimationsphase phase;
  final Duration compressionCycleStartOffset;
  final Duration compressionRemainingAtPause;
  final Duration? analysephaseStartOffset;
  final RhythmusanalyseErgebnis? adrenalinAusloesendesErgebnis;
  final List<SchockEreignis> schocks;
  final List<AdrenalinGabe> adrenalinGaben;
  final List<AmiodaronGabe> amiodaronGaben;
  final List<RhythmusanalyseUeberspringung> uebersprungeneRhythmusanalysen;
  final List<RhythmusanalyseEintrag> rhythmusanalyseEintraege;
  final List<DruckphaseNeustart> druckphaseNeustarts;
  final List<Messwert> messwerte;
  final List<ReanimationsfallNotiz> notizen;
  final List<RoscEreignis> roscEreignisse;
  final List<Reanimationswiederbeginn> wiederbeginnEreignisse;
  final List<Reanimationsabschnitt> abschnitte;
  final ReanimationsfallEnde? ende;
  final Duration? verworfenAm;
}
