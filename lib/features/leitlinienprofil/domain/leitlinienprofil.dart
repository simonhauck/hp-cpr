/// The clinical Leitlinienprofil a Reanimationsfall follows.
///
/// ERC 2025 is the default for German installs; AHA 2025 is the alternative
/// profile. The selected profile is snapshotted when a Reanimationsfall starts.
enum Leitlinienprofil {
  erc2025,
  aha2025;

  /// The length of a compression cycle before the next Rhythmusanalyse.
  Duration get compressionCycle => const Duration(seconds: 120);
}
