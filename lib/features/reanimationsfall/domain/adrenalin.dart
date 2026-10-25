/// The state of the 3–5 minute Adrenalin Zeitfenster.
enum AdrenalinZeitfensterZustand { keine, wartet, faellig, ueberfaellig }

/// A recorded Adrenalin dose.
class AdrenalinGabe {
  const AdrenalinGabe({required this.zeitpunkt, this.dosisMg = 1});

  /// The elapsed time since the Startzeit when the dose was recorded.
  final Duration zeitpunkt;

  /// The administered dose in milligrams.
  final int dosisMg;
}
