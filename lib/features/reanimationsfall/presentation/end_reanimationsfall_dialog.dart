import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The German label for a Beendigungsgrund.
String beendigungsgrundLabel(AppLocalizations l10n, Beendigungsgrund grund) {
  return switch (grund) {
    Beendigungsgrund.uebergabe => l10n.endReasonHandover,
    Beendigungsgrund.abbruch => l10n.endReasonAbort,
    Beendigungsgrund.sonstiges => l10n.endReasonOther,
  };
}

/// Asks for the reason before the Reanimationsfall is closed.
class EndReanimationsfallDialog extends StatelessWidget {
  const EndReanimationsfallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.endCaseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.endCaseReasonLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PageLayout.space8),
          for (final grund in Beendigungsgrund.values) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(grund),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    PageLayout.dialogOptionHeight,
                  ),
                ),
                child: Text(beendigungsgrundLabel(l10n, grund)),
              ),
            ),
            if (grund != Beendigungsgrund.values.last)
              const SizedBox(height: PageLayout.space8),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }
}
