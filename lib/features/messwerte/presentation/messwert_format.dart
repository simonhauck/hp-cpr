import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The icon shown for a Messwert type.
IconData messwertIcon(MesswertTyp typ) {
  return switch (typ) {
    MesswertTyp.temperatur => Icons.thermostat,
    MesswertTyp.blutzucker => Icons.water_drop_outlined,
    MesswertTyp.blutdruck => Icons.speed,
    MesswertTyp.herzfrequenz => Icons.favorite_border,
  };
}

/// The German label for a Messwert type.
String messwertTypLabel(AppLocalizations l10n, MesswertTyp typ) {
  return switch (typ) {
    MesswertTyp.temperatur => l10n.messwertTemperatur,
    MesswertTyp.blutzucker => l10n.messwertBlutzucker,
    MesswertTyp.blutdruck => l10n.messwertBlutdruck,
    MesswertTyp.herzfrequenz => l10n.messwertHerzfrequenz,
  };
}

/// The formatted value with its unit.
String formatMesswert(AppLocalizations l10n, Messwert messwert) {
  return switch (messwert) {
    TemperaturMesswert(:final celsius) => l10n.messwertTemperaturValue(
      _formatDecimal(celsius),
    ),
    BlutzuckerMesswert(:final mgDl) => l10n.messwertBlutzuckerValue(mgDl),
    BlutdruckMesswert(:final systolisch, :final diastolisch) =>
      l10n.messwertBlutdruckValue(systolisch, diastolisch),
    HerzfrequenzMesswert(:final proMinute) => l10n.messwertHerzfrequenzValue(
      proMinute,
    ),
  };
}

String _formatDecimal(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
