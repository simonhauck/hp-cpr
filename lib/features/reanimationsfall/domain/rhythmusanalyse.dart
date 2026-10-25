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

/// Why the Zeitnehmer skipped the Rhythmusanalyse.
enum RhythmusanalyseUebersprungenGrund { keineZeit, aedUebernimmt, sonstiges }

/// A skipped Rhythmusanalyse, recorded even when no reason was given.
class RhythmusanalyseUeberspringung {
  const RhythmusanalyseUeberspringung({required this.zeitpunkt, this.grund});

  /// The elapsed time since the Startzeit when the analysis was skipped.
  final Duration zeitpunkt;

  /// The optional reason selected by the Zeitnehmer.
  final RhythmusanalyseUebersprungenGrund? grund;
}
