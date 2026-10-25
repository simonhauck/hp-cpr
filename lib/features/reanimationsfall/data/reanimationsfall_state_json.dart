import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';

/// Encodes a [ReanimationsfallState] for the local store.
Map<String, dynamic> reanimationsfallStateToJson(ReanimationsfallState state) {
  return {
    'id': state.id,
    'startzeit': state.startzeit.toIso8601String(),
    'startzeitUtc': state.startzeitUtc.toUtc().toIso8601String(),
    'utcOffsetMinutes': state.utcOffsetMinutes,
    'leitlinienprofil': state.leitlinienprofil.name,
    'vibrationEnabled': state.vibrationEnabled,
    'soundEnabled': state.soundEnabled,
    'zustand': state.zustand.name,
    'phase': state.phase.name,
    'compressionCycleStartOffset': _millis(state.compressionCycleStartOffset),
    'compressionRemainingAtPause': _millis(state.compressionRemainingAtPause),
    'analysephaseStartOffset': _nullableMillis(state.analysephaseStartOffset),
    'isSchockpause': state.isSchockpause,
    'schockpauseWasDue': state.schockpauseWasDue,
    'schockpauseOverdue': _millis(state.schockpauseOverdue),
    'schockpauseOpeningSchockIndex': state.schockpauseOpeningSchockIndex,
    'rhythmusanalyseErgebnis': state.rhythmusanalyseErgebnis?.name,
    'rhythmusanalyseNotiz': state.rhythmusanalyseNotiz,
    'adrenalinAusloesendesErgebnis': state.adrenalinAusloesendesErgebnis?.name,
    'schocks': [
      for (final schock in state.schocks)
        {
          'zeitpunkt': _millis(schock.zeitpunkt),
          'energieJoule': schock.energieJoule,
        },
    ],
    'schockRueckgaengigkeiten': [
      for (final entry in state.schockRueckgaengigkeiten)
        {
          'schockIndex': entry.schockIndex,
          'zeitpunkt': _millis(entry.zeitpunkt),
        },
    ],
    'adrenalinGaben': [
      for (final gabe in state.adrenalinGaben)
        {'zeitpunkt': _millis(gabe.zeitpunkt), 'dosisMg': gabe.dosisMg},
    ],
    'amiodaronGaben': [
      for (final gabe in state.amiodaronGaben)
        {'zeitpunkt': _millis(gabe.zeitpunkt), 'dosisMg': gabe.dosisMg},
    ],
    'uebersprungeneRhythmusanalysen': [
      for (final entry in state.uebersprungeneRhythmusanalysen)
        {'zeitpunkt': _millis(entry.zeitpunkt), 'grund': entry.grund?.name},
    ],
    'rhythmusanalyseEintraege': [
      for (final entry in state.rhythmusanalyseEintraege)
        {
          'zeitpunkt': _millis(entry.zeitpunkt),
          'ergebnis': entry.ergebnis.name,
          'notiz': entry.notiz,
        },
    ],
    'messwerte': [
      for (final messwert in state.messwerte) _messwertToJson(messwert),
    ],
    'notizen': [
      for (final notiz in state.notizen)
        {'zeitpunkt': _millis(notiz.zeitpunkt), 'text': notiz.text},
    ],
    'roscEreignisse': [
      for (final entry in state.roscEreignisse)
        {'zeitpunkt': _millis(entry.zeitpunkt)},
    ],
    'wiederbeginnEreignisse': [
      for (final entry in state.wiederbeginnEreignisse)
        {'zeitpunkt': _millis(entry.zeitpunkt)},
    ],
    'abschnitte': [
      for (final abschnitt in state.abschnitte)
        {
          'index': abschnitt.index,
          'start': _millis(abschnitt.start),
          'ende': _nullableMillis(abschnitt.ende),
        },
    ],
    'ende': state.ende == null
        ? null
        : {
            'zeitpunkt': _millis(state.ende!.zeitpunkt),
            'grund': state.ende!.grund.name,
          },
    'verworfenAm': _nullableMillis(state.verworfenAm),
  };
}

