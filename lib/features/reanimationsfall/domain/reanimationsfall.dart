import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/ereignisse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/protokoll.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/protokoll_ereignis.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/zeitversatz.dart';

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
/// The internal timeline starts at the Übernahme recorded with the start tap:
/// every stored time is relative to that instant, which never moves. The
/// Startzeit and the Übernahme are derived from the latest
/// [VorbehandlungKorrigiert], so correcting them keeps every recorded event's
/// wall-clock time and leaves the running timers untouched. The snapshot
/// reports every time relative to the corrected Startzeit.
///
/// The Reanimationsdauer is derived from the monotonic clock. On resume, the
/// wall clock is used only to recover an interval in which the device was
/// suspended.
class Reanimationsfall {
  static int _nextId = 0;

  Reanimationsfall.start({
    required AppClock clock,
    this.leitlinienprofil = Leitlinienprofil.erc2025,
    this.vibrationEnabled = true,
    this.demoMode = false,
  }) : _clock = clock,
       _monotonicStartOffset = clock.monotonicNow(),
       id =
           '${clock.now().microsecondsSinceEpoch}-'
           '${clock.monotonicNow().inMicroseconds}-'
           '${_nextId++}',
       erfassteUebernahme = clock.now(),
       erfassteUebernahmeUtc = clock.now().toUtc(),
       utcOffsetMinutes = clock.now().timeZoneOffset.inMinutes {
    _compressionCycleStartOffset = _monotonicStartOffset;
  }

  /// Restores a Reanimationsfall from its persisted state.
  Reanimationsfall.restore({
    required AppClock clock,
    required ReanimationsfallState state,
  }) : _clock = clock,
       _monotonicStartOffset =
           clock.monotonicNow() -
           clock.now().toUtc().difference(state.erfassteUebernahmeUtc),
       id = state.id,
       leitlinienprofil = state.leitlinienprofil,
       vibrationEnabled = state.vibrationEnabled,
       demoMode = state.demoMode,
       erfassteUebernahme = state.erfassteUebernahme,
       erfassteUebernahmeUtc = state.erfassteUebernahmeUtc,
       utcOffsetMinutes = state.utcOffsetMinutes {
    _zustand = state.zustand;
    _phase = state.phase;
    _demoOffset = state.demoOffset;
    _vorbehandlungHinweisAusgeblendet = state.vorbehandlungHinweisAusgeblendet;
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
    _analysephaseBeginne.addAll(state.analysephaseBeginne);
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

  /// Whether the Reanimationsfall was started in Demo-Modus.
  final bool demoMode;

  /// The Übernahme as recorded with the start tap, the fixed origin of the
  /// internal timeline.
  final DateTime erfassteUebernahme;

  /// The recorded Übernahme as an absolute instant.
  final DateTime erfassteUebernahmeUtc;

  /// The device's UTC offset when the Reanimationsfall started.
  final int utcOffsetMinutes;

  bool _vorbehandlungHinweisAusgeblendet = false;

  /// The latest Vorbehandlung correction, if the form was ever saved.
  VorbehandlungKorrigiert? get _vorbehandlung =>
      letzteVorbehandlung(_korrekturen);

  /// The counts and the Notiz of the latest Vorbehandlung correction.
  Vorbehandlung get _vorbehandlungDaten =>
      _vorbehandlung?.vorbehandlung ?? Vorbehandlung.keine;

  /// The Übernahme relative to the recorded Übernahme.
  Duration get _uebernahmeOffset => _vorbehandlung?.uebernahme ?? Duration.zero;

  /// The Startzeit relative to the recorded Übernahme; zero or negative
  /// unless the Übernahme was corrected to after the start tap.
  Duration get _startzeitOffset => _vorbehandlung?.startzeit ?? Duration.zero;

  /// Turns an internal time into the time since the Startzeit.
  Duration get _versatz => -_startzeitOffset;

  /// The corrected wall-clock time zero of the Reanimationsfall.
  DateTime get startzeit => erfassteUebernahme.add(_startzeitOffset);

  /// The corrected wall-clock time of the Übernahme.
  DateTime get uebernahme => erfassteUebernahme.add(_uebernahmeOffset);

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

  final List<AnalysephaseBeginn> _analysephaseBeginne = [];
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
    final wallElapsed = _clock.now().toUtc().difference(erfassteUebernahmeUtc);
    final realElapsed =
        _clock.monotonicNow() + _monotonicAdjustment - _monotonicStartOffset;
    if (wallElapsed > realElapsed) {
      _monotonicAdjustment += wallElapsed - realElapsed;
    }
  }

