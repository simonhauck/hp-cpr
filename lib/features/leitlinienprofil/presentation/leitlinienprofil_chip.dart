import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The read-only Leitlinienprofil chip shown before and during a Reanimationsfall.
class LeitlinienprofilChip extends StatelessWidget {
  const LeitlinienprofilChip({
    super.key,
    required this.leitlinienprofil,
    this.compact = false,
    this.onPressed,
  });

  final Leitlinienprofil leitlinienprofil;

  /// Whether to use a smaller chip for short landscape screens.
  final bool compact;

  /// Opens settings when set; the chip itself always stays read-only.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final label = switch (leitlinienprofil) {
      Leitlinienprofil.erc2025 => l10n.guidelineErc2025,
      Leitlinienprofil.aha2025 => l10n.guidelineAha2025,
    };

    final avatar = compact
        ? null
        : const Icon(Icons.verified_outlined, size: 18);
    final labelStyle = compact ? theme.textTheme.labelMedium : null;
    final visualDensity = compact ? VisualDensity.compact : null;
    final tapTargetSize = compact ? MaterialTapTargetSize.shrinkWrap : null;

    return Tooltip(
      message: onPressed == null
          ? l10n.guidelineLabel
          : l10n.settingsOpenTooltip,
      child: onPressed == null
          ? Chip(
              avatar: avatar,
              labelStyle: labelStyle,
              visualDensity: visualDensity,
              materialTapTargetSize: tapTargetSize,
              label: Text(label),
            )
          : ActionChip(
              avatar: avatar,
              labelStyle: labelStyle,
              visualDensity: visualDensity,
              materialTapTargetSize: tapTargetSize,
              onPressed: onPressed,
              label: Text(label),
            ),
    );
  }
}
