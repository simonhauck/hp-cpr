import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The contextual Amiodaron hint and the last recorded dose.
class AmiodaronPanel extends StatelessWidget {
  const AmiodaronPanel({
    super.key,
    required this.snapshot,
    required this.layout,
    required this.isHintVisible,
    required this.onRecordAmiodaron,
    required this.onDismiss,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

  /// Whether the hint is shown; a dismissed hint keeps the last dose visible.
  final bool isHintVisible;

  final VoidCallback onRecordAmiodaron;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hint = snapshot.amiodaronHinweis;
    final showHint = isHintVisible && hint != AmiodaronHinweis.keine;
    final lastDose = snapshot.letzteAmiodaronGabe;

    return Container(
      padding: layout.medicationPanelPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(layout.cardRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.vaccines_outlined,
            size: PageLayout.iconSmall,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: PageLayout.space6),
          Expanded(
            child: showHint
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.amiodaronHint(hint.dosisMg!),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (lastDose != null)
                        Text(
                          l10n.amiodaronLastDose(
                            formatReanimationsdauer(lastDose.zeitpunkt),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  )
                : lastDose == null
                ? const SizedBox.shrink()
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${l10n.amiodaronLabel} · '
                      '${l10n.amiodaronLastDose(formatReanimationsdauer(lastDose.zeitpunkt))}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
          if (showHint) ...[
            const SizedBox(width: PageLayout.space8),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                minimumSize: Size(PageLayout.space0, layout.actionHeight),
              ),
              child: Text(l10n.amiodaronDismissButton),
            ),
            const SizedBox(width: PageLayout.space8),
            FilledButton.tonal(
              onPressed: onRecordAmiodaron,
              style: FilledButton.styleFrom(
                minimumSize: Size(PageLayout.space0, layout.actionHeight),
              ),
              child: Text(l10n.amiodaronGiveButton),
            ),
          ],
        ],
      ),
    );
  }
}
