import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/theme/due_colors.dart';

/// The Amiodaron recommendation status and the last recorded dose.
///
/// The card is always visible so that Adrenalin and Amiodaron share the same
/// treatment; the status says whether a dose is currently recommended.
class AmiodaronPanel extends StatelessWidget {
  const AmiodaronPanel({
    super.key,
    required this.snapshot,
    required this.layout,
    required this.onRecordAmiodaron,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onRecordAmiodaron;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hint = snapshot.amiodaronHinweis;
    final isRecommended = hint != AmiodaronHinweis.keine;
    final lastDose = snapshot.letzteAmiodaronGabe;
    final lastDoseText = lastDose == null
        ? null
        : l10n.amiodaronLastDose(formatReanimationsdauer(lastDose.zeitpunkt));

    final stateLabel = isRecommended
        ? l10n.amiodaronStateConsider
        : l10n.amiodaronStateNotRecommended;
    final stateColor = isRecommended
        ? DueColors.of(context).due
        : theme.colorScheme.onSurfaceVariant;

    final detail = isRecommended
        ? lastDoseText == null
              ? l10n.amiodaronDose(hint.dosisMg!)
              : '${l10n.amiodaronDose(hint.dosisMg!)} · $lastDoseText'
        : lastDoseText;

    final giveButton = isRecommended
        ? FilledButton.tonalIcon(
            onPressed: onRecordAmiodaron,
            icon: const Icon(Icons.vaccines_outlined),
            label: Text(l10n.amiodaronGiveButton),
            style: FilledButton.styleFrom(
              minimumSize: Size(PageLayout.space0, layout.actionHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: PageLayout.space12,
              ),
              textStyle: theme.textTheme.titleSmall,
            ),
          )
        : null;

    Widget titleRow({Widget? trailing}) {
      return Row(
        children: [
          Icon(
            Icons.vaccines_outlined,
            size: PageLayout.iconSmall,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: PageLayout.space6),
          Text(
            l10n.amiodaronLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: PageLayout.space8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stateLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: stateColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: PageLayout.space8),
            trailing,
          ],
        ],
      );
    }

    Widget details({required bool allowWrap}) {
      final text = Text(
        detail!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

      return allowWrap
          ? text
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: text,
            );
    }

    return Container(
      padding: layout.medicationPanelPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(layout.cardRadius),
      ),
      child: layout.stacksMedicationPanel
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleRow(trailing: giveButton),
                if (detail != null) ...[
                  const SizedBox(height: PageLayout.space2),
                  details(allowWrap: true),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      titleRow(),
                      if (detail != null) ...[
                        const SizedBox(height: PageLayout.space2),
                        details(allowWrap: false),
                      ],
                    ],
                  ),
                ),
                if (giveButton != null) ...[
                  const SizedBox(width: PageLayout.space8),
                  giveButton,
                ],
              ],
            ),
    );
  }
}
