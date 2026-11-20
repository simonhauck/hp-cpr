import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';

/// The choice made when leaving a running Reanimationsfall.
enum LeaveReanimationsfallChoice {
  /// Stay on the running case.
  stay,

  /// Open the end dialog for the running case.
  endCase,

  /// Return to the start page; the case keeps running.
  leave,
}

/// Asks how to proceed before a running Reanimationsfall is left.
///
/// Returns `null` when the dialog is dismissed without a choice.
Future<LeaveReanimationsfallChoice?> showLeaveReanimationsfallDialog(
  BuildContext context,
) {
  return showDialog<LeaveReanimationsfallChoice>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return AlertDialog(
        title: Text(l10n.leaveCaseTitle),
        content: Text(l10n.leaveCaseDescription),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(LeaveReanimationsfallChoice.stay),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(LeaveReanimationsfallChoice.endCase),
            child: Text(l10n.endCaseButton),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(LeaveReanimationsfallChoice.leave),
            child: Text(l10n.leaveCaseButton),
          ),
        ],
      );
    },
  );
}
