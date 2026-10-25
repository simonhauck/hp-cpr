import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The selected skip choice; a null [grund] means "Ohne Angabe".
class SkipRhythmusanalyseChoice {
  const SkipRhythmusanalyseChoice(this.grund);

  final RhythmusanalyseUebersprungenGrund? grund;
}

/// Asks why the Rhythmusanalyse is skipped and starts the next Druckphase.
class SkipRhythmusanalyseDialog extends StatelessWidget {
  const SkipRhythmusanalyseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.skipAnalysisTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.skipAnalysisReasonLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PageLayout.space8),
          _reasonButton(
            context,
            label: l10n.skipReasonNoTime,
            grund: RhythmusanalyseUebersprungenGrund.keineZeit,
          ),
          const SizedBox(height: PageLayout.space8),
          _reasonButton(
            context,
            label: l10n.skipReasonAed,
            grund: RhythmusanalyseUebersprungenGrund.aedUebernimmt,
          ),
          const SizedBox(height: PageLayout.space8),
          _reasonButton(
            context,
            label: l10n.skipReasonOther,
            grund: RhythmusanalyseUebersprungenGrund.sonstiges,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const SkipRhythmusanalyseChoice(null)),
          child: Text(l10n.skipWithoutReasonButton),
        ),
      ],
    );
  }

  Widget _reasonButton(
    BuildContext context, {
    required String label,
    required RhythmusanalyseUebersprungenGrund grund,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () =>
            Navigator.of(context).pop(SkipRhythmusanalyseChoice(grund)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(PageLayout.dialogOptionHeight),
        ),
        child: Text(label),
      ),
    );
  }
}
