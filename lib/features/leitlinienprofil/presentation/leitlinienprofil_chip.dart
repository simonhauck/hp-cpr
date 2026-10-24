import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The read-only Leitlinienprofil chip shown before and during a Reanimationsfall.
class LeitlinienprofilChip extends StatelessWidget {
  const LeitlinienprofilChip({
    super.key,
    required this.leitlinienprofil,
    this.compact = false,
  });

  final Leitlinienprofil leitlinienprofil;

  /// Whether to use a smaller chip for short landscape screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final label = switch (leitlinienprofil) {
      Leitlinienprofil.erc2025 => l10n.guidelineErc2025,
      Leitlinienprofil.aha2025 => l10n.guidelineAha2025,
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
