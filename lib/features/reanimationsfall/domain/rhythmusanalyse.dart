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
class RhythmusanalyseEintrag {
  const RhythmusanalyseEintrag({
    required this.zeitpunkt,
    required this.ergebnis,
  });

  /// The elapsed time since the Startzeit when the result was recorded.
  final Duration zeitpunkt;

  final RhythmusanalyseErgebnis ergebnis;
}

/// A skipped Rhythmusanalyse.
class RhythmusanalyseUeberspringung {
  const RhythmusanalyseUeberspringung({required this.zeitpunkt});

  /// The elapsed time since the Startzeit when the analysis was skipped.
  final Duration zeitpunkt;
}
