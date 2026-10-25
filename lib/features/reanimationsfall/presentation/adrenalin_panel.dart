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
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onRecordAdrenalin;

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
      padding: EdgeInsets.symmetric(
        horizontal: layout.isCompact ? 10 : 14,
        vertical: layout.isCompact ? 2 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
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
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.adrenalinLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 2),
                if (lastDose != null && sinceLastDose != null) ...[
                  _ZeitfensterBar(
                    seitLetzterGabe: sinceLastDose,
                    startFraction: startFraction,
                    total: windowEnd,
                    color: stateColor,
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 16,
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
                              right: width * (1 - startFraction) + 16,
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
                              left: width * startFraction - 14,
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
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: onRecordAdrenalin,
            icon: const Icon(Icons.medication_outlined),
            label: Text(l10n.adrenalinRecordButton),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, layout.actionHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
      height: 8,
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
                    borderRadius: BorderRadius.circular(4),
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                left: width * startFraction - 1,
                top: -2,
                bottom: -2,
                child: Container(
                  width: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Positioned(
                right: 0,
                top: -2,
                bottom: -2,
                child: Container(
                  width: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Positioned(
                left: (width * progress - 2).clamp(0, width - 4).toDouble(),
                top: -2,
                bottom: -2,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
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
