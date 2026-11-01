import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// A small marker for a Reanimationsfall started in Demo-Modus.
class DemoModusChip extends StatelessWidget {
  const DemoModusChip({super.key, this.compact = false});

  /// Whether to use the smaller chip for short landscape screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Tooltip(
      message: l10n.demoModusTooltip,
      child: Chip(
        avatar: compact
            ? null
            : Icon(
                Icons.science_outlined,
                size: PageLayout.iconSmall,
                color: theme.colorScheme.onTertiaryContainer,
              ),
        label: Text(l10n.demoModusLabel),
        labelStyle:
            (compact ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
                ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
        backgroundColor: theme.colorScheme.tertiaryContainer,
        side: BorderSide(color: theme.colorScheme.tertiary),
        visualDensity: compact ? VisualDensity.compact : null,
        materialTapTargetSize: compact
            ? MaterialTapTargetSize.shrinkWrap
            : null,
      ),
    );
  }
}
