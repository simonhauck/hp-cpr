import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

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
    final state = snapshot.adrenalinZeitfensterZustand;
    final stateColor = switch (state) {
      AdrenalinZeitfensterZustand.keine ||
      AdrenalinZeitfensterZustand.wartet => theme.colorScheme.onSurfaceVariant,
      AdrenalinZeitfensterZustand.faellig => theme.colorScheme.primary,
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

    return Container(
      padding: layout.medicationPanelPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(layout.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: PageLayout.iconSmall,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: PageLayout.space6),
                    Text(
                      l10n.adrenalinLabel,
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
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: stateColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PageLayout.space2),
                if (lastDose != null && sinceLastDose != null) ...[
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
                              left: 0,
                              right:
                                  width * (1 - startFraction) +
                                  PageLayout.space16,
                              child: Text(
                                l10n.adrenalinLastDose(
                                  formatReanimationsdauer(lastDose.zeitpunkt),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: labelStyle,
                              ),
                            ),
                            Positioned(
                              left: width * startFraction - PageLayout.space14,
                              child: Text(
                                formatElapsed(windowStart),
                                style: labelStyle,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: Text(
                                formatElapsed(windowEnd),
                                style: labelStyle,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ] else
                  Text(
                    snapshot.istErsteAdrenalinGabeFaellig
                        ? l10n.adrenalinFirstDoseDue
                        : l10n.adrenalinNotDue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: snapshot.istErsteAdrenalinGabeFaellig
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: snapshot.istErsteAdrenalinGabeFaellig
                          ? FontWeight.w700
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: PageLayout.space8),
          FilledButton.tonalIcon(
            onPressed: isRecordingEnabled ? onRecordAdrenalin : null,
            icon: const Icon(Icons.medication_outlined),
            label: Text(l10n.adrenalinRecordButton),
            style: FilledButton.styleFrom(
              minimumSize: Size(PageLayout.space0, layout.actionHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: PageLayout.space12,
              ),
              textStyle: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
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
