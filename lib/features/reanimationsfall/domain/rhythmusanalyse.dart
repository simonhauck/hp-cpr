import 'package:hp_cpr/features/reanimationsfall/domain/protokoll_ereignis.dart';

/// The first-step category of a Rhythmusanalyse result.
enum RhythmusanalyseKategorie { schockbar, nichtSchockbar, rosc, unklar }

/// A recorded result of the Rhythmusanalyse.
///
/// The category drives the first decision (Schockbar or Nicht schockbar).
/// `unbekanntAedSchockbar` and `unbekanntAedNichtSchockbar` record an AED
/// advisory when the underlying rhythm itself is unknown. `Organisiert` is
/// deliberately not a result category.
enum RhythmusanalyseErgebnis {
  kammerflimmern(RhythmusanalyseKategorie.schockbar),
  pulsloseKammertachykardie(RhythmusanalyseKategorie.schockbar),
  unbekanntAedSchockbar(RhythmusanalyseKategorie.schockbar),
  asystolie(RhythmusanalyseKategorie.nichtSchockbar),
  pea(RhythmusanalyseKategorie.nichtSchockbar),
  unbekanntAedNichtSchockbar(RhythmusanalyseKategorie.nichtSchockbar),
  rosc(RhythmusanalyseKategorie.rosc),
  unklar(RhythmusanalyseKategorie.unklar);

  const RhythmusanalyseErgebnis(this.kategorie);

  final RhythmusanalyseKategorie kategorie;
}

/// A Rhythmusanalyse result recorded at a point in the Reanimationsfall.
class RhythmusanalyseEintrag implements ProtokollEreignis {
  const RhythmusanalyseEintrag({
    required this.id,
    required this.zeitpunkt,
    required this.ergebnis,
  });

  @override
  final String id;

  /// The elapsed time since the Startzeit when the result was recorded.
  @override
  final Duration zeitpunkt;

  final RhythmusanalyseErgebnis ergebnis;
}

/// A skipped Rhythmusanalyse.
class RhythmusanalyseUeberspringung implements ProtokollEreignis {
  const RhythmusanalyseUeberspringung({
    required this.id,
    required this.zeitpunkt,
  });

  @override
  final String id;

  /// The elapsed time since the Startzeit when the analysis was skipped.
  @override
  final Duration zeitpunkt;
}