/// Decodes a [ReanimationsfallState] from the local store.
ReanimationsfallState reanimationsfallStateFromJson(Map<String, dynamic> json) {
  Map<String, dynamic> map(Object? value) =>
      Map<String, dynamic>.from(value! as Map);

  return ReanimationsfallState(
    id: json['id'] as String,
    startzeit: DateTime.parse(json['startzeit'] as String),
    startzeitUtc: DateTime.parse(json['startzeitUtc'] as String).toUtc(),
    utcOffsetMinutes: json['utcOffsetMinutes'] as int,
    leitlinienprofil: Leitlinienprofil.values.byName(
      json['leitlinienprofil'] as String,
    ),
    vibrationEnabled: json['vibrationEnabled'] as bool,
    soundEnabled: json['soundEnabled'] as bool,
    zustand: ReanimationsfallZustand.values.byName(json['zustand'] as String),
    phase: Reanimationsphase.values.byName(json['phase'] as String),
    compressionCycleStartOffset: _duration(json['compressionCycleStartOffset']),
    compressionRemainingAtPause: _duration(json['compressionRemainingAtPause']),
    analysephaseStartOffset: _nullableDuration(json['analysephaseStartOffset']),
    isSchockpause: json['isSchockpause'] as bool,
    schockpauseWasDue: json['schockpauseWasDue'] as bool,
    schockpauseOverdue: _duration(json['schockpauseOverdue']),
    schockpauseOpeningSchockIndex:
        json['schockpauseOpeningSchockIndex'] as int?,
    rhythmusanalyseErgebnis: _rhythmusanalyseErgebnis(
      json['rhythmusanalyseErgebnis'],
    ),
    rhythmusanalyseNotiz: json['rhythmusanalyseNotiz'] as String?,
    adrenalinAusloesendesErgebnis: _rhythmusanalyseErgebnis(
      json['adrenalinAusloesendesErgebnis'],
    ),
    schocks: [
      for (final item in (json['schocks'] as List<dynamic>? ?? const []))
        SchockEreignis(
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          energieJoule: map(item)['energieJoule'] as int?,
        ),
    ],
    schockRueckgaengigkeiten: [
      for (final item
          in (json['schockRueckgaengigkeiten'] as List<dynamic>? ?? const []))
        SchockRueckgaengig(
          schockIndex: map(item)['schockIndex'] as int,
          zeitpunkt: _duration(map(item)['zeitpunkt']),
        ),
    ],
    adrenalinGaben: [
      for (final item in (json['adrenalinGaben'] as List<dynamic>? ?? const []))
        AdrenalinGabe(
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          dosisMg: map(item)['dosisMg'] as int,
        ),
    ],
    amiodaronGaben: [
      for (final item in (json['amiodaronGaben'] as List<dynamic>? ?? const []))
        AmiodaronGabe(
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          dosisMg: map(item)['dosisMg'] as int,
        ),
    ],
    uebersprungeneRhythmusanalysen: [
      for (final item
          in (json['uebersprungeneRhythmusanalysen'] as List<dynamic>? ??
              const []))
        RhythmusanalyseUeberspringung(
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          grund: _uebersprungenGrund(map(item)['grund']),
        ),
    ],
    rhythmusanalyseEintraege: [
      for (final item
          in (json['rhythmusanalyseEintraege'] as List<dynamic>? ?? const []))
        RhythmusanalyseEintrag(
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          ergebnis: RhythmusanalyseErgebnis.values.byName(
            map(item)['ergebnis'] as String,
          ),
          notiz: map(item)['notiz'] as String?,
        ),
    ],
    messwerte: [
      for (final item in (json['messwerte'] as List<dynamic>? ?? const []))
        _messwertFromJson(map(item)),
    ],
    notizen: [
      for (final item in (json['notizen'] as List<dynamic>? ?? const []))
        ReanimationsfallNotiz(
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          text: map(item)['text'] as String,
        ),
    ],
    roscEreignisse: [
      for (final item in (json['roscEreignisse'] as List<dynamic>? ?? const []))
        RoscEreignis(zeitpunkt: _duration(map(item)['zeitpunkt'])),
    ],
    wiederbeginnEreignisse: [
      for (final item
          in (json['wiederbeginnEreignisse'] as List<dynamic>? ?? const []))
        Reanimationswiederbeginn(zeitpunkt: _duration(map(item)['zeitpunkt'])),
    ],
    abschnitte: [
      for (final item in (json['abschnitte'] as List<dynamic>? ?? const []))
        Reanimationsabschnitt(
          index: map(item)['index'] as int,
          start: _duration(map(item)['start']),
          ende: _nullableDuration(map(item)['ende']),
        ),
    ],
    ende: json['ende'] == null
        ? null
        : ReanimationsfallEnde(
            zeitpunkt: _duration(map(json['ende'])['zeitpunkt']),
            grund: Beendigungsgrund.values.byName(
              map(json['ende'])['grund'] as String,
            ),
          ),
    verworfenAm: _nullableDuration(json['verworfenAm']),
  );
}

