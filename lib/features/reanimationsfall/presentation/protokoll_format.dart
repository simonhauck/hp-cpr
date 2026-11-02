import 'package:flutter/material.dart';

import 'package:hp_cpr/features/messwerte/presentation/messwert_format.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/ereignisse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/schock.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/end_reanimationsfall_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The icon for one Protokoll entry.
IconData protokollEintragIcon(Object daten) {
  return switch (daten) {
    SchockEreignis() => Icons.bolt,
    AdrenalinGabe() => Icons.medication_outlined,
    AmiodaronGabe() => Icons.vaccines_outlined,
    RhythmusanalyseEintrag() => Icons.monitor_heart_outlined,
    RhythmusanalyseUeberspringung() => Icons.skip_next_outlined,
    DruckphaseNeustart() => Icons.restart_alt,
    RoscEreignis() => Icons.favorite_outline,
    Reanimationswiederbeginn() => Icons.replay,
    Messwert(:final typ) => messwertIcon(typ),
    ReanimationsfallNotiz() => Icons.notes,
    ReanimationsfallEnde() => Icons.stop_circle_outlined,
    DateTime() => Icons.play_arrow,
    Duration() => Icons.block,
    _ => Icons.circle_outlined,
  };
}

/// The primary text for one Protokoll entry.
String protokollDatenText(AppLocalizations l10n, Object daten, {int? nummer}) {
  return switch (daten) {
    SchockEreignis(:final energieJoule) =>
      nummer == null
          ? energieJoule == null
                ? l10n.protokollSchockPlain
                : l10n.protokollSchockWithEnergyPlain(energieJoule)
          : energieJoule == null
          ? l10n.eventSchock(nummer)
          : l10n.eventSchockWithEnergy(nummer, energieJoule),
    AdrenalinGabe(:final dosisMg) => l10n.eventAdrenalin(dosisMg),
    AmiodaronGabe(:final dosisMg) => l10n.eventAmiodaron(dosisMg),
    RhythmusanalyseEintrag(:final ergebnis) => l10n.eventRhythmusanalyse(
      rhythmusanalyseErgebnisLabel(l10n, ergebnis),
    ),
    RhythmusanalyseUeberspringung() => l10n.eventRhythmusanalyseSkipped,
    DruckphaseNeustart() => l10n.eventDruckphaseRestarted,
    RoscEreignis() => l10n.eventRosc,
    Reanimationswiederbeginn() => l10n.eventResuscitationResumed,
    Messwert(:final typ) => l10n.eventMesswert(
      messwertTypLabel(l10n, typ),
      formatMesswert(l10n, daten),
    ),
    ReanimationsfallNotiz(:final text) => l10n.eventNotiz(text),
    ReanimationsfallEnde(:final grund) => l10n.eventCaseEnded(
      beendigungsgrundLabel(l10n, grund),
    ),
    DateTime() => l10n.eventCaseStart,
    Duration() => l10n.eventCaseDiscarded,
    _ => '',
  };
}

/// The optional secondary text for one Protokoll entry.
String? protokollDatenDetail(Object daten) {
  return switch (daten) {
    Messwert(:final notiz) => notiz,
    _ => null,
  };
}
