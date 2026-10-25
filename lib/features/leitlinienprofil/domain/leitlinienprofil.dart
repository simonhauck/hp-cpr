/// The clinical Leitlinienprofil a Reanimationsfall follows.
///
/// ERC 2025 is the default for German installs; AHA 2025 is the alternative
/// profile. The selected profile is snapshotted when a Reanimationsfall starts.
enum Leitlinienprofil {
  erc2025,
  aha2025;

  /// The length of a compression cycle before the next Rhythmusanalyse.
  Duration get compressionCycle => const Duration(seconds: 120);

  /// How long the Analysephase may pause before the overdue hint appears.
  ///
  /// AHA uses the 10-second pulse-check limit; ERC sets a 5-second
  /// peri-shock-pause target.
  Duration get pauseTarget => switch (this) {
    Leitlinienprofil.aha2025 => const Duration(seconds: 10),
    Leitlinienprofil.erc2025 => const Duration(seconds: 5),
  };

  /// The active Schock count at which the first Adrenalin dose is due.
  int get adrenalinErsteGabeNachSchock => switch (this) {
    Leitlinienprofil.aha2025 => 2,
    Leitlinienprofil.erc2025 => 3,
  };

  /// The active Schock count at which the first Amiodaron dose is suggested.
  int get amiodaronErsteGabeNachSchock => 3;

  /// The active Schock count at which the second Amiodaron dose is suggested.
  ///
  /// ERC 2025 gives 150 mg after shock 5. AHA 2025 lists the second 150 mg
  /// dose without a shock-count trigger, so the next CPR block after the first
  /// dose (shock 4) is used until clinical review confirms the AHA trigger.
  int get amiodaronZweiteGabeNachSchock => switch (this) {
    Leitlinienprofil.aha2025 => 4,
    Leitlinienprofil.erc2025 => 5,
  };

  /// The earliest time in the Adrenalin Zeitfenster.
  Duration get adrenalinZeitfensterFruehestens => const Duration(minutes: 3);

  /// The latest time in the Adrenalin Zeitfenster.
  Duration get adrenalinZeitfensterSpaetestens => const Duration(minutes: 5);
}
