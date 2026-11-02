/// Why the Zeitnehmer ended the Reanimationsfall.
enum Beendigungsgrund { uebergabe, abbruch, sonstiges }

/// A recorded ROSC event.
class RoscEreignis {
  const RoscEreignis({
    required this.id,
    required this.zeitpunkt,
    this.rhythmusanalyseId,
  });

  /// The stable identity of this event in the Protokoll.
  final String id;

  /// The elapsed time since the Startzeit when the ROSC was recorded.
  final Duration zeitpunkt;

  /// The Rhythmusanalyse entry that recorded this ROSC, when it came from the
  /// guided wizard.
  final String? rhythmusanalyseId;
}

/// A recorded Reanimationswiederbeginn after ROSC.
class Reanimationswiederbeginn {
  const Reanimationswiederbeginn({required this.id, required this.zeitpunkt});

  /// The stable identity of this event in the Protokoll.
  final String id;

  /// The elapsed time since the Startzeit when resuscitation resumed.
  final Duration zeitpunkt;
}

/// A manual reset of the current Druckphase to a fresh 2-minute cycle.
class DruckphaseNeustart {
  const DruckphaseNeustart({required this.id, required this.zeitpunkt});

  /// The stable identity of this event in the Protokoll.
  final String id;

  /// The elapsed time since the Startzeit when the cycle was reset.
  final Duration zeitpunkt;
}

/// The end of a Reanimationsfall, including its reason.
class ReanimationsfallEnde {
  const ReanimationsfallEnde({required this.zeitpunkt, required this.grund});

  final Duration zeitpunkt;
  final Beendigungsgrund grund;
}
