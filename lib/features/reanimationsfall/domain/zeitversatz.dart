import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/ereignisse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/protokoll.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';

/// Moves a recorded event's case-relative time by [versatz].
///
/// A Reanimationsfall stores every time relative to the Übernahme recorded at
/// the start tap. Moving by the distance to the corrected Startzeit turns it
/// into the time since the Startzeit without touching its wall-clock time.
T verschobenesEreignis<T extends Object>(T ereignis, Duration versatz) {
  if (versatz == Duration.zero) return ereignis;
  final Object verschoben = switch (ereignis) {
    SchockEreignis(:final id, :final zeitpunkt, :final energieJoule) =>
      SchockEreignis(
        id: id,
        zeitpunkt: zeitpunkt + versatz,
        energieJoule: energieJoule,
      ),
    AdrenalinGabe(:final id, :final zeitpunkt, :final dosisMg) => AdrenalinGabe(
      id: id,
      zeitpunkt: zeitpunkt + versatz,
      dosisMg: dosisMg,
    ),
    AmiodaronGabe(:final id, :final zeitpunkt, :final dosisMg) => AmiodaronGabe(
      id: id,
      zeitpunkt: zeitpunkt + versatz,
      dosisMg: dosisMg,
    ),
    RhythmusanalyseEintrag(:final id, :final zeitpunkt, :final ergebnis) =>
      RhythmusanalyseEintrag(
        id: id,
        zeitpunkt: zeitpunkt + versatz,
        ergebnis: ergebnis,
      ),
    RhythmusanalyseUeberspringung(:final id, :final zeitpunkt) =>
      RhythmusanalyseUeberspringung(id: id, zeitpunkt: zeitpunkt + versatz),
    DruckphaseNeustart(:final id, :final zeitpunkt) => DruckphaseNeustart(
      id: id,
      zeitpunkt: zeitpunkt + versatz,
    ),
    RoscEreignis(:final id, :final zeitpunkt, :final rhythmusanalyseId) =>
      RoscEreignis(
        id: id,
        zeitpunkt: zeitpunkt + versatz,
        rhythmusanalyseId: rhythmusanalyseId,
      ),
    Reanimationswiederbeginn(:final id, :final zeitpunkt) =>
      Reanimationswiederbeginn(id: id, zeitpunkt: zeitpunkt + versatz),
    ReanimationsfallNotiz(:final id, :final zeitpunkt, :final text) =>
      ReanimationsfallNotiz(id: id, zeitpunkt: zeitpunkt + versatz, text: text),
    Messwert() => _verschobenerMesswert(ereignis, versatz),
    ReanimationsfallEnde(:final zeitpunkt, :final grund) =>
      ReanimationsfallEnde(zeitpunkt: zeitpunkt + versatz, grund: grund),
    Uebernahme(:final zeitpunkt) => Uebernahme(zeitpunkt: zeitpunkt + versatz),
    Duration() => ereignis + versatz,
    _ => ereignis,
  };
  return verschoben as T;
}

/// Moves every time in [korrektur] by [versatz].
ProtokollKorrektur verschobeneKorrektur(
  ProtokollKorrektur korrektur,
  Duration versatz,
) {
  if (versatz == Duration.zero) return korrektur;
  return switch (korrektur) {
    ProtokollEintragEntfernt() ||
    ProtokollEintragWiederhergestellt() ||
    VorbehandlungKorrigiert() => korrektur,
    SchockKorrigiert(:final ziel, :final zeitpunkt, :final energieJoule) =>
      SchockKorrigiert(
        ziel: ziel,
        zeitpunkt: zeitpunkt + versatz,
        energieJoule: energieJoule,
      ),
    AdrenalinKorrigiert(:final ziel, :final zeitpunkt, :final dosisMg) =>
      AdrenalinKorrigiert(
        ziel: ziel,
        zeitpunkt: zeitpunkt + versatz,
        dosisMg: dosisMg,
      ),
    AmiodaronKorrigiert(:final ziel, :final zeitpunkt, :final dosisMg) =>
      AmiodaronKorrigiert(
        ziel: ziel,
        zeitpunkt: zeitpunkt + versatz,
        dosisMg: dosisMg,
      ),
    MesswertKorrigiert(:final ziel, :final ersatz) => MesswertKorrigiert(
      ziel: ziel,
      ersatz: _verschobenerMesswert(ersatz, versatz),
    ),
    NotizKorrigiert(:final ziel, :final zeitpunkt, :final text) =>
      NotizKorrigiert(ziel: ziel, zeitpunkt: zeitpunkt + versatz, text: text),
    RhythmusanalyseKorrigiert(:final ziel, :final zeitpunkt, :final ergebnis) =>
      RhythmusanalyseKorrigiert(
        ziel: ziel,
        zeitpunkt: zeitpunkt + versatz,
        ergebnis: ergebnis,
      ),
    ZeitpunktKorrigiert(:final ziel, :final zeitpunkt) => ZeitpunktKorrigiert(
      ziel: ziel,
      zeitpunkt: zeitpunkt + versatz,
    ),
    RoscKorrigiert(:final ziel, :final zeitpunkt) => RoscKorrigiert(
      ziel: ziel,
      zeitpunkt: zeitpunkt + versatz,
    ),
  };
}

Messwert _verschobenerMesswert(Messwert messwert, Duration versatz) {
  final zeitpunkt = messwert.zeitpunkt + versatz;
  return switch (messwert) {
    TemperaturMesswert(:final id, :final celsius, :final notiz) =>
      TemperaturMesswert(
        id: id,
        zeitpunkt: zeitpunkt,
        celsius: celsius,
        notiz: notiz,
      ),
    BlutzuckerMesswert(:final id, :final mgDl, :final notiz) =>
      BlutzuckerMesswert(
        id: id,
        zeitpunkt: zeitpunkt,
        mgDl: mgDl,
        notiz: notiz,
      ),
    BlutdruckMesswert(
      :final id,
      :final systolisch,
      :final diastolisch,
      :final notiz,
    ) =>
      BlutdruckMesswert(
        id: id,
        zeitpunkt: zeitpunkt,
        systolisch: systolisch,
        diastolisch: diastolisch,
        notiz: notiz,
      ),
    HerzfrequenzMesswert(:final id, :final proMinute, :final notiz) =>
      HerzfrequenzMesswert(
        id: id,
        zeitpunkt: zeitpunkt,
        proMinute: proMinute,
        notiz: notiz,
      ),
  };
}
