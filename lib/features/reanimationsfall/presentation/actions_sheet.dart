import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Opens the secondary case actions for the running Reanimationsfall.
Future<void> showActionsSheet(
  BuildContext context, {
  required VoidCallback onRecordSchock,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ActionsSheet(onRecordSchock: onRecordSchock),
  );
}

/// The `Weitere Aktionen` sheet.
///
/// Entries are added as the corresponding flows are wired; the sheet stays a
/// single, large-target surface so the phase bar remains uncluttered.
class ActionsSheet extends StatelessWidget {
  const ActionsSheet({super.key, required this.onRecordSchock});

  final VoidCallback onRecordSchock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
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
            _ActionButton(
              icon: Icons.bolt_outlined,
              label: l10n.actionsSchock,
              onPressed: () {
                Navigator.of(context).pop();
                onRecordSchock();
              },
            ),
            const SizedBox(height: PageLayout.space12),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(PageLayout.dialogActionHeight),
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
