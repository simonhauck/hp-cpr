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

/// A Schock together with its current undo state.
class SchockEintrag {
  const SchockEintrag({required this.ereignis, required this.rueckgaengig});

  final SchockEreignis ereignis;
  final bool rueckgaengig;

  Duration get zeitpunkt => ereignis.zeitpunkt;

  int? get energieJoule => ereignis.energieJoule;
}
