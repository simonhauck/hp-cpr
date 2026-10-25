/// A recorded Schock during a Reanimationsfall.
class SchockEreignis {
  const SchockEreignis({required this.zeitpunkt, this.energieJoule});

  /// The elapsed time since the Startzeit when the Schock was recorded.
  final Duration zeitpunkt;

  /// The optional Schock energy in joules.
  final int? energieJoule;

  SchockEreignis copyWith({int? energieJoule}) {
    return SchockEreignis(
      zeitpunkt: zeitpunkt,
      energieJoule: energieJoule ?? this.energieJoule,
    );
  }
}

/// A separate log entry that marks a recorded Schock as undone.
class SchockRueckgaengig {
  const SchockRueckgaengig({
    required this.schockIndex,
    required this.zeitpunkt,
  });

  /// The index of the Schock in the case's Schock list.
  final int schockIndex;

  /// The elapsed time since the Startzeit when the Schock was undone.
  final Duration zeitpunkt;
}

/// A later correction of a recorded Schock's energy.
///
/// The original [SchockEreignis] keeps its own energy; this entry is the
/// append-only log record that supersedes it.
class SchockKorrektur {
  const SchockKorrektur({
    required this.schockIndex,
    required this.zeitpunkt,
    required this.energieJoule,
  });

  /// The index of the corrected Schock in the case's Schock list.
  final int schockIndex;

  /// The elapsed time since the Startzeit when the correction was recorded.
  final Duration zeitpunkt;

  final int energieJoule;
}

/// A Schock together with its current undo and correction state.
class SchockEintrag {
  const SchockEintrag({
    required this.ereignis,
    required this.rueckgaengig,
    this.korrigierteEnergieJoule,
  });

  final SchockEreignis ereignis;
  final bool rueckgaengig;

  /// The energy from the latest correction, if one was recorded.
  final int? korrigierteEnergieJoule;

  Duration get zeitpunkt => ereignis.zeitpunkt;

  /// The effective energy: the latest correction or the originally recorded one.
  int? get energieJoule => korrigierteEnergieJoule ?? ereignis.energieJoule;
}