  /// Pauses the compression timer, records an [AnalysephaseBeginn], and
  /// starts the Analysephase.
  void enterAnalysephase() {
    _requireLaufend();
    if (_phase != Reanimationsphase.druckphase) {
      throw StateError('already in the Analysephase');
    }

    final now = _monotonicNow();
    _analysephaseBeginne.add(
      AnalysephaseBeginn(
        id: _newEreignisId(),
        zeitpunkt: now - _monotonicStartOffset,
      ),
    );
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
    final gaben = _effektiveAmiodaronGaben(_korrekturZustaende());
    final bisherige = _vorbehandlungDaten.amiodaron + gaben.length;
    if (bisherige >= 2) {
      throw StateError('at most two Amiodaron doses are supported');
    }

    _amiodaronGaben.add(
      AmiodaronGabe(
        id: _newEreignisId(),
        zeitpunkt: _monotonicNow() - _monotonicStartOffset,
        dosisMg: bisherige == 0
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
    // A Vorbehandlung Adrenalin has no time, so it only suppresses the hint.
    if (gaben.isNotEmpty || _vorbehandlungDaten.adrenalin > 0) {
      _ersteAdrenalinGabeFaellig = false;
      return;
    }

    final ergebnis = _adrenalinAusloesendesErgebnis;
    _ersteAdrenalinGabeFaellig = switch (ergebnis?.kategorie) {
      RhythmusanalyseKategorie.nichtSchockbar => true,
      RhythmusanalyseKategorie.schockbar =>
        _vorbehandlungDaten.schocks + _effektiveSchocks(states).length >=
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

  /// Hides the `Vorbehandlung erfassen` prompt for this case.
  void dismissVorbehandlungHinweis() {
    _vorbehandlungHinweisAusgeblendet = true;
  }

  /// Saves the Vorbehandlung form as an append-only correction.
  ///
  /// [uebernahme] is the wall-clock time the team took over and
  /// [laufzeitBeiUebernahme] how long the resuscitation had been running by
  /// then; together they define the Startzeit. The rule is
  /// `Startzeit ≤ Übernahme ≤ first event recorded in the app`, never in the
  /// future. Recorded events keep their wall-clock time and the running
  /// Druckphase, the Adrenalin Zeitfenster and the phase stay untouched; only
  /// the Reanimationsdauer changes. It works during and after the case.
  ///
  /// [schocks], [adrenalin] and [amiodaron] are the counts given before the
  /// Übernahme and [notiz] an optional remark. They feed the Schock count, the
  /// Amiodaron hint and limit and the first Adrenalin dose hint like events
  /// recorded in the app, but have no time.
  void correctVorbehandlung({
    required DateTime uebernahme,
    required Duration laufzeitBeiUebernahme,
    int schocks = 0,
    int adrenalin = 0,
    int amiodaron = 0,
    String? notiz,
  }) {
    final offset = uebernahme.toUtc().difference(erfassteUebernahmeUtc);
    applyProtokollKorrektur(
      VorbehandlungKorrigiert(
        uebernahme: Duration(milliseconds: offset.inMilliseconds),
        laufzeitBeiUebernahme: Duration(
          milliseconds: laufzeitBeiUebernahme.inMilliseconds,
        ),
        schocks: schocks,
        adrenalin: adrenalin,
        amiodaron: amiodaron,
        notiz: notiz,
      ),
    );
  }

  void _applyVorbehandlung(VorbehandlungKorrigiert korrektur) {
    if (korrektur.laufzeitBeiUebernahme.isNegative) {
      throw ArgumentError.value(
        korrektur.laufzeitBeiUebernahme,
        'laufzeitBeiUebernahme',
        'the Startzeit must not be after the Übernahme',
      );
    }
    if (korrektur.uebernahme > _spaetesteUebernahmeOffset) {
      throw ArgumentError.value(
        korrektur.uebernahme,
        'uebernahme',
        'must not be after the first recorded event or in the future',
      );
    }
    for (final (name, wert) in [
      ('schocks', korrektur.schocks),
      ('adrenalin', korrektur.adrenalin),
      ('amiodaron', korrektur.amiodaron),
    ]) {
      if (wert < 0) {
        throw ArgumentError.value(wert, name, 'must not be negative');
      }
    }
    final notiz = korrektur.notiz?.trim();
    _appendKorrektur(
      VorbehandlungKorrigiert(
        uebernahme: korrektur.uebernahme,
        laufzeitBeiUebernahme: korrektur.laufzeitBeiUebernahme,
        schocks: korrektur.schocks,
        adrenalin: korrektur.adrenalin,
        amiodaron: korrektur.amiodaron,
        notiz: notiz == null || notiz.isEmpty ? null : notiz,
      ),
    );
    _updateAdrenalinGabeFaelligkeit();
  }

  /// The latest allowed Übernahme relative to the recorded Übernahme: the
  /// first visible event recorded in the app, and never after now or the end
  /// of the case.
  Duration get _spaetesteUebernahmeOffset {
    final states = _korrekturZustaende();
    var spaeteste = _maxKorrekturZeitpunkt;
    void consider(Iterable<ProtokollEreignis> ereignisse) {
      for (final ereignis in ereignisse) {
        if (ereignis.zeitpunkt < spaeteste) spaeteste = ereignis.zeitpunkt;
      }
    }

    consider(_effektiveSchocks(states));
    consider(_effektiveAdrenalinGaben(states));
    consider(_effektiveAmiodaronGaben(states));
    consider(_effektiveMesswerte(states));
    consider(_effektiveNotizen(states));
    consider(_effektiveRhythmusanalysen(states));
    consider(_effektiveUeberspringungen(states));
    consider(_effektiveDruckphaseNeustarts(states));
    consider(_effektiveRosc(states));
    consider(_effektiveWiederbeginn(states));
    return spaeteste;
  }

  /// Applies an append-only correction to one Protokoll entry.
  ///
  /// Times in [eingabe] are relative to the current Startzeit, as shown in the
  /// Protokoll. They are stored relative to the recorded Übernahme so that a
  /// later Startzeit correction keeps their wall-clock time.
  ///
  /// Every clinical entry can be corrected, removed, and restored, also while
  /// the case is open. A correction to a structural entry replays the live
  /// state (phase, timers, ROSC state) from the corrected Protokoll.
  void applyProtokollKorrektur(ProtokollKorrektur eingabe) {
    if (eingabe is VorbehandlungKorrigiert) {
      _applyVorbehandlung(eingabe);
      return;
    }
    final korrektur = verschobeneKorrektur(eingabe, _startzeitOffset);
    final ref = korrektur.ziel;
    if (ref.typ.istLebenszyklus) {
      throw StateError('lifecycle entries are read-only');
    }
    final original = _findOriginal(ref);
    if (original == null) {
      throw ArgumentError.value(ref, 'ziel', 'unknown Protokoll entry');
    }

    if (korrektur is ProtokollEintragEntfernt) {
      _requireNotRemoved(ref);
      _requireNotPairedRoscRhythmusanalyse(ref);
      _appendKorrektur(korrektur);
      _appendPairRemoval(ref);
      _afterKorrektur(ref);
      return;
    }
    if (korrektur is ProtokollEintragWiederhergestellt) {
      _requireRemoved(ref);
      _requireNotPairedRoscRhythmusanalyse(ref);
      _appendKorrektur(korrektur);
      _appendPairRestore(ref);
      _afterKorrektur(ref);
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
        if (ref.typ != ProtokollEintragTyp.analysephaseBeginn &&
            ref.typ != ProtokollEintragTyp.ueberspringung &&
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
      case ProtokollEintragEntfernt() ||
          ProtokollEintragWiederhergestellt() ||
          VorbehandlungKorrigiert():
        throw StateError('unreachable');
    }

    _appendKorrektur(korrektur);
    if (ref.typ == ProtokollEintragTyp.rosc) {
      _appendRoscPairTime(korrektur);
    }
    _afterKorrektur(ref);
  }

  /// Recomputes the state derived from the corrected Protokoll.
  void _afterKorrektur(ProtokollEintragRef ref) {
    if (ref.typ.istStrukturell) {
      _rebuildLiveState();
    } else if (ref.typ == ProtokollEintragTyp.schock ||
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

  /// Removes the paired Rhythmusanalyse and the following
  /// Reanimationswiederbeginn together with a ROSC, as if neither happened.
  void _appendPairRemoval(ProtokollEintragRef ref) {
    if (ref.typ != ProtokollEintragTyp.rosc) return;
    // Resolve the Wiederbeginn before the ROSC removal changes the timeline.
    final folgenderWiederbeginn = _folgenderWiederbeginn(
      ref.id,
      ohneEntfernung: ref,
    );
    final pairId = _findRosc(ref.id)?.rhythmusanalyseId;
    if (pairId != null) {
      _korrekturen.add(
        ProtokollEintragEntfernt(
          ziel: _ref(ProtokollEintragTyp.rhythmusanalyse, pairId),
        ),
      );
    }
    if (folgenderWiederbeginn != null) {
      _korrekturen.add(
        ProtokollEintragEntfernt(
          ziel: _ref(ProtokollEintragTyp.wiederbeginn, folgenderWiederbeginn),
        ),
      );
    }
  }

  /// Restores everything that was removed together with a ROSC.
  void _appendPairRestore(ProtokollEintragRef ref) {
    if (ref.typ != ProtokollEintragTyp.rosc) return;
    final removalIndex = _korrekturen.lastIndexWhere(
      (k) => k is ProtokollEintragEntfernt && k.ziel == ref,
    );
    if (removalIndex == -1) return;
    final cascade = <ProtokollEintragRef>[];
    for (final korrektur in _korrekturen.skip(removalIndex + 1)) {
      if (korrektur is! ProtokollEintragEntfernt) break;
      final ziel = korrektur.ziel;
      if (ziel.typ != ProtokollEintragTyp.rhythmusanalyse &&
          ziel.typ != ProtokollEintragTyp.wiederbeginn) {
        break;
      }
      cascade.add(ziel);
    }
    final states = _korrekturZustaende();
    for (final ziel in cascade) {
      if (!(states[ziel]?.entfernt ?? false)) continue;
      _korrekturen.add(ProtokollEintragWiederhergestellt(ziel: ziel));
    }
  }

  /// The id of the effective Reanimationswiederbeginn that ends the ROSC
  /// interval started by the ROSC [roscId], if any.
  ///
  /// [ohneEntfernung] is the ROSC removal that was just appended; it is
  /// ignored so the ROSC itself is still part of the timeline.
  String? _folgenderWiederbeginn(
    String roscId, {
    required ProtokollEintragRef ohneEntfernung,
  }) {
    final states = _korrekturZustaende();
    states[ohneEntfernung]?.entfernt = false;
    final struktur = _effektiveStruktur(states);
    final index = struktur.indexWhere(
      (e) => e.typ == ProtokollEintragTyp.rosc && e.id == roscId,
    );
    if (index == -1) return null;
    for (final eintrag in struktur.skip(index + 1)) {
      if (eintrag.typ == ProtokollEintragTyp.rosc) return null;
      if (eintrag.typ == ProtokollEintragTyp.wiederbeginn) return eintrag.id;
    }
    return null;
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
      ProtokollEintragTyp.analysephaseBeginn => _findById<AnalysephaseBeginn>(
        _analysephaseBeginne,
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
      ProtokollEintragTyp.startzeit ||
      ProtokollEintragTyp.uebernahme ||
      ProtokollEintragTyp.vorbehandlung ||
      ProtokollEintragTyp.reanimationsfallEnde ||
      ProtokollEintragTyp.verworfen => null,
    };
  }

  T? _findById<T>(List<T> list, String id, String Function(T) idOf) {
    for (final item in list) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

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
    if (zeitpunkt < _uebernahmeOffset || zeitpunkt > _maxKorrekturZeitpunkt) {
      throw ArgumentError.value(
        zeitpunkt,
        'zeitpunkt',
        'must be inside the case',
      );
    }
    if (typ.istStrukturell) {
      _requireBetweenStructuralNeighbours(zeitpunkt, typ, id);
    }
  }

  /// Keeps a corrected structural entry between its effective neighbours so
  /// the replayed sequence of the case stays the same.
  void _requireBetweenStructuralNeighbours(
    Duration zeitpunkt,
    ProtokollEintragTyp typ,
    String id,
  ) {
    final struktur = _effektiveStruktur(_korrekturZustaende())
        .where(
          (e) =>
              e.typ != ProtokollEintragTyp.rhythmusanalyse ||
              !_isPairedRoscRhythmusanalyse(e.id),
        )
        .toList();

    final index = struktur.indexWhere((e) => e.typ == typ && e.id == id);
    if (index == -1) return;
    final previous = index > 0
        ? struktur[index - 1].zeitpunkt
        : _uebernahmeOffset;
    final next = index < struktur.length - 1
        ? struktur[index + 1].zeitpunkt
        : _maxKorrekturZeitpunkt;
    if (zeitpunkt < previous || zeitpunkt > next) {
      throw ArgumentError.value(
        zeitpunkt,
        'zeitpunkt',
        'must stay between the neighbouring structural entries',
      );
    }
  }

  /// Every effective structural entry in replay order.
  List<_Strukturereignis> _effektiveStruktur(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    var legacyOrder = 0;
    _Strukturereignis eintrag(ProtokollEintragTyp typ, ProtokollEreignis e) {
      return _Strukturereignis(
        typ: typ,
        daten: e,
        reihenfolge: _ereignisReihenfolge(e.id, legacyOrder++),
      );
    }

    return [
      for (final e in _effektiveAnalysephaseBeginne(states))
        eintrag(ProtokollEintragTyp.analysephaseBeginn, e),
      for (final e in _effektiveRhythmusanalysen(states))
        eintrag(ProtokollEintragTyp.rhythmusanalyse, e),
      for (final e in _effektiveUeberspringungen(states))
        eintrag(ProtokollEintragTyp.ueberspringung, e),
      for (final e in _effektiveDruckphaseNeustarts(states))
        eintrag(ProtokollEintragTyp.druckphaseNeustart, e),
      for (final e in _effektiveRosc(states))
        eintrag(ProtokollEintragTyp.rosc, e),
      for (final e in _effektiveWiederbeginn(states))
        eintrag(ProtokollEintragTyp.wiederbeginn, e),
    ]..sort((a, b) {
      final byTime = a.zeitpunkt.compareTo(b.zeitpunkt);
      if (byTime != 0) return byTime;
      return a.reihenfolge.compareTo(b.reihenfolge);
    });
  }

  /// Replays the live state from the effective structural Protokoll entries,
  /// as if the corrected history had happened that way.
  ///
  /// The rules mirror the recording commands. An entry that does not fit the
  /// replayed state, for example a Wiederbeginn without a preceding ROSC, has
  /// no effect. A closed case keeps its lifecycle state.
  void _rebuildLiveState() {
    final cycle = leitlinienprofil.compressionCycle;
    var zustand = ReanimationsfallZustand.laufend;
    var phase = Reanimationsphase.druckphase;
    var cycleStart = Duration.zero;
    var remainingAtPause = Duration.zero;
    Duration? pauseStart;
    RhythmusanalyseErgebnis? ausloesendesErgebnis;

    void startDruckphase(Duration t) {
      phase = Reanimationsphase.druckphase;
      cycleStart = t;
      remainingAtPause = Duration.zero;
      pauseStart = null;
    }

    for (final eintrag in _effektiveStruktur(_korrekturZustaende())) {
      final t = eintrag.zeitpunkt;
      final laufend = zustand == ReanimationsfallZustand.laufend;
      switch (eintrag.daten) {
        case AnalysephaseBeginn():
          if (laufend && phase == Reanimationsphase.druckphase) {
            final cycleElapsed = t - cycleStart;
            remainingAtPause = cycleElapsed >= cycle
                ? Duration.zero
                : cycle - cycleElapsed;
            pauseStart = t;
            phase = Reanimationsphase.analysephase;
          }
        case RhythmusanalyseEintrag(:final ergebnis):
          if (laufend) {
            ausloesendesErgebnis = ergebnis;
            // A ROSC result changes the state through its ROSC entry.
            if (ergebnis != RhythmusanalyseErgebnis.rosc) startDruckphase(t);
          }
        case RhythmusanalyseUeberspringung():
          if (laufend) startDruckphase(t);
        case DruckphaseNeustart():
          if (laufend && phase == Reanimationsphase.druckphase) {
            cycleStart = t;
            remainingAtPause = Duration.zero;
          }
        case RoscEreignis():
          if (laufend) {
            zustand = ReanimationsfallZustand.rosc;
            phase = Reanimationsphase.druckphase;
            pauseStart = null;
          }
        case Reanimationswiederbeginn():
          if (zustand == ReanimationsfallZustand.rosc) {
            zustand = ReanimationsfallZustand.laufend;
            startDruckphase(t);
          }
      }
    }

    final offen =
        _zustand == ReanimationsfallZustand.laufend ||
        _zustand == ReanimationsfallZustand.rosc;
    if (offen) _zustand = zustand;
    if (_zustand != ReanimationsfallZustand.laufend) {
      phase = Reanimationsphase.druckphase;
      pauseStart = null;
    }

    _phase = phase;
    _compressionCycleStartOffset = _monotonicStartOffset + cycleStart;
    _compressionRemainingAtPause = remainingAtPause;
    final start = pauseStart;
    _analysephaseStartOffset = start == null
        ? null
        : _monotonicStartOffset + start;
    _adrenalinAusloesendesErgebnis = ausloesendesErgebnis;
    _updateAdrenalinGabeFaelligkeit();
  }

  Map<ProtokollEintragRef, _KorrekturZustand> _korrekturZustaende() {
    final states = <ProtokollEintragRef, _KorrekturZustand>{};
    for (final korrektur in _korrekturen) {
      // The Startzeit and Übernahme entries derive from the latest
      // Vorbehandlung directly.
      if (korrektur is VorbehandlungKorrigiert) continue;
      final state = states.putIfAbsent(korrektur.ziel, _KorrekturZustand.new);
      switch (korrektur) {
        case VorbehandlungKorrigiert():
          break;
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

  SchockEreignis _applySchock(
    SchockEreignis original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is SchockKorrigiert) {
      return SchockEreignis(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
        energieJoule: korrektur.energieJoule,
      );
    }
    return original;
  }

  AdrenalinGabe _applyAdrenalin(
    AdrenalinGabe original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is AdrenalinKorrigiert) {
      return AdrenalinGabe(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
        dosisMg: korrektur.dosisMg,
      );
    }
    return original;
  }

  AmiodaronGabe _applyAmiodaron(
    AmiodaronGabe original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is AmiodaronKorrigiert) {
      return AmiodaronGabe(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
        dosisMg: korrektur.dosisMg,
      );
    }
    return original;
  }

  Messwert _applyMesswert(Messwert original, ProtokollKorrektur? korrektur) {
    if (korrektur is MesswertKorrigiert) return korrektur.ersatz;
    return original;
  }

  ReanimationsfallNotiz _applyNotiz(
    ReanimationsfallNotiz original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is NotizKorrigiert) {
      return ReanimationsfallNotiz(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
        text: korrektur.text.trim(),
      );
    }
    return original;
  }

  RhythmusanalyseEintrag _applyRhythmusanalyse(
    RhythmusanalyseEintrag original,
    ProtokollKorrektur? korrektur,
  ) {
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
  }

  AnalysephaseBeginn _applyAnalysephaseBeginn(
    AnalysephaseBeginn original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is ZeitpunktKorrigiert) {
      return AnalysephaseBeginn(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
      );
    }
    return original;
  }

  RhythmusanalyseUeberspringung _applyUeberspringung(
    RhythmusanalyseUeberspringung original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is ZeitpunktKorrigiert) {
      return RhythmusanalyseUeberspringung(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
      );
    }
    return original;
  }

  DruckphaseNeustart _applyDruckphaseNeustart(
    DruckphaseNeustart original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is ZeitpunktKorrigiert) {
      return DruckphaseNeustart(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
      );
    }
    return original;
  }

  RoscEreignis _applyRosc(
    RoscEreignis original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is RoscKorrigiert) {
      return RoscEreignis(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
        rhythmusanalyseId: original.rhythmusanalyseId,
      );
    }
    return original;
  }

  Reanimationswiederbeginn _applyWiederbeginn(
    Reanimationswiederbeginn original,
    ProtokollKorrektur? korrektur,
  ) {
    if (korrektur is ZeitpunktKorrigiert) {
      return Reanimationswiederbeginn(
        id: original.id,
        zeitpunkt: korrektur.zeitpunkt,
      );
    }
    return original;
  }

  List<T> _effektiveListe<T extends ProtokollEreignis>({
    required ProtokollEintragTyp typ,
    required List<T> original,
    required T Function(T, ProtokollKorrektur?) apply,
    required Map<ProtokollEintragRef, _KorrekturZustand> states,
  }) {
    final result = <T>[];
    for (final item in original) {
      final state = states[_ref(typ, item.id)];
      if (state?.entfernt ?? false) continue;
      result.add(apply(item, state?.letzteKorrektur));
    }
    return result;
  }

  List<SchockEreignis> _effektiveSchocks(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.schock,
      original: _schocks,
      apply: _applySchock,
      states: states,
    );
  }

  List<AdrenalinGabe> _effektiveAdrenalinGaben(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.adrenalin,
      original: _adrenalinGaben,
      apply: _applyAdrenalin,
      states: states,
    );
  }

