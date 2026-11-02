/// A recorded Schock during a Reanimationsfall.
class SchockEreignis {
  const SchockEreignis({
    required this.id,
    required this.zeitpunkt,
    this.energieJoule,
  });

  /// The stable identity of this event in the Protokoll.
  final String id;

  /// The elapsed time since the Startzeit when the Schock was recorded.
  final Duration zeitpunkt;

  /// The optional Schock energy in joules.
  final int? energieJoule;
}
