import 'package:hp_cpr/features/reanimationsfall/domain/protokoll_ereignis.dart';

/// Why the Zeitnehmer ended the Reanimationsfall.
enum Beendigungsgrund { uebergabe, abbruch, sonstiges }

/// A recorded ROSC event.
class RoscEreignis implements ProtokollEreignis {
  const RoscEreignis({
    required this.id,
    required this.zeitpunkt,
    this.rhythmusanalyseId,
  });

  @override
  final String id;

  /// The elapsed time since the Startzeit when the ROSC was recorded.
  @override
  final Duration zeitpunkt;

  /// The Rhythmusanalyse entry that recorded this ROSC, when it came from the
  /// guided wizard.
  final String? rhythmusanalyseId;
}

/// A recorded Reanimationswiederbeginn after ROSC.
class Reanimationswiederbeginn implements ProtokollEreignis {
  const Reanimationswiederbeginn({required this.id, required this.zeitpunkt});

  @override
  final String id;

  /// The elapsed time since the Startzeit when resuscitation resumed.
  @override
  final Duration zeitpunkt;
}

/// A manual reset of the current Druckphase to a fresh 2-minute cycle.
class DruckphaseNeustart implements ProtokollEreignis {
  const DruckphaseNeustart({required this.id, required this.zeitpunkt});

  @override
  final String id;

  /// The elapsed time since the Startzeit when the cycle was reset.
  @override
  final Duration zeitpunkt;
}

/// The end of a Reanimationsfall, including its reason.
class ReanimationsfallEnde {
  const ReanimationsfallEnde({required this.zeitpunkt, required this.grund});

  final Duration zeitpunkt;
  final Beendigungsgrund grund;
}
