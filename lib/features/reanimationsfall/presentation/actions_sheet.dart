import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Opens the secondary actions for the running Reanimationsfall.
Future<void> showActionsSheet(
  BuildContext context, {
  required VoidCallback onOpenMesswerte,
  required VoidCallback onOpenProtokoll,
  required VoidCallback onRecordNotiz,
  required VoidCallback onEndCase,
  VoidCallback? onRecordSchock,
  VoidCallback? onRestartDruckphase,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ActionsSheet(
      onOpenMesswerte: onOpenMesswerte,
      onOpenProtokoll: onOpenProtokoll,
      onRecordNotiz: onRecordNotiz,
      onEndCase: onEndCase,
      onRecordSchock: onRecordSchock,
      onRestartDruckphase: onRestartDruckphase,
    ),
  );
}

/// The `Weitere Aktionen` sheet.
///
/// Entries are grouped into `Erfassen` and `Ansehen` sections, with the
/// destructive `Fall beenden` separated at the bottom. Entries are shown only
/// when their flow is available in the current state.
class ActionsSheet extends StatelessWidget {
  const ActionsSheet({
    super.key,
    required this.onOpenMesswerte,
    required this.onOpenProtokoll,
    required this.onRecordNotiz,
    required this.onEndCase,
    this.onRecordSchock,
    this.onRestartDruckphase,
  });

  final VoidCallback onOpenMesswerte;
  final VoidCallback onOpenProtokoll;
  final VoidCallback onRecordNotiz;
  final VoidCallback onEndCase;
  final VoidCallback? onRecordSchock;
  final VoidCallback? onRestartDruckphase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recordSchock = onRecordSchock;
    final restartDruckphase = onRestartDruckphase;

    final recordActions = <_SheetAction>[
      if (recordSchock != null)
        _SheetAction(
          icon: Icons.bolt,
          label: l10n.actionsSchock,
          onPressed: recordSchock,
        ),
      _SheetAction(
        icon: Icons.straighten,
        label: l10n.messwerteTitle,
        onPressed: onOpenMesswerte,
      ),
      _SheetAction(
        icon: Icons.notes,
        label: l10n.actionsNotiz,
        onPressed: onRecordNotiz,
      ),
      if (restartDruckphase != null)
        _SheetAction(
          icon: Icons.restart_alt,
          label: l10n.actionsRestartDruckphase,
          onPressed: restartDruckphase,
        ),
    ];

    final viewActions = <_SheetAction>[
      _SheetAction(
        icon: Icons.receipt_long_outlined,
        label: l10n.actionsProtokoll,
        onPressed: onOpenProtokoll,
      ),
    ];

    final endCaseAction = _SheetAction(
      icon: Icons.stop_circle_outlined,
      label: l10n.endCaseButton,
      onPressed: onEndCase,
    );

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
            _SectionHeader(label: l10n.actionsSectionRecord),
            for (final action in recordActions) ...[
              _ActionButton(action: action),
              const SizedBox(height: PageLayout.space12),
            ],
            const SizedBox(height: PageLayout.space4),
            _SectionHeader(label: l10n.actionsSectionView),
            for (final action in viewActions) ...[
              _ActionButton(action: action),
              const SizedBox(height: PageLayout.space12),
            ],
            const SizedBox(height: PageLayout.space4),
            const Divider(height: PageLayout.dividerHeight),
            const SizedBox(height: PageLayout.space16),
            _ActionButton(action: endCaseAction, destructive: true),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PageLayout.space8),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
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
  const _ActionButton({required this.action, this.destructive = false});

  final _SheetAction action;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    void onPressed() {
      Navigator.of(context).pop();
      action.onPressed();
    }

    const minimumSize = Size.fromHeight(PageLayout.dialogActionHeight);
    final textStyle = theme.textTheme.titleMedium;

    return SizedBox(
      width: double.infinity,
      child: destructive
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
              style: FilledButton.styleFrom(
                minimumSize: minimumSize,
                textStyle: textStyle,
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
            )
          : FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
              style: FilledButton.styleFrom(
                minimumSize: minimumSize,
                textStyle: textStyle,
              ),
            ),
    );
  }
}
