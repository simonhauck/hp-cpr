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
}
