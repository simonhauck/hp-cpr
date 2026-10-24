import 'package:flutter/material.dart';

import 'package:hp_cpr/features/guideline/domain/guideline_profile.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The read-only guideline profile chip shown before and during a case.
class GuidelineChip extends StatelessWidget {
  const GuidelineChip({super.key, required this.profile, this.compact = false});

  final GuidelineProfile profile;

  /// Whether to use a smaller chip for short landscape screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final label = switch (profile) {
      GuidelineProfile.erc2025 => l10n.guidelineErc2025,
      GuidelineProfile.aha2025 => l10n.guidelineAha2025,
    };

    return Tooltip(
      message: l10n.guidelineLabel,
      child: Chip(
        avatar: compact ? null : const Icon(Icons.verified_outlined, size: 18),
        labelStyle: compact ? theme.textTheme.labelMedium : null,
        visualDensity: compact ? VisualDensity.compact : null,
        materialTapTargetSize: compact
            ? MaterialTapTargetSize.shrinkWrap
            : null,
        label: Text(label),
      ),
    );
  }
}
