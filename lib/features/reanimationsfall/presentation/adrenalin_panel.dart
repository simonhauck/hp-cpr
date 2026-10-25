import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/adrenalin.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

const double _iconSize = 18;
const double _headerIconGap = 6;
const double _headerStateGap = 8;
const double _lineGap = 2;
const double _panelButtonGap = 8;
const double _buttonHorizontalPadding = 12;
const double _labelRowHeight = 16;
const double _lastDoseTrailingGap = 16;
const double _barLabelHalfWidth = 14;
const double _barHeight = 8;
const double _barRadius = 4;
const double _barTickWidth = 2;
const double _barMarkerWidth = 4;
const double _barMarkerRadius = 2;
const double _barOverhang = 2;

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
                      size: _iconSize,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: _headerIconGap),
                    Text(
                      l10n.adrenalinLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: _headerStateGap),
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
                const SizedBox(height: _lineGap),
                if (lastDose != null && sinceLastDose != null) ...[
                  _ZeitfensterBar(
                    seitLetzterGabe: sinceLastDose,
                    startFraction: startFraction,
                    total: windowEnd,
                    color: stateColor,
                  ),
                  const SizedBox(height: _lineGap),
                  SizedBox(
                    height: _labelRowHeight,
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
                                  _lastDoseTrailingGap,
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
                              left: width * startFraction - _barLabelHalfWidth,
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
          const SizedBox(width: _panelButtonGap),
          FilledButton.tonalIcon(
            onPressed: onRecordAdrenalin,
            icon: const Icon(Icons.medication_outlined),
            label: Text(l10n.adrenalinRecordButton),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, layout.actionHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: _buttonHorizontalPadding,
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
      height: _barHeight,
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
                    borderRadius: BorderRadius.circular(_barRadius),
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
                    borderRadius: BorderRadius.circular(_barRadius),
                  ),
                ),
              ),
              Positioned(
                left: width * startFraction - _barTickWidth / 2,
                top: -_barOverhang,
                bottom: -_barOverhang,
                child: Container(
                  width: _barTickWidth,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Positioned(
                right: 0,
                top: -_barOverhang,
                bottom: -_barOverhang,
                child: Container(
                  width: _barTickWidth,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Positioned(
                left: (width * progress - _barMarkerWidth / 2)
                    .clamp(0, width - _barMarkerWidth)
                    .toDouble(),
                top: -_barOverhang,
                bottom: -_barOverhang,
                child: Container(
                  width: _barMarkerWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(_barMarkerRadius),
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
