import 'package:hp_cpr/features/reanimationsfall/domain/protokoll_ereignis.dart';

/// The state of the 3–5 minute Adrenalin Zeitfenster.
enum AdrenalinZeitfensterZustand { keine, wartet, faellig, ueberfaellig }

/// A recorded Adrenalin dose.
class AdrenalinGabe implements ProtokollEreignis {
  const AdrenalinGabe({
    required this.id,
    required this.zeitpunkt,
    this.dosisMg = 1,
  });

  @override
  final String id;

  /// The elapsed time since the Startzeit when the dose was recorded.
  @override
  final Duration zeitpunkt;

  /// The administered dose in milligrams.
  final int dosisMg;
}
