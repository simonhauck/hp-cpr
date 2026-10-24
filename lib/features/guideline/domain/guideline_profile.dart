/// The clinical guideline standard a Reanimationsfall follows.
///
/// ERC 2025 is the default for German installs; AHA 2025 is the alternative
/// profile. The selected standard is snapshotted when a case starts.
enum GuidelineProfile {
  erc2025,
  aha2025;

  /// The length of a compression cycle before the next Rhythmusanalyse.
  Duration get compressionCycle => const Duration(seconds: 120);
}
