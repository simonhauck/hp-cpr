import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The read-only Schock count shown in the running case header.
class SchockCountChip extends StatelessWidget {
  const SchockCountChip({super.key, required this.count, required this.layout});

  final int count;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textStyle = layout.usesCompactHeaderChip
        ? theme.textTheme.labelMedium
        : theme.textTheme.labelLarge;

    return Container(
      padding: layout.schockChipPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(PageLayout.radius16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: PageLayout.iconSmall,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: PageLayout.space4),
          Text(
            l10n.schockCountChip(count),
            style: textStyle?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
