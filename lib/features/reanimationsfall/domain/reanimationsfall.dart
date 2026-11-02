import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/ereignisse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/protokoll.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';

export 'package:hp_cpr/features/reanimationsfall/domain/ereignisse.dart';
export 'package:hp_cpr/features/reanimationsfall/domain/protokoll.dart';

/// The current part of a Reanimationsfall.
enum Reanimationsphase { druckphase, analysephase }

/// The lifecycle state of a Reanimationsfall.
enum ReanimationsfallZustand { laufend, rosc, beendet, verworfen }

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
    this.demoMode = false,
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
       demoMode = state.demoMode,
       startzeit = state.startzeit,
       startzeitUtc = state.startzeitUtc,
       utcOffsetMinutes = state.utcOffsetMinutes {
    _zustand = state.zustand;
    _phase = state.phase;
    _demoOffset = state.demoOffset;
    _nextEreignisId = state.nextEreignisId;
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
    _korrekturen.addAll(state.korrekturen);
    _updateAdrenalinGabeFaelligkeit();
  }

  final AppClock _clock;
  Duration _monotonicAdjustment = Duration.zero;
  Duration _demoOffset = Duration.zero;

  final Duration _monotonicStartOffset;

  /// The identity of this Reanimationsfall in the local store.
  final String id;

  /// The Leitlinienprofil snapshotted when the Reanimationsfall started.
  final Leitlinienprofil leitlinienprofil;

  /// Whether vibration was enabled when the Reanimationsfall started.
  final bool vibrationEnabled;

  /// Whether sound was enabled when the Reanimationsfall started.
  final bool soundEnabled;

  /// Whether the Reanimationsfall was started in Demo-Modus.
  final bool demoMode;

  /// The corrected wall-clock time zero of the Reanimationsfall.
  final DateTime startzeit;

  /// The time zero as an absolute instant.
  final DateTime startzeitUtc;

  /// The device's UTC offset when the Reanimationsfall started.
  final int utcOffsetMinutes;

  ReanimationsfallZustand _zustand = ReanimationsfallZustand.laufend;
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
  final List<ProtokollKorrektur> _korrekturen = [];
  int _nextEreignisId = 0;
  RhythmusanalyseErgebnis? _adrenalinAusloesendesErgebnis;
  bool _ersteAdrenalinGabeFaellig = false;

  /// The monotonic timeline shifted by recovered wall-clock intervals and
  /// Demo-Modus time.
  Duration _monotonicNow() =>
      _clock.monotonicNow() + _monotonicAdjustment + _demoOffset;

  Duration get _elapsedOffset => _monotonicNow() - _monotonicStartOffset;

  String _newEreignisId() => 'e${_nextEreignisId++}';

  /// Recovers time that passed while the device was suspended.
  ///
  /// A monotonic clock can stop during device sleep. On resume, a larger
  /// wall-clock delta is trusted to restore the missing interval. The wall
  /// clock never shortens the Reanimationsdauer, so a backwards clock change
  /// is ignored. Demo-Modus time is excluded so a simulated advance is not
  /// mistaken for device sleep.
  void reconcileWithWallClock() {
    final wallElapsed = _clock.now().toUtc().difference(startzeitUtc);
    final realElapsed =
        _clock.monotonicNow() + _monotonicAdjustment - _monotonicStartOffset;
    if (wallElapsed > realElapsed) {
      _monotonicAdjustment += wallElapsed - realElapsed;
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
      SchockEreignis(
        id: _newEreignisId(),
        zeitpunkt: _elapsedOffset,
        energieJoule: energieJoule,
      ),
    );
    // The shock count still feeds the derived Adrenalin and Amiodaron hints.
    _updateAdrenalinGabeFaelligkeit();
  }

  /// Records an Adrenalin dose and starts a new Zeitfenster.
  void recordAdrenalin() {
    _requireLaufend();
    _adrenalinGaben.add(
      AdrenalinGabe(
        id: _newEreignisId(),
        zeitpunkt: _monotonicNow() - _monotonicStartOffset,
      ),
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
        id: _newEreignisId(),
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
    final id = _newEreignisId();
    _adrenalinAusloesendesErgebnis = ergebnis;
    _rhythmusanalyseEintraege.add(
      RhythmusanalyseEintrag(
        id: id,
        zeitpunkt: _elapsedOffset,
        ergebnis: ergebnis,
      ),
    );
    _updateAdrenalinGabeFaelligkeit();

    if (ergebnis == RhythmusanalyseErgebnis.rosc) {
      _recordRosc(rhythmusanalyseId: id);
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

    _druckphaseNeustarts.add(
      DruckphaseNeustart(id: _newEreignisId(), zeitpunkt: _elapsedOffset),
    );
    _resetCompressionCycle();
  }

  void _resetCompressionCycle() {
    _compressionCycleStartOffset = _monotonicNow();
    _compressionRemainingAtPause = Duration.zero;
  }

  /// Advances the simulated case timeline in Demo-Modus.
  ///
  /// This is a test aid: it moves every derived timer forward by [amount]
  /// without recording a clinical event. It works while the case is running
  /// or interrupted by ROSC, and only for a case started in Demo-Modus.
  void advanceDemoTime(Duration amount) {
    if (!demoMode) {
      throw StateError('the Reanimationsfall is not in Demo-Modus');
    }
    _requireOpen();
    if (amount <= Duration.zero) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    _demoOffset += amount;
  }

  void _updateAdrenalinGabeFaelligkeit() {
    final states = _korrekturZustaende();
    final gaben = _effektiveAdrenalinGaben(states);
    if (gaben.isNotEmpty) {
      _ersteAdrenalinGabeFaellig = false;
      return;
    }

    final ergebnis = _adrenalinAusloesendesErgebnis;
    _ersteAdrenalinGabeFaellig = switch (ergebnis?.kategorie) {
      RhythmusanalyseKategorie.nichtSchockbar => true,
      RhythmusanalyseKategorie.schockbar =>
        _effektiveSchocks(states).length >=
            leitlinienprofil.adrenalinErsteGabeNachSchock,
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
        id: _newEreignisId(),
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
        id: _newEreignisId(),
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
        id: _newEreignisId(),
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
        id: _newEreignisId(),
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
      ReanimationsfallNotiz(
        id: _newEreignisId(),
        zeitpunkt: _elapsedOffset,
        text: normalized,
      ),
    );
  }

  /// Records a skipped Rhythmusanalyse and starts a fresh Druckphase.
  void skipRhythmusanalyse() {
    _requireLaufend();
    _requireAnalysephase();
    _uebersprungeneRhythmusanalysen.add(
      RhythmusanalyseUeberspringung(
        id: _newEreignisId(),
        zeitpunkt: _elapsedOffset,
      ),
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
    _wiederbeginnEreignisse.add(
      Reanimationswiederbeginn(id: _newEreignisId(), zeitpunkt: offset),
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

    final offset = _elapsedOffset;
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

    _verworfenAm = _elapsedOffset;
    _zustand = ReanimationsfallZustand.verworfen;
    _resetAfterArrest();
  }

  void _recordRosc({String? rhythmusanalyseId}) {
    _roscEreignisse.add(
      RoscEreignis(
        id: _newEreignisId(),
        zeitpunkt: _elapsedOffset,
        rhythmusanalyseId: rhythmusanalyseId,
      ),
    );
    _zustand = ReanimationsfallZustand.rosc;
    _resetAfterArrest();
  }

  void _resetAfterArrest() {
    _phase = Reanimationsphase.druckphase;
    _analysephaseStartOffset = null;
    _ersteAdrenalinGabeFaellig = false;
  }

  /// Applies an append-only correction to one Protokoll entry.
  void applyProtokollKorrektur(ProtokollKorrektur korrektur) {
    final ref = korrektur.ziel;
    if (ref.typ.istLebenszyklus) {
      throw StateError('lifecycle entries are read-only');
    }
    final original = _findOriginal(ref);
    if (original == null) {
      throw ArgumentError.value(ref, 'ziel', 'unknown Protokoll entry');
    }
    _requireKorrekturScope(ref.typ);

    if (korrektur is ProtokollEintragEntfernt) {
      _requireNotRemoved(ref);
      _requireNotPairedRoscRhythmusanalyse(ref);
      _appendKorrektur(korrektur);
      _appendPairRemoval(ref);
      if (ref.typ == ProtokollEintragTyp.schock ||
          ref.typ == ProtokollEintragTyp.adrenalin) {
        _updateAdrenalinGabeFaelligkeit();
      }
      return;
    }
    if (korrektur is ProtokollEintragWiederhergestellt) {
      _requireRemoved(ref);
      _requireNotPairedRoscRhythmusanalyse(ref);
      _appendKorrektur(korrektur);
      _appendPairRestore(ref);
      if (ref.typ == ProtokollEintragTyp.schock ||
          ref.typ == ProtokollEintragTyp.adrenalin) {
        _updateAdrenalinGabeFaelligkeit();
      }
      return;
    }

    _requireNotRemoved(ref);

    switch (korrektur) {
      case SchockKorrigiert(:final zeitpunkt, :final energieJoule):
        _requireTyp(ref, ProtokollEintragTyp.schock);
        _requireValidEnergie(energieJoule);
        _requireValidKorrekturZeitpunkt(ref.typ, zeitpunkt, ref.id);
      case AdrenalinKorrigiert(:final zeitpunkt, :final dosisMg):
        _requireTyp(ref, ProtokollEintragTyp.adrenalin);
        _requireValidDosis(dosisMg);
        _requireValidKorrekturZeitpunkt(ref.typ, zeitpunkt, ref.id);
      case AmiodaronKorrigiert(:final zeitpunkt, :final dosisMg):
        _requireTyp(ref, ProtokollEintragTyp.amiodaron);
        _requireValidDosis(dosisMg);
        _requireValidKorrekturZeitpunkt(ref.typ, zeitpunkt, ref.id);
      case MesswertKorrigiert(:final ersatz):
        _requireTyp(ref, ProtokollEintragTyp.messwert);
        _requireSameMesswertTyp(original, ersatz);
        _requireValidMesswert(ersatz);
        _requireValidKorrekturZeitpunkt(ref.typ, ersatz.zeitpunkt, ref.id);
      case NotizKorrigiert(:final zeitpunkt, :final text):
        _requireTyp(ref, ProtokollEintragTyp.notiz);
        _requireValidNotiz(text);
        _requireValidKorrekturZeitpunkt(ref.typ, zeitpunkt, ref.id);
      case RhythmusanalyseKorrigiert(:final zeitpunkt, :final ergebnis):
        _requireTyp(ref, ProtokollEintragTyp.rhythmusanalyse);
        if (_isPairedRoscRhythmusanalyse(ref.id)) {
          throw StateError('ROSC is corrected through the ROSC entry');
        }
        if (ergebnis == RhythmusanalyseErgebnis.rosc) {
          throw ArgumentError.value(
            ergebnis,
            'ergebnis',
            'ROSC is corrected through the ROSC entry',
          );
        }
        _requireValidKorrekturZeitpunkt(ref.typ, zeitpunkt, ref.id);
      case ZeitpunktKorrigiert(:final zeitpunkt):
        if (ref.typ != ProtokollEintragTyp.ueberspringung &&
            ref.typ != ProtokollEintragTyp.druckphaseNeustart &&
            ref.typ != ProtokollEintragTyp.wiederbeginn) {
          throw ArgumentError.value(
            ref.typ,
            'ziel.typ',
            'time-only corrections do not apply to this entry',
          );
        }
        _requireValidKorrekturZeitpunkt(ref.typ, zeitpunkt, ref.id);
      case RoscKorrigiert(:final zeitpunkt):
        _requireTyp(ref, ProtokollEintragTyp.rosc);
        _requireValidKorrekturZeitpunkt(ref.typ, zeitpunkt, ref.id);
      case ProtokollEintragEntfernt() || ProtokollEintragWiederhergestellt():
        throw StateError('unreachable');
    }

    _appendKorrektur(korrektur);
    if (ref.typ == ProtokollEintragTyp.rosc) {
      _appendRoscPairTime(korrektur);
    }
    if (ref.typ == ProtokollEintragTyp.schock ||
        ref.typ == ProtokollEintragTyp.adrenalin) {
      _updateAdrenalinGabeFaelligkeit();
    }
  }

  void _appendKorrektur(ProtokollKorrektur korrektur) {
    _korrekturen.add(korrektur);
  }

  void _appendRoscPairTime(ProtokollKorrektur korrektur) {
    if (korrektur is! RoscKorrigiert) return;
    final rosc = _findRosc(korrektur.ziel.id);
    final pairId = rosc?.rhythmusanalyseId;
    if (pairId == null) return;
    _korrekturen.add(
      ZeitpunktKorrigiert(
        ziel: ProtokollEintragRef(
          typ: ProtokollEintragTyp.rhythmusanalyse,
          id: pairId,
        ),
        zeitpunkt: korrektur.zeitpunkt,
      ),
    );
  }

  void _appendPairRemoval(ProtokollEintragRef ref) {
    if (ref.typ != ProtokollEintragTyp.rosc) return;
    final rosc = _findRosc(ref.id);
    final pairId = rosc?.rhythmusanalyseId;
    if (pairId == null) return;
    _korrekturen.add(
      ProtokollEintragEntfernt(
        ziel: ProtokollEintragRef(
          typ: ProtokollEintragTyp.rhythmusanalyse,
          id: pairId,
        ),
      ),
    );
  }

  void _appendPairRestore(ProtokollEintragRef ref) {
    if (ref.typ != ProtokollEintragTyp.rosc) return;
    final rosc = _findRosc(ref.id);
    final pairId = rosc?.rhythmusanalyseId;
    if (pairId == null) return;
    _korrekturen.add(
      ProtokollEintragWiederhergestellt(
        ziel: ProtokollEintragRef(
          typ: ProtokollEintragTyp.rhythmusanalyse,
          id: pairId,
        ),
      ),
    );
  }

  bool _isPairedRoscRhythmusanalyse(String id) =>
      _roscEreignisse.any((rosc) => rosc.rhythmusanalyseId == id);

  void _requireNotPairedRoscRhythmusanalyse(ProtokollEintragRef ref) {
    if (ref.typ == ProtokollEintragTyp.rhythmusanalyse &&
        _isPairedRoscRhythmusanalyse(ref.id)) {
      throw StateError('ROSC is corrected through the ROSC entry');
    }
  }

  RoscEreignis? _findRosc(String id) {
    for (final rosc in _roscEreignisse) {
      if (rosc.id == id) return rosc;
    }
    return null;
  }

  Object? _findOriginal(ProtokollEintragRef ref) {
    return switch (ref.typ) {
      ProtokollEintragTyp.schock => _findById<SchockEreignis>(
        _schocks,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.adrenalin => _findById<AdrenalinGabe>(
        _adrenalinGaben,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.amiodaron => _findById<AmiodaronGabe>(
        _amiodaronGaben,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.messwert => _findById<Messwert>(
        _messwerte,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.notiz => _findById<ReanimationsfallNotiz>(
        _notizen,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.rhythmusanalyse => _findById<RhythmusanalyseEintrag>(
        _rhythmusanalyseEintraege,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.ueberspringung =>
        _findById<RhythmusanalyseUeberspringung>(
          _uebersprungeneRhythmusanalysen,
          ref.id,
          (e) => e.id,
        ),
      ProtokollEintragTyp.druckphaseNeustart => _findById<DruckphaseNeustart>(
        _druckphaseNeustarts,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.rosc => _findById<RoscEreignis>(
        _roscEreignisse,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.wiederbeginn => _findById<Reanimationswiederbeginn>(
        _wiederbeginnEreignisse,
        ref.id,
        (e) => e.id,
      ),
      ProtokollEintragTyp.fallStart ||
      ProtokollEintragTyp.fallEnde ||
      ProtokollEintragTyp.fallVerworfen => null,
    };
  }

  T? _findById<T>(List<T> list, String id, String Function(T) idOf) {
    for (final item in list) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  void _requireKorrekturScope(ProtokollEintragTyp typ) {
    if (_istOffen && typ.istStrukturell) {
      throw StateError(
        'structural Protokoll entries are read-only while the case is open',
      );
    }
  }

  bool get _istOffen =>
      _zustand == ReanimationsfallZustand.laufend ||
      _zustand == ReanimationsfallZustand.rosc;

  void _requireTyp(ProtokollEintragRef ref, ProtokollEintragTyp typ) {
    if (ref.typ != typ) {
      throw ArgumentError.value(ref.typ, 'ziel.typ', 'unexpected entry type');
    }
  }

  void _requireNotRemoved(ProtokollEintragRef ref) {
    if (_korrekturZustaende()[ref]?.entfernt ?? false) {
      throw StateError('the Protokoll entry is removed');
    }
  }

  void _requireRemoved(ProtokollEintragRef ref) {
    if (!(_korrekturZustaende()[ref]?.entfernt ?? false)) {
      throw StateError('the Protokoll entry is not removed');
    }
  }

  void _requireSameMesswertTyp(Object original, Messwert ersatz) {
    if (original is! Messwert || original.typ != ersatz.typ) {
      throw ArgumentError.value(
        ersatz.typ,
        'ersatz.typ',
        'the Messwert type is fixed',
      );
    }
    if (original.id != ersatz.id) {
      throw ArgumentError.value(
        ersatz.id,
        'ersatz.id',
        'the replacement must keep the original id',
      );
    }
  }

  void _requireValidMesswert(Messwert messwert) {
    switch (messwert) {
      case TemperaturMesswert(:final celsius):
        if (!celsius.isFinite || celsius <= 0) {
          throw ArgumentError.value(
            celsius,
            'celsius',
            'must be greater than 0',
          );
        }
      case BlutzuckerMesswert(:final mgDl):
        if (mgDl <= 0) {
          throw ArgumentError.value(mgDl, 'mgDl', 'must be greater than 0');
        }
      case BlutdruckMesswert(:final systolisch, :final diastolisch):
        if (systolisch <= 0 || diastolisch <= 0 || systolisch <= diastolisch) {
          throw ArgumentError(
            'systolisch must be greater than diastolisch and both must be positive',
          );
        }
      case HerzfrequenzMesswert(:final proMinute):
        if (proMinute <= 0) {
          throw ArgumentError.value(
            proMinute,
            'proMinute',
            'must be greater than 0',
          );
        }
    }
  }

  void _requireValidNotiz(String text) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
  }

  void _requireValidDosis(int dosisMg) {
    if (dosisMg <= 0) {
      throw ArgumentError.value(
        dosisMg,
        'dosisMg',
        'must be greater than zero',
      );
    }
  }

  Duration get _maxKorrekturZeitpunkt {
    if (_zustand == ReanimationsfallZustand.beendet) {
      return _ende?.zeitpunkt ?? _elapsedOffset;
    }
    if (_zustand == ReanimationsfallZustand.verworfen) {
      return _verworfenAm ?? _elapsedOffset;
    }
    return _elapsedOffset;
  }

  void _requireValidKorrekturZeitpunkt(
    ProtokollEintragTyp typ,
    Duration zeitpunkt,
    String id,
  ) {
    if (zeitpunkt < Duration.zero || zeitpunkt > _maxKorrekturZeitpunkt) {
      throw ArgumentError.value(
        zeitpunkt,
        'zeitpunkt',
        'must be inside the case',
      );
    }
    if (typ == ProtokollEintragTyp.rosc ||
        typ == ProtokollEintragTyp.wiederbeginn) {
      _requireBetweenStructuralNeighbours(zeitpunkt, id);
    }
  }

  void _requireBetweenStructuralNeighbours(Duration zeitpunkt, String id) {
    final states = _korrekturZustaende();
    final struktur =
        <({String id, Duration original, Duration effective})>[
          for (final rosc in _roscEreignisse)
            if (!(states[_ref(ProtokollEintragTyp.rosc, rosc.id)]?.entfernt ??
                false))
              (
                id: rosc.id,
                original: rosc.zeitpunkt,
                effective: _effektiveRosc(states)
                    .firstWhere((e) => e.id == rosc.id)
                    .zeitpunkt,
              ),
          for (final wiederbeginn in _wiederbeginnEreignisse)
            if (!(states[_ref(
                      ProtokollEintragTyp.wiederbeginn,
                      wiederbeginn.id,
                    )]
                    ?.entfernt ??
                false))
              (
                id: wiederbeginn.id,
                original: wiederbeginn.zeitpunkt,
                effective: _effektiveWiederbeginn(states)
                    .firstWhere((e) => e.id == wiederbeginn.id)
                    .zeitpunkt,
              ),
        ]..sort((a, b) {
          final byTime = a.original.compareTo(b.original);
          return byTime != 0 ? byTime : a.id.compareTo(b.id);
        });

    final index = struktur.indexWhere((eintrag) => eintrag.id == id);
    if (index == -1) return;
    final previous = index > 0 ? struktur[index - 1].effective : Duration.zero;
    final next = index < struktur.length - 1
        ? struktur[index + 1].effective
        : _maxKorrekturZeitpunkt;
    if (zeitpunkt < previous || zeitpunkt > next) {
      throw ArgumentError.value(
        zeitpunkt,
        'zeitpunkt',
        'must stay between the neighbouring structural entries',
      );
    }
  }

  Map<ProtokollEintragRef, _KorrekturZustand> _korrekturZustaende() {
    final states = <ProtokollEintragRef, _KorrekturZustand>{};
    for (final korrektur in _korrekturen) {
      final state = states.putIfAbsent(korrektur.ziel, _KorrekturZustand.new);
      switch (korrektur) {
        case ProtokollEintragEntfernt():
          state.entfernt = true;
        case ProtokollEintragWiederhergestellt():
          state.entfernt = false;
        case SchockKorrigiert() ||
            AdrenalinKorrigiert() ||
            AmiodaronKorrigiert() ||
            MesswertKorrigiert() ||
            NotizKorrigiert() ||
            RhythmusanalyseKorrigiert() ||
            ZeitpunktKorrigiert() ||
            RoscKorrigiert():
          state.letzteKorrektur = korrektur;
          state.hatKorrektur = true;
      }
    }
    return states;
  }

  List<SchockEreignis> _effektiveSchocks(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _schocks)
        if (!(states[_ref(ProtokollEintragTyp.schock, original.id)]?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.schock, original.id)]
              ?.letzteKorrektur) {
            SchockKorrigiert(:final zeitpunkt, :final energieJoule) =>
              SchockEreignis(
                id: original.id,
                zeitpunkt: zeitpunkt,
                energieJoule: energieJoule,
              ),
            _ => original,
          },
    ];
  }

  List<AdrenalinGabe> _effektiveAdrenalinGaben(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _adrenalinGaben)
        if (!(states[_ref(ProtokollEintragTyp.adrenalin, original.id)]
                ?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.adrenalin, original.id)]
              ?.letzteKorrektur) {
            AdrenalinKorrigiert(:final zeitpunkt, :final dosisMg) =>
              AdrenalinGabe(
                id: original.id,
                zeitpunkt: zeitpunkt,
                dosisMg: dosisMg,
              ),
            _ => original,
          },
    ];
  }

  List<AmiodaronGabe> _effektiveAmiodaronGaben(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _amiodaronGaben)
        if (!(states[_ref(ProtokollEintragTyp.amiodaron, original.id)]
                ?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.amiodaron, original.id)]
              ?.letzteKorrektur) {
            AmiodaronKorrigiert(:final zeitpunkt, :final dosisMg) =>
              AmiodaronGabe(
                id: original.id,
                zeitpunkt: zeitpunkt,
                dosisMg: dosisMg,
              ),
            _ => original,
          },
    ];
  }

  List<Messwert> _effektiveMesswerte(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _messwerte)
        if (!(states[_ref(ProtokollEintragTyp.messwert, original.id)]
                ?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.messwert, original.id)]
              ?.letzteKorrektur) {
            MesswertKorrigiert(:final ersatz) => ersatz,
            _ => original,
          },
    ];
  }

  List<ReanimationsfallNotiz> _effektiveNotizen(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _notizen)
        if (!(states[_ref(ProtokollEintragTyp.notiz, original.id)]?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.notiz, original.id)]
              ?.letzteKorrektur) {
            NotizKorrigiert(:final zeitpunkt, :final text) =>
              ReanimationsfallNotiz(
                id: original.id,
                zeitpunkt: zeitpunkt,
                text: text.trim(),
              ),
            _ => original,
          },
    ];
  }

  List<RhythmusanalyseEintrag> _effektiveRhythmusanalysen(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _rhythmusanalyseEintraege)
        if (!(states[_ref(ProtokollEintragTyp.rhythmusanalyse, original.id)]
                ?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.rhythmusanalyse, original.id)]
              ?.letzteKorrektur) {
            RhythmusanalyseKorrigiert(:final zeitpunkt, :final ergebnis) =>
              RhythmusanalyseEintrag(
                id: original.id,
                zeitpunkt: zeitpunkt,
                ergebnis: ergebnis,
              ),
            ZeitpunktKorrigiert(:final zeitpunkt) => RhythmusanalyseEintrag(
              id: original.id,
              zeitpunkt: zeitpunkt,
              ergebnis: original.ergebnis,
            ),
            _ => original,
          },
    ];
  }

  List<RhythmusanalyseUeberspringung> _effektiveUeberspringungen(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _uebersprungeneRhythmusanalysen)
        if (!(states[_ref(ProtokollEintragTyp.ueberspringung, original.id)]
                ?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.ueberspringung, original.id)]
              ?.letzteKorrektur) {
            ZeitpunktKorrigiert(:final zeitpunkt) =>
              RhythmusanalyseUeberspringung(
                id: original.id,
                zeitpunkt: zeitpunkt,
              ),
            _ => original,
          },
    ];
  }

  List<DruckphaseNeustart> _effektiveDruckphaseNeustarts(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _druckphaseNeustarts)
        if (!(states[_ref(ProtokollEintragTyp.druckphaseNeustart, original.id)]
                ?.entfernt ??
            false))
          switch (states[_ref(
                ProtokollEintragTyp.druckphaseNeustart,
                original.id,
              )]
              ?.letzteKorrektur) {
            ZeitpunktKorrigiert(:final zeitpunkt) => DruckphaseNeustart(
              id: original.id,
              zeitpunkt: zeitpunkt,
            ),
            _ => original,
          },
    ];
  }

  List<RoscEreignis> _effektiveRosc(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _roscEreignisse)
        if (!(states[_ref(ProtokollEintragTyp.rosc, original.id)]?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.rosc, original.id)]
              ?.letzteKorrektur) {
            RoscKorrigiert(:final zeitpunkt) => RoscEreignis(
              id: original.id,
              zeitpunkt: zeitpunkt,
              rhythmusanalyseId: original.rhythmusanalyseId,
            ),
            _ => original,
          },
    ];
  }

  List<Reanimationswiederbeginn> _effektiveWiederbeginn(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return [
      for (final original in _wiederbeginnEreignisse)
        if (!(states[_ref(ProtokollEintragTyp.wiederbeginn, original.id)]
                ?.entfernt ??
            false))
          switch (states[_ref(ProtokollEintragTyp.wiederbeginn, original.id)]
              ?.letzteKorrektur) {
            ZeitpunktKorrigiert(:final zeitpunkt) => Reanimationswiederbeginn(
              id: original.id,
              zeitpunkt: zeitpunkt,
            ),
            _ => original,
          },
    ];
  }

  ProtokollEintragRef _ref(ProtokollEintragTyp typ, String id) =>
      ProtokollEintragRef(typ: typ, id: id);

  ReanimationsfallSnapshot snapshot() {
    final states = _korrekturZustaende();
    final schocks = _effektiveSchocks(states);
    final adrenalinGaben = _effektiveAdrenalinGaben(states);
    final amiodaronGaben = _effektiveAmiodaronGaben(states);
    final messwerte = _effektiveMesswerte(states);
    final notizen = _effektiveNotizen(states);
    final rhythmusanalysen = _effektiveRhythmusanalysen(states);
    final ueberspringungen = _effektiveUeberspringungen(states);
    final druckphaseNeustarts = _effektiveDruckphaseNeustarts(states);
    final roscEreignisse = _effektiveRosc(states);
    final wiederbeginnEreignisse = _effektiveWiederbeginn(states);

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

    final abschnitte = _deriveAbschnitte(
      roscEreignisse: roscEreignisse,
      wiederbeginnEreignisse: wiederbeginnEreignisse,
    );
    final cprDauer = abschnitte.fold(
      Duration.zero,
      (sum, abschnitt) => sum + abschnitt.dauerBis(elapsed),
    );

    final letzteAdrenalinGabe = adrenalinGaben.isEmpty
        ? null
        : adrenalinGaben.last;
    final adrenalinSeitLetzterGabe = letzteAdrenalinGabe == null
        ? null
        : elapsed - letzteAdrenalinGabe.zeitpunkt;
    final adrenalinZeitfensterZustand = letzteAdrenalinGabe == null
        ? AdrenalinZeitfensterZustand.keine
        : _adrenalinZustand(adrenalinSeitLetzterGabe!);
    final letzteAmiodaronGabe = amiodaronGaben.isEmpty
        ? null
        : amiodaronGaben.last;

    return ReanimationsfallSnapshot(
      zustand: _zustand,
      phase: _phase,
      leitlinienprofil: leitlinienprofil,
      vibrationEnabled: vibrationEnabled,
      soundEnabled: soundEnabled,
      demoMode: demoMode,
      startzeit: startzeit,
      reanimationsdauer: elapsed,
      cprDauer: cprDauer,
      abschnitte: List.unmodifiable(abschnitte),
      roscEreignisse: List.unmodifiable(roscEreignisse),
      wiederbeginnEreignisse: List.unmodifiable(wiederbeginnEreignisse),
      ende: _ende,
      verworfenAm: _verworfenAm,
      compressionRemaining: compressionRemaining,
      rhythmusanalyseOverdue: rhythmusanalyseOverdue,
      isRhythmusanalyseDue: isRhythmusanalyseDue,
      pauseDuration: pauseDuration,
      isPauseOverdue: isPauseOverdue,
      rhythmusanalyseEintraege: List.unmodifiable(rhythmusanalysen),
      druckphaseNeustarts: List.unmodifiable(druckphaseNeustarts),
      messwerte: List.unmodifiable(messwerte),
      notizen: List.unmodifiable(notizen),
      uebersprungeneRhythmusanalysen: List.unmodifiable(ueberspringungen),
      schocks: List.unmodifiable(schocks),
      adrenalinGaben: List.unmodifiable(adrenalinGaben),
      adrenalinSeitLetzterGabe: adrenalinSeitLetzterGabe,
      adrenalinZeitfensterZustand: adrenalinZeitfensterZustand,
      istErsteAdrenalinGabeFaellig: isLaufend && _ersteAdrenalinGabeFaellig,
      amiodaronGaben: List.unmodifiable(amiodaronGaben),
      letzteAmiodaronGabe: letzteAmiodaronGabe,
      amiodaronHinweis: isLaufend
          ? _amiodaronHinweis(schocks, amiodaronGaben)
          : AmiodaronHinweis.keine,
      protokoll: _buildProtokoll(states),
    );
  }

  List<Reanimationsabschnitt> _deriveAbschnitte({
    required List<RoscEreignis> roscEreignisse,
    required List<Reanimationswiederbeginn> wiederbeginnEreignisse,
  }) {
    final boundaries = <_Strukturgrenze>[
      for (final rosc in roscEreignisse)
        _Strukturgrenze(
          zeitpunkt: rosc.zeitpunkt,
          typ: _StrukturgrenzeTyp.rosc,
          id: rosc.id,
        ),
      for (final wiederbeginn in wiederbeginnEreignisse)
        _Strukturgrenze(
          zeitpunkt: wiederbeginn.zeitpunkt,
          typ: _StrukturgrenzeTyp.wiederbeginn,
          id: wiederbeginn.id,
        ),
    ]..sort(_compareStrukturgrenzen);

    final abschnitte = <Reanimationsabschnitt>[];
    Duration? start = Duration.zero;
    var index = 0;

    for (final boundary in boundaries) {
      if (boundary.typ == _StrukturgrenzeTyp.rosc) {
        if (start != null) {
          abschnitte.add(
            Reanimationsabschnitt(
              index: index++,
              start: start,
              ende: boundary.zeitpunkt,
            ),
          );
          start = null;
        }
      } else {
        if (start != null) {
          abschnitte.add(
            Reanimationsabschnitt(
              index: index++,
              start: start,
              ende: boundary.zeitpunkt,
            ),
          );
        }
        start = boundary.zeitpunkt;
      }
    }

    if (start != null) {
      final closedAt = _verworfenAm ?? _ende?.zeitpunkt;
      abschnitte.add(
        Reanimationsabschnitt(index: index, start: start, ende: closedAt),
      );
    }

    return abschnitte;
  }

  int _compareStrukturgrenzen(_Strukturgrenze a, _Strukturgrenze b) {
    final byTime = a.zeitpunkt.compareTo(b.zeitpunkt);
    if (byTime != 0) return byTime;
    final byType = a.typ.index.compareTo(b.typ.index);
    if (byType != 0) return byType;
    return a.id.compareTo(b.id);
  }

  Protokoll _buildProtokoll(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    final eintraege = <ProtokollEintrag>[];
    var order = 0;

    ProtokollEintrag build<T extends Object>({
      required ProtokollEintragTyp typ,
      required T original,
      required String id,
      required Duration Function(T) zeitpunktOf,
      required T Function(T, ProtokollKorrektur?) apply,
    }) {
      final ref = _ref(typ, id);
      final state = states[ref];
      final daten = apply(original, state?.letzteKorrektur);
      final istEntfernt = state?.entfernt ?? false;
      final istKorrigiert = state?.hatKorrektur ?? false;
      final canEdit = _kannKorrigieren(typ);
      return ProtokollEintrag(
        ref: ref,
        typ: typ,
        zeitpunkt: zeitpunktOf(daten),
        originalZeitpunkt: zeitpunktOf(original),
        daten: daten,
        originalDaten: original,
        istEntfernt: istEntfernt,
        istKorrigiert: istKorrigiert,
        istBearbeitbar: !istEntfernt && canEdit,
        istWiederherstellbar: istEntfernt && canEdit,
        order: order++,
      );
    }

    eintraege.add(
      ProtokollEintrag(
        ref: const ProtokollEintragRef(
          typ: ProtokollEintragTyp.fallStart,
          id: 'fall-start',
        ),
        typ: ProtokollEintragTyp.fallStart,
        zeitpunkt: Duration.zero,
        originalZeitpunkt: Duration.zero,
        daten: startzeit,
        originalDaten: startzeit,
        istEntfernt: false,
        istKorrigiert: false,
        istBearbeitbar: false,
        istWiederherstellbar: false,
        order: order++,
      ),
    );

    for (final original in _schocks) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.schock,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is SchockKorrigiert) {
              return SchockEreignis(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
                energieJoule: korrektur.energieJoule,
              );
            }
            return original;
          },
        ),
      );
    }

    for (final original in _adrenalinGaben) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.adrenalin,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is AdrenalinKorrigiert) {
              return AdrenalinGabe(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
                dosisMg: korrektur.dosisMg,
              );
            }
            return original;
          },
        ),
      );
    }

    for (final original in _amiodaronGaben) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.amiodaron,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is AmiodaronKorrigiert) {
              return AmiodaronGabe(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
                dosisMg: korrektur.dosisMg,
              );
            }
            return original;
          },
        ),
      );
    }

    final pairedRoscRhythmusIds = <String>{
      for (final rosc in _roscEreignisse)
        if (rosc.rhythmusanalyseId != null) rosc.rhythmusanalyseId!,
    };
    for (final original in _rhythmusanalyseEintraege) {
      if (pairedRoscRhythmusIds.contains(original.id)) continue;
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.rhythmusanalyse,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            return switch (korrektur) {
              RhythmusanalyseKorrigiert(:final zeitpunkt, :final ergebnis) =>
                RhythmusanalyseEintrag(
                  id: original.id,
                  zeitpunkt: zeitpunkt,
                  ergebnis: ergebnis,
                ),
              ZeitpunktKorrigiert(:final zeitpunkt) => RhythmusanalyseEintrag(
                id: original.id,
                zeitpunkt: zeitpunkt,
                ergebnis: original.ergebnis,
              ),
              _ => original,
            };
          },
        ),
      );
    }

    for (final original in _uebersprungeneRhythmusanalysen) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.ueberspringung,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is ZeitpunktKorrigiert) {
              return RhythmusanalyseUeberspringung(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
              );
            }
            return original;
          },
        ),
      );
    }

    for (final original in _druckphaseNeustarts) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.druckphaseNeustart,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is ZeitpunktKorrigiert) {
              return DruckphaseNeustart(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
              );
            }
            return original;
          },
        ),
      );
    }

    for (final original in _roscEreignisse) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.rosc,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is RoscKorrigiert) {
              return RoscEreignis(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
                rhythmusanalyseId: original.rhythmusanalyseId,
              );
            }
            return original;
          },
        ),
      );
    }

    for (final original in _wiederbeginnEreignisse) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.wiederbeginn,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is ZeitpunktKorrigiert) {
              return Reanimationswiederbeginn(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
              );
            }
            return original;
          },
        ),
      );
    }

    for (final original in _messwerte) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.messwert,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) => switch (korrektur) {
            MesswertKorrigiert(:final ersatz) => ersatz,
            _ => original,
          },
        ),
      );
    }

    for (final original in _notizen) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.notiz,
          original: original,
          id: original.id,
          zeitpunktOf: (e) => e.zeitpunkt,
          apply: (original, korrektur) {
            if (korrektur is NotizKorrigiert) {
              return ReanimationsfallNotiz(
                id: original.id,
                zeitpunkt: korrektur.zeitpunkt,
                text: korrektur.text.trim(),
              );
            }
            return original;
          },
        ),
      );
    }

    if (_ende != null) {
      eintraege.add(
        ProtokollEintrag(
          ref: const ProtokollEintragRef(
            typ: ProtokollEintragTyp.fallEnde,
            id: 'fall-ende',
          ),
          typ: ProtokollEintragTyp.fallEnde,
          zeitpunkt: _ende!.zeitpunkt,
          originalZeitpunkt: _ende!.zeitpunkt,
          daten: _ende!,
          originalDaten: _ende!,
          istEntfernt: false,
          istKorrigiert: false,
          istBearbeitbar: false,
          istWiederherstellbar: false,
          order: order++,
        ),
      );
    }
    if (_verworfenAm != null) {
      eintraege.add(
        ProtokollEintrag(
          ref: const ProtokollEintragRef(
            typ: ProtokollEintragTyp.fallVerworfen,
            id: 'fall-verworfen',
          ),
          typ: ProtokollEintragTyp.fallVerworfen,
          zeitpunkt: _verworfenAm!,
          originalZeitpunkt: _verworfenAm!,
          daten: _verworfenAm!,
          originalDaten: _verworfenAm!,
          istEntfernt: false,
          istKorrigiert: false,
          istBearbeitbar: false,
          istWiederherstellbar: false,
          order: order++,
        ),
      );
    }

    final alle = List<ProtokollEintrag>.of(eintraege)..sort(_compareEintraege);
    final sichtbar = alle.where((e) => !e.istEntfernt).toList();
    final shockNummern = <ProtokollEintragRef, int>{};
    var schockNummer = 0;
    for (final eintrag in sichtbar) {
      if (eintrag.typ == ProtokollEintragTyp.schock) {
        shockNummern[eintrag.ref] = ++schockNummer;
      }
    }
    final sichtbarMitNummern = [
      for (final eintrag in sichtbar)
        eintrag.typ == ProtokollEintragTyp.schock
            ? eintrag.withNummer(shockNummern[eintrag.ref])
            : eintrag,
    ];
    final alleMitNummern = [
      for (final eintrag in alle)
        eintrag.typ == ProtokollEintragTyp.schock
            ? eintrag.withNummer(shockNummern[eintrag.ref])
            : eintrag,
    ];

    return Protokoll(
      eintraege: List.unmodifiable(sichtbarMitNummern),
      alleEintraege: List.unmodifiable(alleMitNummern),
    );
  }

  int _compareEintraege(ProtokollEintrag a, ProtokollEintrag b) {
    final byTime = a.zeitpunkt.compareTo(b.zeitpunkt);
    if (byTime != 0) return byTime;
    return a.order.compareTo(b.order);
  }

  bool _kannKorrigieren(ProtokollEintragTyp typ) {
    if (typ.istLebenszyklus) return false;
    if (_istOffen) return typ.istAufzeichnung;
    return true;
  }

  /// The contextual Amiodaron hint for the current Schock count.
  AmiodaronHinweis _amiodaronHinweis(
    List<SchockEreignis> schocks,
    List<AmiodaronGabe> gaben,
  ) {
    if (gaben.length >= 2) return AmiodaronHinweis.keine;

    final schockAnzahl = schocks.length;
    if (gaben.isEmpty) {
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
      demoMode: demoMode,
      demoOffset: _demoOffset,
      zustand: _zustand,
      phase: _phase,
      nextEreignisId: _nextEreignisId,
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
      korrekturen: List.unmodifiable(_korrekturen),
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

class _KorrekturZustand {
  bool entfernt = false;
  bool hatKorrektur = false;
  ProtokollKorrektur? letzteKorrektur;
}

enum _StrukturgrenzeTyp { rosc, wiederbeginn }

class _Strukturgrenze {
  const _Strukturgrenze({
    required this.zeitpunkt,
    required this.typ,
    required this.id,
  });

  final Duration zeitpunkt;
  final _StrukturgrenzeTyp typ;
  final String id;
}

/// A read-only snapshot of a [Reanimationsfall].
class ReanimationsfallSnapshot {
  const ReanimationsfallSnapshot({
    required this.zustand,
    required this.phase,
    required this.leitlinienprofil,
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.demoMode,
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
    required this.protokoll,
  });

  /// Whether the case is running, interrupted by ROSC, or ended.
  final ReanimationsfallZustand zustand;

  final Reanimationsphase phase;
  final Leitlinienprofil leitlinienprofil;
  final bool vibrationEnabled;
  final bool soundEnabled;

  /// Whether the Reanimationsfall was started in Demo-Modus.
  final bool demoMode;

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

  /// The effective and audit views of the case's Protokoll.
  final Protokoll protokoll;

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
    required this.demoMode,
    required this.demoOffset,
    required this.zustand,
    required this.phase,
    required this.nextEreignisId,
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
    required this.korrekturen,
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
  final bool demoMode;

  /// The accumulated simulated time added by Demo-Modus.
  final Duration demoOffset;

  final ReanimationsfallZustand zustand;
  final Reanimationsphase phase;

  /// The next stable event ID to assign.
  final int nextEreignisId;

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
  final List<ProtokollKorrektur> korrekturen;
  final ReanimationsfallEnde? ende;
  final Duration? verworfenAm;
}
