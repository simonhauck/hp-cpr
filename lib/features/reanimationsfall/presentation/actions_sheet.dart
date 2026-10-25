import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Opens the secondary actions for the running Reanimationsfall.
Future<void> showActionsSheet(
  BuildContext context, {
  required VoidCallback onOpenMesswerte,
  required VoidCallback onRecordNotiz,
  VoidCallback? onRecordSchock,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ActionsSheet(
      onOpenMesswerte: onOpenMesswerte,
      onRecordNotiz: onRecordNotiz,
      onRecordSchock: onRecordSchock,
    ),
  );
}

/// The `Weitere Aktionen` sheet.
///
/// Entries are shown only when their flow is available in the current state;
/// the sheet stays a single, large-target surface so the phase bar remains
/// uncluttered.
class ActionsSheet extends StatelessWidget {
  const ActionsSheet({
    super.key,
    required this.onOpenMesswerte,
    required this.onRecordNotiz,
    this.onRecordSchock,
  });

  final VoidCallback onOpenMesswerte;
  final VoidCallback onRecordNotiz;
  final VoidCallback? onRecordSchock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recordSchock = onRecordSchock;

    final actions = <_SheetAction>[
      _SheetAction(
        icon: Icons.monitor_heart_outlined,
        label: l10n.messwerteTitle,
        onPressed: onOpenMesswerte,
      ),
      _SheetAction(
        icon: Icons.notes,
        label: l10n.actionsNotiz,
        onPressed: onRecordNotiz,
      ),
      if (recordSchock != null)
        _SheetAction(
          icon: Icons.bolt_outlined,
          label: l10n.actionsSchock,
          onPressed: recordSchock,
        ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          PageLayout.space20,
          PageLayout.space8,
          PageLayout.space20,
          PageLayout.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.actionsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PageLayout.space16),
            for (final action in actions) ...[
              _ActionButton(action: action),
              const SizedBox(height: PageLayout.space12),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final _SheetAction action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () {
          Navigator.of(context).pop();
          action.onPressed();
        },
        icon: Icon(action.icon),
        label: Text(action.label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(PageLayout.dialogActionHeight),
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
