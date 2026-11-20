import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';

/// Asks for confirmation of a destructive action.
///
/// Returns true only when the error-colored confirm button is pressed.
Future<bool> showDestructiveConfirmDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