  List<AmiodaronGabe> _effektiveAmiodaronGaben(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.amiodaron,
      original: _amiodaronGaben,
      apply: _applyAmiodaron,
      states: states,
    );
  }

  List<Messwert> _effektiveMesswerte(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.messwert,
      original: _messwerte,
      apply: _applyMesswert,
      states: states,
    );
  }

  List<ReanimationsfallNotiz> _effektiveNotizen(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.notiz,
      original: _notizen,
      apply: _applyNotiz,
      states: states,
    );
  }

  List<RhythmusanalyseEintrag> _effektiveRhythmusanalysen(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.rhythmusanalyse,
      original: _rhythmusanalyseEintraege,
      apply: _applyRhythmusanalyse,
      states: states,
    );
  }

  List<AnalysephaseBeginn> _effektiveAnalysephaseBeginne(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.analysephaseBeginn,
      original: _analysephaseBeginne,
      apply: _applyAnalysephaseBeginn,
      states: states,
    );
  }

  List<RhythmusanalyseUeberspringung> _effektiveUeberspringungen(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.ueberspringung,
      original: _uebersprungeneRhythmusanalysen,
      apply: _applyUeberspringung,
      states: states,
    );
  }

  List<DruckphaseNeustart> _effektiveDruckphaseNeustarts(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.druckphaseNeustart,
      original: _druckphaseNeustarts,
      apply: _applyDruckphaseNeustart,
      states: states,
    );
  }

  List<RoscEreignis> _effektiveRosc(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.rosc,
      original: _roscEreignisse,
      apply: _applyRosc,
      states: states,
    );
  }

  List<Reanimationswiederbeginn> _effektiveWiederbeginn(
    Map<ProtokollEintragRef, _KorrekturZustand> states,
  ) {
    return _effektiveListe(
      typ: ProtokollEintragTyp.wiederbeginn,
      original: _wiederbeginnEreignisse,
      apply: _applyWiederbeginn,
      states: states,
    );
  }

  ProtokollEintragRef _ref(ProtokollEintragTyp typ, String id) =>
      ProtokollEintragRef(typ: typ, id: id);

  /// A read-only view in which every time is relative to the Startzeit.
  ReanimationsfallSnapshot snapshot() {
    final versatz = _versatz;
    List<T> verschoben<T extends Object>(List<T> ereignisse) => [
      for (final ereignis in ereignisse)
        verschobenesEreignis(ereignis, versatz),
    ];

    final states = _korrekturZustaende();
    final schocks = verschoben(_effektiveSchocks(states));
    final adrenalinGaben = verschoben(_effektiveAdrenalinGaben(states))
      ..sort((a, b) => a.zeitpunkt.compareTo(b.zeitpunkt));
    final amiodaronGaben = verschoben(_effektiveAmiodaronGaben(states))
      ..sort((a, b) => a.zeitpunkt.compareTo(b.zeitpunkt));
    final messwerte = verschoben(_effektiveMesswerte(states));
    final notizen = verschoben(_effektiveNotizen(states));
    final rhythmusanalysen = verschoben(_effektiveRhythmusanalysen(states));
    final analysephaseBeginne = verschoben(
      _effektiveAnalysephaseBeginne(states),
    );
    final ueberspringungen = verschoben(_effektiveUeberspringungen(states));
    final druckphaseNeustarts = verschoben(
      _effektiveDruckphaseNeustarts(states),
    );
    final roscEreignisse = verschoben(_effektiveRosc(states));
    final wiederbeginnEreignisse = verschoben(_effektiveWiederbeginn(states));
    final ende = _ende == null ? null : verschobenesEreignis(_ende!, versatz);
    final verworfenAm = _verworfenAm == null ? null : _verworfenAm! + versatz;

    final now = _monotonicNow();
    // The Reanimationsdauer counts from the corrected Startzeit; every timer
    // below runs on the internal monotonic timeline and ignores corrections.
    final elapsed = now - _monotonicStartOffset + versatz;
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
      closedAt: verworfenAm ?? ende?.zeitpunkt,
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
      demoMode: demoMode,
      startzeit: startzeit,
      uebernahme: uebernahme,
      laufzeitBeiUebernahme: _uebernahmeOffset + versatz,
      spaetesteUebernahme: erfassteUebernahme.add(_spaetesteUebernahmeOffset),
      zeigeVorbehandlungHinweis:
          _istOffen &&
          !_vorbehandlungHinweisAusgeblendet &&
          _vorbehandlung == null,
      reanimationsdauer: elapsed,
      cprDauer: cprDauer,
      abschnitte: List.unmodifiable(abschnitte),
      roscEreignisse: List.unmodifiable(roscEreignisse),
      wiederbeginnEreignisse: List.unmodifiable(wiederbeginnEreignisse),
      ende: ende,
      verworfenAm: verworfenAm,
      compressionRemaining: compressionRemaining,
      rhythmusanalyseOverdue: rhythmusanalyseOverdue,
      isRhythmusanalyseDue: isRhythmusanalyseDue,
      pauseDuration: pauseDuration,
      isPauseOverdue: isPauseOverdue,
      rhythmusanalyseEintraege: List.unmodifiable(rhythmusanalysen),
      druckphaseNeustarts: List.unmodifiable(druckphaseNeustarts),
      messwerte: List.unmodifiable(messwerte),
      notizen: List.unmodifiable(notizen),
      analysephaseBeginne: List.unmodifiable(analysephaseBeginne),
      uebersprungeneRhythmusanalysen: List.unmodifiable(ueberspringungen),
      schocks: List.unmodifiable(schocks),
      adrenalinGaben: List.unmodifiable(adrenalinGaben),
      adrenalinSeitLetzterGabe: adrenalinSeitLetzterGabe,
      adrenalinZeitfensterZustand: adrenalinZeitfensterZustand,
      istErsteAdrenalinGabeFaellig: isLaufend && _ersteAdrenalinGabeFaellig,
      amiodaronGaben: List.unmodifiable(amiodaronGaben),
      letzteAmiodaronGabe: letzteAmiodaronGabe,
      amiodaronHinweis: isLaufend
          ? _amiodaronHinweis(
              _vorbehandlungDaten.schocks + schocks.length,
              _vorbehandlungDaten.amiodaron + amiodaronGaben.length,
            )
          : AmiodaronHinweis.keine,
      vorbehandlung: _vorbehandlungDaten,
      protokoll: _buildProtokoll(states),
    );
  }

  List<Reanimationsabschnitt> _deriveAbschnitte({
    required List<RoscEreignis> roscEreignisse,
    required List<Reanimationswiederbeginn> wiederbeginnEreignisse,
    required Duration? closedAt,
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
        // A Reanimationswiederbeginn starts a new segment only after ROSC.
        // Without a preceding ROSC, the CPR period stays continuous.
        start ??= boundary.zeitpunkt;
      }
    }

    if (start != null) {
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
    final versatz = _versatz;
    final eintraege = <ProtokollEintrag>[];
    var legacyOrder = 0;

    ProtokollEintrag build<T extends ProtokollEreignis>({
      required ProtokollEintragTyp typ,
      required T original,
      required T Function(T, ProtokollKorrektur?) apply,
    }) {
      final ref = _ref(typ, original.id);
      final state = states[ref];
      final daten = verschobenesEreignis(
        apply(original, state?.letzteKorrektur),
        versatz,
      );
      final istEntfernt = state?.entfernt ?? false;
      final istKorrigiert = state?.hatKorrektur ?? false;
      final canEdit = _kannKorrigieren(typ);
      return ProtokollEintrag(
        ref: ref,
        typ: typ,
        zeitpunkt: daten.zeitpunkt,
        originalZeitpunkt: original.zeitpunkt + versatz,
        daten: daten,
        originalDaten: verschobenesEreignis(original, versatz),
        istEntfernt: istEntfernt,
        istKorrigiert: istKorrigiert,
        istBearbeitbar: !istEntfernt && canEdit,
        istWiederherstellbar: istEntfernt && canEdit,
        reihenfolge: _ereignisReihenfolge(original.id, legacyOrder++),
      );
    }

    // The Startzeit and the Übernahme open the Vorbehandlung form, during and
    // after the case. Their original is the Übernahme recorded at the tap.
    eintraege.add(
      ProtokollEintrag(
        ref: const ProtokollEintragRef(
          typ: ProtokollEintragTyp.startzeit,
          id: 'startzeit',
        ),
        typ: ProtokollEintragTyp.startzeit,
        zeitpunkt: Duration.zero,
        originalZeitpunkt: versatz,
        daten: startzeit,
        originalDaten: erfassteUebernahme,
        istEntfernt: false,
        istKorrigiert: versatz != Duration.zero,
        istBearbeitbar: true,
        istWiederherstellbar: false,
        reihenfolge: -3,
      ),
    );
    final laufzeitBeiUebernahme = _uebernahmeOffset + versatz;
    if (laufzeitBeiUebernahme != Duration.zero) {
      eintraege.add(
        ProtokollEintrag(
          ref: VorbehandlungKorrigiert.zielRef,
          typ: ProtokollEintragTyp.uebernahme,
          zeitpunkt: laufzeitBeiUebernahme,
          originalZeitpunkt: versatz,
          daten: Uebernahme(zeitpunkt: laufzeitBeiUebernahme),
          originalDaten: Uebernahme(zeitpunkt: versatz),
          istEntfernt: false,
          istKorrigiert: _uebernahmeOffset != Duration.zero,
          istBearbeitbar: true,
          istWiederherstellbar: false,
          reihenfolge: -2,
        ),
      );
    }
    // The Vorbehandlung is its own entry at the Übernahme, shown only when
    // something was recorded. It is saved with the form, so it carries no
    // Korrektur marker of its own.
    if (!_vorbehandlungDaten.istLeer) {
      eintraege.add(
        ProtokollEintrag(
          ref: const ProtokollEintragRef(
            typ: ProtokollEintragTyp.vorbehandlung,
            id: 'vorbehandlung',
          ),
          typ: ProtokollEintragTyp.vorbehandlung,
          zeitpunkt: laufzeitBeiUebernahme,
          originalZeitpunkt: versatz,
          daten: _vorbehandlungDaten,
          originalDaten: _vorbehandlungDaten,
          istEntfernt: false,
          istKorrigiert: false,
          istBearbeitbar: true,
          istWiederherstellbar: false,
          reihenfolge: -1,
        ),
      );
    }

    for (final original in _schocks) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.schock,
          original: original,
          apply: _applySchock,
        ),
      );
    }

    for (final original in _adrenalinGaben) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.adrenalin,
          original: original,
          apply: _applyAdrenalin,
        ),
      );
    }

    for (final original in _amiodaronGaben) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.amiodaron,
          original: original,
          apply: _applyAmiodaron,
        ),
      );
    }

    for (final original in _analysephaseBeginne) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.analysephaseBeginn,
          original: original,
          apply: _applyAnalysephaseBeginn,
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
          apply: _applyRhythmusanalyse,
        ),
      );
    }

    for (final original in _uebersprungeneRhythmusanalysen) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.ueberspringung,
          original: original,
          apply: _applyUeberspringung,
        ),
      );
    }

    for (final original in _druckphaseNeustarts) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.druckphaseNeustart,
          original: original,
          apply: _applyDruckphaseNeustart,
        ),
      );
    }

    for (final original in _roscEreignisse) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.rosc,
          original: original,
          apply: _applyRosc,
        ),
      );
    }

    for (final original in _wiederbeginnEreignisse) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.wiederbeginn,
          original: original,
          apply: _applyWiederbeginn,
        ),
      );
    }

    for (final original in _messwerte) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.messwert,
          original: original,
          apply: _applyMesswert,
        ),
      );
    }

    for (final original in _notizen) {
      eintraege.add(
        build(
          typ: ProtokollEintragTyp.notiz,
          original: original,
          apply: _applyNotiz,
        ),
      );
    }

    if (_ende != null) {
      eintraege.add(
        ProtokollEintrag(
          ref: const ProtokollEintragRef(
            typ: ProtokollEintragTyp.reanimationsfallEnde,
            id: 'reanimationsfall-ende',
          ),
          typ: ProtokollEintragTyp.reanimationsfallEnde,
          zeitpunkt: _ende!.zeitpunkt + versatz,
          originalZeitpunkt: _ende!.zeitpunkt + versatz,
          daten: verschobenesEreignis(_ende!, versatz),
          originalDaten: verschobenesEreignis(_ende!, versatz),
          istEntfernt: false,
          istKorrigiert: false,
          istBearbeitbar: false,
          istWiederherstellbar: false,
          reihenfolge: 1 << 30,
        ),
      );
    }
    if (_verworfenAm != null) {
      eintraege.add(
        ProtokollEintrag(
          ref: const ProtokollEintragRef(
            typ: ProtokollEintragTyp.verworfen,
            id: 'verworfen',
          ),
          typ: ProtokollEintragTyp.verworfen,
          zeitpunkt: _verworfenAm! + versatz,
          originalZeitpunkt: _verworfenAm! + versatz,
          daten: _verworfenAm! + versatz,
          originalDaten: _verworfenAm! + versatz,
          istEntfernt: false,
          istKorrigiert: false,
          istBearbeitbar: false,
          istWiederherstellbar: false,
          reihenfolge: 1 << 30,
        ),
      );
    }

    final alle = List<ProtokollEintrag>.of(eintraege)..sort(_compareEintraege);
    final sichtbar = alle.where((e) => !e.istEntfernt).toList();
    final shockNummern = <ProtokollEintragRef, int>{};
    var schockNummer = _vorbehandlungDaten.schocks;
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

  int _ereignisReihenfolge(String id, int fallback) {
    if (id.startsWith('e')) {
      final parsed = int.tryParse(id.substring(1));
      if (parsed != null) return parsed;
    }
    return (1 << 30) + fallback;
  }

  int _compareEintraege(ProtokollEintrag a, ProtokollEintrag b) {
    final byTime = a.zeitpunkt.compareTo(b.zeitpunkt);
    if (byTime != 0) return byTime;
    return a.reihenfolge.compareTo(b.reihenfolge);
  }

  bool _kannKorrigieren(ProtokollEintragTyp typ) => !typ.istLebenszyklus;

  bool get _istOffen =>
      _zustand == ReanimationsfallZustand.laufend ||
      _zustand == ReanimationsfallZustand.rosc;

  /// The contextual Amiodaron hint for the current Schock count.
  ///
  /// Both counts include the Vorbehandlung.
  AmiodaronHinweis _amiodaronHinweis(int schockAnzahl, int gabenAnzahl) {
    if (gabenAnzahl >= 2) return AmiodaronHinweis.keine;

    if (gabenAnzahl == 0) {
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
      erfassteUebernahme: erfassteUebernahme,
      erfassteUebernahmeUtc: erfassteUebernahmeUtc,
      vorbehandlungHinweisAusgeblendet: _vorbehandlungHinweisAusgeblendet,
      utcOffsetMinutes: utcOffsetMinutes,
      leitlinienprofil: leitlinienprofil,
      vibrationEnabled: vibrationEnabled,
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
      analysephaseBeginne: List.unmodifiable(_analysephaseBeginne),
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

/// One effective structural entry, used to replay the live state.
class _Strukturereignis {
  const _Strukturereignis({
    required this.typ,
    required this.daten,
    required this.reihenfolge,
  });

  final ProtokollEintragTyp typ;
  final ProtokollEreignis daten;
  final int reihenfolge;

  String get id => daten.id;
  Duration get zeitpunkt => daten.zeitpunkt;
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
    required this.demoMode,
    required this.startzeit,
    required this.uebernahme,
    required this.laufzeitBeiUebernahme,
    required this.spaetesteUebernahme,
    required this.zeigeVorbehandlungHinweis,
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
    required this.analysephaseBeginne,
    required this.uebersprungeneRhythmusanalysen,
    required this.schocks,
    required this.adrenalinGaben,
    required this.adrenalinSeitLetzterGabe,
    required this.adrenalinZeitfensterZustand,
    required this.istErsteAdrenalinGabeFaellig,
    required this.amiodaronGaben,
    required this.letzteAmiodaronGabe,
    required this.amiodaronHinweis,
    required this.vorbehandlung,
    required this.protokoll,
  });

  /// Whether the case is running, interrupted by ROSC, or ended.
  final ReanimationsfallZustand zustand;

  final Reanimationsphase phase;
  final Leitlinienprofil leitlinienprofil;
  final bool vibrationEnabled;

  /// Whether the Reanimationsfall was started in Demo-Modus.
  final bool demoMode;

  /// The corrected wall-clock time zero; every time in this snapshot is
  /// relative to it.
  final DateTime startzeit;

  /// The corrected wall-clock time the team took over.
  final DateTime uebernahme;

  /// How long the resuscitation had been running at the Übernahme.
  final Duration laufzeitBeiUebernahme;

  /// The latest Übernahme the Vorbehandlung form accepts: the first event
  /// recorded in the app, now, or the end of the case, whichever is first.
  final DateTime spaetesteUebernahme;

  /// Whether the `Vorbehandlung erfassen` prompt is shown: on an open case
  /// until the Vorbehandlung is saved or the prompt is dismissed.
  final bool zeigeVorbehandlungHinweis;

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

  /// Every recorded Analysephase start.
  final List<AnalysephaseBeginn> analysephaseBeginne;

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

  /// The Schocks, Adrenalin and Amiodaron Gaben given before the Übernahme,
  /// as counts, and the optional Notiz.
  final Vorbehandlung vorbehandlung;

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

  /// The total number of Schocks: the Vorbehandlung plus those recorded in
  /// the app.
  int get schockAnzahl => vorbehandlung.schocks + schocks.length;

  /// The number of Schocks recorded in the app, without the Vorbehandlung.
  int get schockAnzahlInApp => schocks.length;

  /// The total number of Adrenalin Gaben, including the Vorbehandlung.
  int get adrenalinAnzahl => vorbehandlung.adrenalin + adrenalinGaben.length;

  /// The total number of Amiodaron Gaben, including the Vorbehandlung.
  int get amiodaronAnzahl => vorbehandlung.amiodaron + amiodaronGaben.length;

  /// Whether the Adrenalin card shows the Vorbehandlung count instead of a
  /// Zeitfenster: Adrenalin was given before the Übernahme and none has been
  /// recorded in the app yet.
  bool get zeigeAdrenalinVorbehandlung =>
      vorbehandlung.adrenalin > 0 && adrenalinGaben.isEmpty;

  /// The most recently skipped Rhythmusanalyse, if any.
  RhythmusanalyseUeberspringung? get letzteRhythmusanalyseUeberspringung {
    if (uebersprungeneRhythmusanalysen.isEmpty) return null;
    return uebersprungeneRhythmusanalysen.last;
  }
}

