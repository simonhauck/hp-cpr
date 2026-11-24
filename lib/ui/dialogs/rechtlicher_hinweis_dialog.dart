import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Shows the first-start Rechtlicher Hinweis; only "Verstanden" dismisses it.
Future<void> showRechtlicherHinweisDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.legalNoticeTitle),
        content: SingleChildScrollView(child: Text(l10n.legalNoticeText)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                PageLayout.dialogActionWidth,
                PageLayout.dialogActionHeight,
              ),
            ),
            child: Text(l10n.legalNoticeConfirm),
          ),
        ],
      ),
    ),
  );
}
