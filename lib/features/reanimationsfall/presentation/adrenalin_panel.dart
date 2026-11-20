import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/medikament_card.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/theme/due_colors.dart';

/// The Adrenalin Zeitfenster and the action to record a dose.
class AdrenalinPanel extends StatelessWidget {
  const AdrenalinPanel({
    super.key,
    required this.snapshot,
    required this.layout,
    required this.onRecordAdrenalin,
    this.isRecordingEnabled = true,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onRecordAdrenalin;

  /// Recording is disabled while the case is interrupted by ROSC.
  final bool isRecordingEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dueColors = DueColors.of(context);
    final state = snapshot.adrenalinZeitfensterZustand;
    final stateColor = switch (state) {
      AdrenalinZeitfensterZustand.keine ||
      AdrenalinZeitfensterZustand.wartet => theme.colorScheme.onSurfaceVariant,
      AdrenalinZeitfensterZustand.faellig => dueColors.due,
      AdrenalinZeitfensterZustand.ueberfaellig => theme.colorScheme.error,
    };
    final stateLabel = switch (state) {
      AdrenalinZeitfensterZustand.keine => '',
      AdrenalinZeitfensterZustand.wartet => l10n.adrenalinStateWaiting,
      AdrenalinZeitfensterZustand.faellig => l10n.adrenalinStateDue,
      AdrenalinZeitfensterZustand.ueberfaellig => l10n.adrenalinStateOverdue,
    };
    final lastDose = snapshot.letzteAdrenalinGabe;
    final sinceLastDose = snapshot.adrenalinSeitLetzterGabe;
    final windowStart =
        snapshot.leitlinienprofil.adrenalinZeitfensterFruehestens;
    final windowEnd = snapshot.leitlinienprofil.adrenalinZeitfensterSpaetestens;
    final startFraction = windowStart.inMilliseconds / windowEnd.inMilliseconds;

    Widget details(bool allowWrap) {
      if (lastDose == null || sinceLastDose == null) {
        return Text(
          snapshot.istErsteAdrenalinGabeFaellig
              ? l10n.adrenalinFirstDoseDue
              : l10n.adrenalinNotDue,
          style: theme.textTheme.bodySmall?.copyWith(
            color: snapshot.istErsteAdrenalinGabeFaellig
                ? dueColors.due
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: snapshot.istErsteAdrenalinGabeFaellig
                ? FontWeight.w700
                : null,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MedikamentLetzteGabeText(
            snapshot: snapshot,
            zeitpunkt: lastDose.zeitpunkt,
            color: stateColor,
            allowWrap: allowWrap,
          ),
          const SizedBox(height: PageLayout.space2),
          _ZeitfensterBar(
            seitLetzterGabe: sinceLastDose,
            startFraction: startFraction,
            total: windowEnd,
            color: stateColor,
          ),
          const SizedBox(height: PageLayout.space2),
          SizedBox(
            height: PageLayout.space16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final labelStyle = theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: width * startFraction - PageLayout.space14,
                      child: Text(
                        formatElapsed(windowStart),
                        style: labelStyle,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Text(formatElapsed(windowEnd), style: labelStyle),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    return MedikamentCard(
      layout: layout,
      icon: Icons.medication_outlined,
      label: l10n.adrenalinLabel,
      stateLabel: stateLabel,
      stateColor: stateColor,
      onRecord: isRecordingEnabled ? onRecordAdrenalin : null,
      details: details,
    );
  }
}

class _ZeitfensterBar extends StatelessWidget {
  const _ZeitfensterBar({
    required this.seitLetzterGabe,
    required this.startFraction,
    required this.total,
    required this.color,
  });

  final Duration seitLetzterGabe;
  final double startFraction;
  final Duration total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (seitLetzterGabe.inMilliseconds / total.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();

    return SizedBox(
      height: PageLayout.barHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(PageLayout.radius4),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: width * progress,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(PageLayout.radius4),
                  ),
                ),
              ),
              Positioned(
                left: width * startFraction - PageLayout.barTickWidth / 2,
                top: -PageLayout.barOverhang,
                bottom: -PageLayout.barOverhang,
                child: Container(
                  width: PageLayout.barTickWidth,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Positioned(
                right: 0,
                top: -PageLayout.barOverhang,
                bottom: -PageLayout.barOverhang,
                child: Container(
                  width: PageLayout.barTickWidth,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Positioned(
                left: (width * progress - PageLayout.barMarkerWidth / 2)
                    .clamp(0, width - PageLayout.barMarkerWidth)
                    .toDouble(),
                top: -PageLayout.barOverhang,
                bottom: -PageLayout.barOverhang,
                child: Container(
                  width: PageLayout.barMarkerWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(PageLayout.radius2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
