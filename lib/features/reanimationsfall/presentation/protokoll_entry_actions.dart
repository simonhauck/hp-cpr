import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/protokoll.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_edit_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

enum _EintragAktion { bearbeiten, entfernen, wiederherstellen }

/// Opens the actions for one Protokoll entry and applies the chosen correction.
///
/// [onApply] returns whether the domain accepted the correction. The helper
/// shows the success snackbar only when it did.
Future<bool> showProtokollEintragActions(
  BuildContext context, {
  required ProtokollEintrag eintrag,
  required DateTime startzeit,
  required Duration maxZeitpunkt,
  required bool Function(ProtokollKorrektur korrektur) onApply,
}) async {
  final l10n = AppLocalizations.of(context);
  final aktion = await showModalBottomSheet<_EintragAktion>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _EintragAktionenSheet(
      eintrag: eintrag,
      onAktion: (aktion) => Navigator.of(sheetContext).pop(aktion),
    ),
  );
  if (aktion == null || !context.mounted) return false;

  switch (aktion) {
    case _EintragAktion.wiederherstellen:
      final applied = onApply(
        ProtokollEintragWiederhergestellt(ziel: eintrag.ref),
      );
      if (applied && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.protokollRestoredSnackbar)));
      }
      return applied;
    case _EintragAktion.entfernen:
      final applied = onApply(ProtokollEintragEntfernt(ziel: eintrag.ref));
      if (applied && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.protokollRemovedSnackbar)));
      }
      return applied;
    case _EintragAktion.bearbeiten:
      final korrektur = await showProtokollEditDialog(
        context,
        eintrag: eintrag,
        startzeit: startzeit,
        maxZeitpunkt: maxZeitpunkt,
      );
      if (korrektur == null || !context.mounted) return false;
      return onApply(korrektur);
  }
}

class _EintragAktionenSheet extends StatelessWidget {
  const _EintragAktionenSheet({required this.eintrag, required this.onAktion});

  final ProtokollEintrag eintrag;
  final ValueChanged<_EintragAktion> onAktion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
              protokollDatenText(l10n, eintrag.daten, nummer: eintrag.nummer),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PageLayout.space16),
            if (eintrag.istWiederherstellbar)
              _Aktion(
                icon: Icons.restore,
                label: l10n.protokollRestore,
                onPressed: () => onAktion(_EintragAktion.wiederherstellen),
              ),
            if (eintrag.istBearbeitbar) ...[
              _Aktion(
                icon: Icons.edit_outlined,
                label: l10n.protokollEdit,
                onPressed: () => onAktion(_EintragAktion.bearbeiten),
              ),
              const SizedBox(height: PageLayout.space12),
              _Aktion(
                icon: Icons.delete_outline,
                label: l10n.protokollRemove,
                onPressed: () => onAktion(_EintragAktion.entfernen),
              ),
            ],
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

class _Aktion extends StatelessWidget {
  const _Aktion({
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
