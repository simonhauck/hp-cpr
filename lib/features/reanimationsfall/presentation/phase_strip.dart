import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The current phase and the next action.
class PhaseStrip extends StatelessWidget {
  const PhaseStrip({super.key, required this.snapshot});

  final ReanimationsfallSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDue = snapshot.isRhythmusanalyseDue;
    final isAlert = isDue || snapshot.isPauseOverdue;
    final label = switch (snapshot.zustand) {
      ReanimationsfallZustand.laufend => switch (snapshot.phase) {
        Reanimationsphase.druckphase =>
          isDue ? l10n.phaseStripDruckphaseDue : l10n.phaseStripDruckphase,
        Reanimationsphase.analysephase => l10n.phaseStripAnalysephase,
      },
      ReanimationsfallZustand.rosc => l10n.phaseStripRosc,
      ReanimationsfallZustand.beendet => l10n.summaryCaseEnded,
      ReanimationsfallZustand.verworfen => l10n.verworfenLabel,
    };
    final color = isAlert
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurfaceVariant;

    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: isAlert ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }
}
