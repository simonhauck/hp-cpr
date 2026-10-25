import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The current phase, the next action, and the shock count.
class PhaseStrip extends StatelessWidget {
  const PhaseStrip({super.key, required this.snapshot, required this.layout});

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDue = snapshot.isRhythmusanalyseDue;
    final isAlert = isDue || snapshot.isPauseOverdue;
    final label = switch (snapshot.zustand) {
      ReanimationsfallZustand.laufend => switch (snapshot.phase) {
        Reanimationsphase.druckphase =>
          isDue
              ? (layout.isCompact
                    ? l10n.phaseStripDruckphaseDueCompact
                    : l10n.phaseStripDruckphaseDue)
              : (layout.isCompact
                    ? l10n.phaseStripDruckphaseCompact
                    : l10n.phaseStripDruckphase),
        Reanimationsphase.analysephase =>
          layout.isCompact
              ? l10n.phaseStripAnalysephaseCompact
              : l10n.phaseStripAnalysephase,
      },
      ReanimationsfallZustand.rosc =>
        layout.isCompact ? l10n.phaseStripRoscCompact : l10n.phaseStripRosc,
      ReanimationsfallZustand.beendet => l10n.summaryCaseEnded,
      ReanimationsfallZustand.verworfen => l10n.verworfenLabel,
    };
    final color = isAlert
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: isAlert ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: layout.sectionGap),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PageLayout.space10,
            vertical: PageLayout.space4,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(PageLayout.radius16),
          ),
          child: Text(
            l10n.schockCountChip(snapshot.schockAnzahl),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
