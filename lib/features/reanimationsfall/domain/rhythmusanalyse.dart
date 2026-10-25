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
    this.notiz,
  });

  /// The elapsed time since the Startzeit when the result was recorded.
  final Duration zeitpunkt;

  final RhythmusanalyseErgebnis ergebnis;

  /// The optional note recorded with the result.
  final String? notiz;

  RhythmusanalyseEintrag copyWith({String? notiz}) {
    return RhythmusanalyseEintrag(
      zeitpunkt: zeitpunkt,
      ergebnis: ergebnis,
      notiz: notiz,
    );
  }
}

/// A later correction of a recorded Rhythmusanalyse note.
///
/// The original [RhythmusanalyseEintrag] keeps its note; this entry is the
/// append-only log record that supersedes it.
class RhythmusanalyseNotizKorrektur {
  const RhythmusanalyseNotizKorrektur({
    required this.eintragIndex,
    required this.zeitpunkt,
    this.notiz,
  });

  /// The index of the corrected entry in the result history.
  final int eintragIndex;

  /// The elapsed time since the Startzeit when the correction was recorded.
  final Duration zeitpunkt;

  final String? notiz;
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