int _millis(Duration duration) => duration.inMilliseconds;

int? _nullableMillis(Duration? duration) => duration?.inMilliseconds;

Duration _duration(Object? value) => Duration(milliseconds: value as int? ?? 0);

Duration? _nullableDuration(Object? value) =>
    value == null ? null : Duration(milliseconds: value as int);

RhythmusanalyseErgebnis? _rhythmusanalyseErgebnis(Object? value) =>
    value == null
    ? null
    : RhythmusanalyseErgebnis.values.byName(value as String);

RhythmusanalyseUebersprungenGrund? _uebersprungenGrund(Object? value) =>
    value == null
    ? null
    : RhythmusanalyseUebersprungenGrund.values.byName(value as String);

Map<String, dynamic> _messwertToJson(Messwert messwert) {
  final base = {
    'typ': messwert.typ.name,
    'zeitpunkt': _millis(messwert.zeitpunkt),
    'notiz': messwert.notiz,
  };

  return switch (messwert) {
    TemperaturMesswert(:final celsius) => {...base, 'celsius': celsius},
    BlutzuckerMesswert(:final mgDl) => {...base, 'mgDl': mgDl},
    BlutdruckMesswert(:final systolisch, :final diastolisch) => {
      ...base,
      'systolisch': systolisch,
      'diastolisch': diastolisch,
    },
    HerzfrequenzMesswert(:final proMinute) => {...base, 'proMinute': proMinute},
  };
}

Messwert _messwertFromJson(Map<String, dynamic> json) {
  final zeitpunkt = _duration(json['zeitpunkt']);
  final notiz = json['notiz'] as String?;

  return switch (MesswertTyp.values.byName(json['typ'] as String)) {
    MesswertTyp.temperatur => TemperaturMesswert(
      zeitpunkt: zeitpunkt,
      celsius: (json['celsius'] as num).toDouble(),
      notiz: notiz,
    ),
    MesswertTyp.blutzucker => BlutzuckerMesswert(
      zeitpunkt: zeitpunkt,
      mgDl: json['mgDl'] as int,
      notiz: notiz,
    ),
    MesswertTyp.blutdruck => BlutdruckMesswert(
      zeitpunkt: zeitpunkt,
      systolisch: json['systolisch'] as int,
      diastolisch: json['diastolisch'] as int,
      notiz: notiz,
    ),
    MesswertTyp.herzfrequenz => HerzfrequenzMesswert(
      zeitpunkt: zeitpunkt,
      proMinute: json['proMinute'] as int,
      notiz: notiz,
    ),
  };
}
