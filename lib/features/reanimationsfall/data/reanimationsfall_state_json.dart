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
    'demoMode': state.demoMode,
    'demoOffset': _millis(state.demoOffset),
    'zustand': state.zustand.name,
    'phase': state.phase.name,
    'nextEreignisId': state.nextEreignisId,
    'compressionCycleStartOffset': _millis(state.compressionCycleStartOffset),
    'compressionRemainingAtPause': _millis(state.compressionRemainingAtPause),
    'analysephaseStartOffset': _nullableMillis(state.analysephaseStartOffset),
    'adrenalinAusloesendesErgebnis': state.adrenalinAusloesendesErgebnis?.name,
    'schocks': [
      for (final schock in state.schocks)
        {
          'id': schock.id,
          'zeitpunkt': _millis(schock.zeitpunkt),
          'energieJoule': schock.energieJoule,
        },
    ],
    'adrenalinGaben': [
      for (final gabe in state.adrenalinGaben)
        {
          'id': gabe.id,
          'zeitpunkt': _millis(gabe.zeitpunkt),
          'dosisMg': gabe.dosisMg,
        },
    ],
    'amiodaronGaben': [
      for (final gabe in state.amiodaronGaben)
        {
          'id': gabe.id,
          'zeitpunkt': _millis(gabe.zeitpunkt),
          'dosisMg': gabe.dosisMg,
        },
    ],
    'uebersprungeneRhythmusanalysen': [
      for (final entry in state.uebersprungeneRhythmusanalysen)
        {'id': entry.id, 'zeitpunkt': _millis(entry.zeitpunkt)},
    ],
    'rhythmusanalyseEintraege': [
      for (final entry in state.rhythmusanalyseEintraege)
        {
          'id': entry.id,
          'zeitpunkt': _millis(entry.zeitpunkt),
          'ergebnis': entry.ergebnis.name,
        },
    ],
    'druckphaseNeustarts': [
      for (final entry in state.druckphaseNeustarts)
        {'id': entry.id, 'zeitpunkt': _millis(entry.zeitpunkt)},
    ],
    'messwerte': [
      for (final messwert in state.messwerte) _messwertToJson(messwert),
    ],
    'notizen': [
      for (final notiz in state.notizen)
        {
          'id': notiz.id,
          'zeitpunkt': _millis(notiz.zeitpunkt),
          'text': notiz.text,
        },
    ],
    'roscEreignisse': [
      for (final entry in state.roscEreignisse)
        {
          'id': entry.id,
          'zeitpunkt': _millis(entry.zeitpunkt),
          'rhythmusanalyseId': entry.rhythmusanalyseId,
        },
    ],
    'wiederbeginnEreignisse': [
      for (final entry in state.wiederbeginnEreignisse)
        {'id': entry.id, 'zeitpunkt': _millis(entry.zeitpunkt)},
    ],
    'korrekturen': [
      for (final korrektur in state.korrekturen) _korrekturToJson(korrektur),
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

  List<dynamic> list(Object? value) => value as List<dynamic>? ?? const [];

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
    demoMode: json['demoMode'] as bool? ?? false,
    demoOffset: _duration(json['demoOffset']),
    zustand: ReanimationsfallZustand.values.byName(json['zustand'] as String),
    phase: Reanimationsphase.values.byName(json['phase'] as String),
    nextEreignisId: json['nextEreignisId'] as int? ?? 0,
    compressionCycleStartOffset: _duration(json['compressionCycleStartOffset']),
    compressionRemainingAtPause: _duration(json['compressionRemainingAtPause']),
    analysephaseStartOffset: _nullableDuration(json['analysephaseStartOffset']),
    adrenalinAusloesendesErgebnis: _rhythmusanalyseErgebnis(
      json['adrenalinAusloesendesErgebnis'],
    ),
    schocks: [
      for (final (index, item) in list(json['schocks']).indexed)
        SchockEreignis(
          id: _id(map(item), 'legacy-schock-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          energieJoule: map(item)['energieJoule'] as int?,
        ),
    ],
    adrenalinGaben: [
      for (final (index, item) in list(json['adrenalinGaben']).indexed)
        AdrenalinGabe(
          id: _id(map(item), 'legacy-adrenalin-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          dosisMg: map(item)['dosisMg'] as int,
        ),
    ],
    amiodaronGaben: [
      for (final (index, item) in list(json['amiodaronGaben']).indexed)
        AmiodaronGabe(
          id: _id(map(item), 'legacy-amiodaron-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          dosisMg: map(item)['dosisMg'] as int,
        ),
    ],
    uebersprungeneRhythmusanalysen: [
      for (final (index, item) in list(
        json['uebersprungeneRhythmusanalysen'],
      ).indexed)
        RhythmusanalyseUeberspringung(
          id: _id(map(item), 'legacy-ueberspringung-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
        ),
    ],
    rhythmusanalyseEintraege: [
      for (final (index, item) in list(
        json['rhythmusanalyseEintraege'],
      ).indexed)
        RhythmusanalyseEintrag(
          id: _id(map(item), 'legacy-rhythmusanalyse-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          ergebnis: RhythmusanalyseErgebnis.values.byName(
            map(item)['ergebnis'] as String,
          ),
        ),
    ],
    druckphaseNeustarts: [
      for (final (index, item) in list(json['druckphaseNeustarts']).indexed)
        DruckphaseNeustart(
          id: _id(map(item), 'legacy-druckphase-neustart-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
        ),
    ],
    messwerte: [
      for (final (index, item) in list(json['messwerte']).indexed)
        _messwertFromJson(map(item), fallbackId: 'legacy-messwert-$index'),
    ],
    notizen: [
      for (final (index, item) in list(json['notizen']).indexed)
        ReanimationsfallNotiz(
          id: _id(map(item), 'legacy-notiz-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          text: map(item)['text'] as String,
        ),
    ],
    roscEreignisse: [
      for (final (index, item) in list(json['roscEreignisse']).indexed)
        RoscEreignis(
          id: _id(map(item), 'legacy-rosc-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
          rhythmusanalyseId: map(item)['rhythmusanalyseId'] as String?,
        ),
    ],
    wiederbeginnEreignisse: [
      for (final (index, item) in list(json['wiederbeginnEreignisse']).indexed)
        Reanimationswiederbeginn(
          id: _id(map(item), 'legacy-wiederbeginn-$index'),
          zeitpunkt: _duration(map(item)['zeitpunkt']),
        ),
    ],
    korrekturen: [
      for (final item in list(json['korrekturen']))
        _korrekturFromJson(map(item)),
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

String _id(Map<String, dynamic> json, String fallback) =>
    json['id'] as String? ?? fallback;

RhythmusanalyseErgebnis? _rhythmusanalyseErgebnis(Object? value) =>
    value == null
    ? null
    : RhythmusanalyseErgebnis.values.byName(value as String);

Map<String, dynamic> _messwertToJson(Messwert messwert) {
  final base = {
    'id': messwert.id,
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

Messwert _messwertFromJson(
  Map<String, dynamic> json, {
  required String fallbackId,
}) {
  final id = _id(json, fallbackId);
  final zeitpunkt = _duration(json['zeitpunkt']);
  final notiz = json['notiz'] as String?;

  return switch (MesswertTyp.values.byName(json['typ'] as String)) {
    MesswertTyp.temperatur => TemperaturMesswert(
      id: id,
      zeitpunkt: zeitpunkt,
      celsius: (json['celsius'] as num).toDouble(),
      notiz: notiz,
    ),
    MesswertTyp.blutzucker => BlutzuckerMesswert(
      id: id,
      zeitpunkt: zeitpunkt,
      mgDl: json['mgDl'] as int,
      notiz: notiz,
    ),
    MesswertTyp.blutdruck => BlutdruckMesswert(
      id: id,
      zeitpunkt: zeitpunkt,
      systolisch: json['systolisch'] as int,
      diastolisch: json['diastolisch'] as int,
      notiz: notiz,
    ),
    MesswertTyp.herzfrequenz => HerzfrequenzMesswert(
      id: id,
      zeitpunkt: zeitpunkt,
      proMinute: json['proMinute'] as int,
      notiz: notiz,
    ),
  };
}

Map<String, dynamic> _korrekturToJson(ProtokollKorrektur korrektur) {
  final base = {
    'zielTyp': korrektur.ziel.typ.name,
    'zielId': korrektur.ziel.id,
  };

  return switch (korrektur) {
    ProtokollEintragEntfernt() => {...base, 'typ': 'entfernt'},
    ProtokollEintragWiederhergestellt() => {
      ...base,
      'typ': 'wiederhergestellt',
    },
    SchockKorrigiert(:final zeitpunkt, :final energieJoule) => {
      ...base,
      'typ': 'schock',
      'zeitpunkt': _millis(zeitpunkt),
      'energieJoule': energieJoule,
    },
    AdrenalinKorrigiert(:final zeitpunkt, :final dosisMg) => {
      ...base,
      'typ': 'adrenalin',
      'zeitpunkt': _millis(zeitpunkt),
      'dosisMg': dosisMg,
    },
    AmiodaronKorrigiert(:final zeitpunkt, :final dosisMg) => {
      ...base,
      'typ': 'amiodaron',
      'zeitpunkt': _millis(zeitpunkt),
      'dosisMg': dosisMg,
    },
    MesswertKorrigiert(:final ersatz) => {
      ...base,
      'typ': 'messwert',
      'messwert': _messwertToJson(ersatz),
    },
    NotizKorrigiert(:final zeitpunkt, :final text) => {
      ...base,
      'typ': 'notiz',
      'zeitpunkt': _millis(zeitpunkt),
      'text': text,
    },
    RhythmusanalyseKorrigiert(:final zeitpunkt, :final ergebnis) => {
      ...base,
      'typ': 'rhythmusanalyse',
      'zeitpunkt': _millis(zeitpunkt),
      'ergebnis': ergebnis.name,
    },
    ZeitpunktKorrigiert(:final zeitpunkt) => {
      ...base,
      'typ': 'zeitpunkt',
      'zeitpunkt': _millis(zeitpunkt),
    },
    RoscKorrigiert(:final zeitpunkt) => {
      ...base,
      'typ': 'rosc',
      'zeitpunkt': _millis(zeitpunkt),
    },
  };
}

ProtokollKorrektur _korrekturFromJson(Map<String, dynamic> json) {
  final ziel = ProtokollEintragRef(
    typ: ProtokollEintragTyp.values.byName(json['zielTyp'] as String),
    id: json['zielId'] as String,
  );

  return switch (json['typ'] as String) {
    'entfernt' => ProtokollEintragEntfernt(ziel: ziel),
    'wiederhergestellt' => ProtokollEintragWiederhergestellt(ziel: ziel),
    'schock' => SchockKorrigiert(
      ziel: ziel,
      zeitpunkt: _duration(json['zeitpunkt']),
      energieJoule: json['energieJoule'] as int?,
    ),
    'adrenalin' => AdrenalinKorrigiert(
      ziel: ziel,
      zeitpunkt: _duration(json['zeitpunkt']),
      dosisMg: json['dosisMg'] as int,
    ),
    'amiodaron' => AmiodaronKorrigiert(
      ziel: ziel,
      zeitpunkt: _duration(json['zeitpunkt']),
      dosisMg: json['dosisMg'] as int,
    ),
    'messwert' => MesswertKorrigiert(
      ziel: ziel,
      ersatz: _messwertFromJson(
        Map<String, dynamic>.from(json['messwert'] as Map),
        fallbackId: ziel.id,
      ),
    ),
    'notiz' => NotizKorrigiert(
      ziel: ziel,
      zeitpunkt: _duration(json['zeitpunkt']),
      text: json['text'] as String,
    ),
    'rhythmusanalyse' => RhythmusanalyseKorrigiert(
      ziel: ziel,
      zeitpunkt: _duration(json['zeitpunkt']),
      ergebnis: RhythmusanalyseErgebnis.values.byName(
        json['ergebnis'] as String,
      ),
    ),
    'zeitpunkt' => ZeitpunktKorrigiert(
      ziel: ziel,
      zeitpunkt: _duration(json['zeitpunkt']),
    ),
    'rosc' => RoscKorrigiert(
      ziel: ziel,
      zeitpunkt: _duration(json['zeitpunkt']),
    ),
    final String typ => throw FormatException('unknown correction type: $typ'),
  };
}
