import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The German label shown for a recorded Rhythmusanalyse result.
String rhythmusanalyseErgebnisLabel(
  AppLocalizations l10n,
  RhythmusanalyseErgebnis ergebnis,
) {
  return switch (ergebnis) {
    RhythmusanalyseErgebnis.kammerflimmern =>
      '${l10n.rhythmusanalyseSchockbar} – ${l10n.rhythmusanalyseKammerflimmern}',
    RhythmusanalyseErgebnis.pulsloseKammertachykardie =>
      '${l10n.rhythmusanalyseSchockbar} – ${l10n.rhythmusanalysePvt}',
    RhythmusanalyseErgebnis.unbekanntAedSchockbar =>
      '${l10n.rhythmusanalyseSchockbar} – ${l10n.rhythmusanalyseUnbekanntAed}',
    RhythmusanalyseErgebnis.asystolie =>
      '${l10n.rhythmusanalyseNichtSchockbar} – ${l10n.rhythmusanalyseAsystolie}',
    RhythmusanalyseErgebnis.pea =>
      '${l10n.rhythmusanalyseNichtSchockbar} – ${l10n.rhythmusanalysePea}',
    RhythmusanalyseErgebnis.unbekanntAedNichtSchockbar =>
      '${l10n.rhythmusanalyseNichtSchockbar} – ${l10n.rhythmusanalyseUnbekanntAed}',
    RhythmusanalyseErgebnis.rosc => l10n.rhythmusanalyseRosc,
    RhythmusanalyseErgebnis.unklar => l10n.rhythmusanalyseUnklar,
  };
}
