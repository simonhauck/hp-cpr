/// The contextual Amiodaron hint derived from the recorded Schocks and doses.
enum AmiodaronHinweis {
  keine(null),
  ersteGabe(300),
  zweiteGabe(150);

  const AmiodaronHinweis(this.dosisMg);

  /// The dose the hint recommends, or null when no dose is due.
  final int? dosisMg;
}

/// A recorded Amiodaron dose.
class AmiodaronGabe {
  const AmiodaronGabe({required this.zeitpunkt, required this.dosisMg});

  /// The elapsed time since the Startzeit when the dose was recorded.
  final Duration zeitpunkt;

  /// The administered dose in milligrams.
  final int dosisMg;
}
