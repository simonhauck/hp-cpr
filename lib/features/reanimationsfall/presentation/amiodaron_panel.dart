import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/medikament_card.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/theme/panel_tone.dart';

/// The Amiodaron recommendation status and the last recorded dose.
///
/// The card is always visible and its button always stays in place; it is
/// disabled while no dose is recommended or the case is interrupted by ROSC.
class AmiodaronPanel extends StatelessWidget {
  const AmiodaronPanel({
    super.key,
    required this.snapshot,
    required this.layout,
    required this.onRecordAmiodaron,
    this.isRecordingEnabled = true,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onRecordAmiodaron;

  /// Recording is disabled while the case is interrupted by ROSC.
  final bool isRecordingEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hint = snapshot.amiodaronHinweis;
    final isRecommended = hint != AmiodaronHinweis.keine;
    final lastDose = snapshot.letzteAmiodaronGabe;

    final stateLabel = isRecommended
        ? l10n.amiodaronStateConsider
        : l10n.amiodaronStateNotRecommended;
    final tone = isRecommended && isRecordingEnabled
        ? PanelTone.due
        : PanelTone.neutral;
    final stateColor = tone.colors(context).accent;

    return MedikamentCard(
      layout: layout,
      icon: Icons.vaccines_outlined,
      label: l10n.amiodaronLabel,
      stateLabel: stateLabel,
      tone: tone,
      onRecord: isRecommended && isRecordingEnabled ? onRecordAmiodaron : null,
      details: !isRecommended && lastDose == null
          ? null
          : (allowWrap) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRecommended)
                  Text(
                    l10n.amiodaronDose(hint.dosisMg!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (lastDose != null)
                  MedikamentLetzteGabeText(
                    snapshot: snapshot,
                    zeitpunkt: lastDose.zeitpunkt,
                    color: stateColor,
                    allowWrap: allowWrap,
                  ),
              ],
            ),
    );
  }
}