/// The serializable state of a Reanimationsfall.
///
/// Event times, correction times and phase offsets are relative to the
/// Übernahme recorded at the start tap so that the state can be restored with
/// a fresh monotonic clock and a corrected Startzeit never moves an event.
class ReanimationsfallState {
  const ReanimationsfallState({
    required this.id,
    required this.erfassteUebernahme,
    required this.erfassteUebernahmeUtc,
    this.vorbehandlungHinweisAusgeblendet = false,
    required this.utcOffsetMinutes,
    required this.leitlinienprofil,
    required this.vibrationEnabled,
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
    required this.analysephaseBeginne,
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

  /// The Übernahme recorded at the start tap, the origin of every stored time.
  final DateTime erfassteUebernahme;
  final DateTime erfassteUebernahmeUtc;

  /// Whether the `Vorbehandlung erfassen` prompt was dismissed.
  final bool vorbehandlungHinweisAusgeblendet;

  final int utcOffsetMinutes;

  Duration get _startzeitOffset =>
      letzteVorbehandlung(korrekturen)?.startzeit ?? Duration.zero;

  /// The corrected wall-clock Startzeit.
  DateTime get startzeit => erfassteUebernahme.add(_startzeitOffset);

  /// The corrected Startzeit as an absolute instant.
  DateTime get startzeitUtc => erfassteUebernahmeUtc.add(_startzeitOffset);

  final Leitlinienprofil leitlinienprofil;
  final bool vibrationEnabled;
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
  final List<AnalysephaseBeginn> analysephaseBeginne;
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
