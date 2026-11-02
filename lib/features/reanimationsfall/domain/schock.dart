import 'package:hp_cpr/features/reanimationsfall/domain/protokoll_ereignis.dart';

/// A recorded Schock during a Reanimationsfall.
class SchockEreignis implements ProtokollEreignis {
  const SchockEreignis({
    required this.id,
    required this.zeitpunkt,
    this.energieJoule,
  });

  @override
  final String id;

  /// The elapsed time since the Startzeit when the Schock was recorded.
  @override
  final Duration zeitpunkt;

  /// The optional Schock energy in joules.
  final int? energieJoule;
}
