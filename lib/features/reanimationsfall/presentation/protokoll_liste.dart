import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/protokoll.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_format.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The shared timeline for a live or completed Protokoll.
///
/// The page decides what surrounds the component; this widget owns the
/// timeline, the Änderungsverlauf toggle, and the entry affordances.
class ProtokollListe extends StatefulWidget {
  const ProtokollListe({
    super.key,
    required this.protokoll,
    required this.startzeit,
    required this.isLive,
    required this.onOpenEintrag,
  });

  final Protokoll protokoll;
  final DateTime startzeit;
  final bool isLive;
  final ValueChanged<ProtokollEintrag> onOpenEintrag;

  @override
  State<ProtokollListe> createState() => _ProtokollListeState();
}

class _ProtokollListeState extends State<ProtokollListe> {
  bool _zeigeAenderungsverlauf = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final zeilen = _zeilen();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.protokollTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: PageLayout.space8),
            FilterChip(
              label: Text(l10n.protokollAuditToggle),
              selected: _zeigeAenderungsverlauf,
              onSelected: (selected) {
                setState(() => _zeigeAenderungsverlauf = selected);
              },
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        if (widget.isLive) ...[
          const SizedBox(height: PageLayout.space4),
          Text(
            l10n.protokollLiveEditHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: PageLayout.space8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, zeile) in zeilen.indexed) ...[
                if (index > 0) const Divider(height: PageLayout.dividerHeight),
                _ProtokollZeile(
                  zeile: zeile,
                  startzeit: widget.startzeit,
                  onTap: zeile.istAktion
                      ? () => widget.onOpenEintrag(zeile.eintrag)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<_Zeile> _zeilen() {
    final entries = _zeigeAenderungsverlauf
        ? widget.protokoll.alleEintraege
        : widget.protokoll.eintraege;
    final zeilen = <_Zeile>[];

    for (final eintrag in entries) {
      if (eintrag.istEntfernt) {
        zeilen.add(
          _Zeile(
            eintrag: eintrag,
            daten: eintrag.daten,
            zeitpunkt: eintrag.zeitpunkt,
            istOriginal: false,
            istEntfernt: true,
            istKorrigiert: eintrag.istKorrigiert,
            istAktion: eintrag.istWiederherstellbar,
          ),
        );
        if (eintrag.istKorrigiert) {
          zeilen.add(
            _Zeile(
              eintrag: eintrag,
              daten: eintrag.originalDaten,
              zeitpunkt: eintrag.originalZeitpunkt,
              istOriginal: true,
              istEntfernt: false,
              istKorrigiert: false,
              istAktion: false,
            ),
          );
        }
        continue;
      }

      zeilen.add(
        _Zeile(
          eintrag: eintrag,
          daten: eintrag.daten,
          zeitpunkt: eintrag.zeitpunkt,
          istOriginal: false,
          istEntfernt: false,
          istKorrigiert: eintrag.istKorrigiert,
          istAktion: eintrag.istBearbeitbar,
        ),
      );
      if (_zeigeAenderungsverlauf && eintrag.istKorrigiert) {
        zeilen.add(
          _Zeile(
            eintrag: eintrag,
            daten: eintrag.originalDaten,
            zeitpunkt: eintrag.originalZeitpunkt,
            istOriginal: true,
            istEntfernt: false,
            istKorrigiert: false,
            istAktion: false,
          ),
        );
      }
    }

    zeilen.sort((a, b) {
      final byTime = a.zeitpunkt.compareTo(b.zeitpunkt);
      if (byTime != 0) return byTime;
      final byOrder = a.eintrag.reihenfolge.compareTo(b.eintrag.reihenfolge);
      if (byOrder != 0) return byOrder;
      return (a.istOriginal ? 1 : 0).compareTo(b.istOriginal ? 1 : 0);
    });
    return zeilen;
  }
}

class _Zeile {
  const _Zeile({
    required this.eintrag,
    required this.daten,
    required this.zeitpunkt,
    required this.istOriginal,
    required this.istEntfernt,
    required this.istKorrigiert,
    required this.istAktion,
  });

  final ProtokollEintrag eintrag;
  final Object daten;
  final Duration zeitpunkt;
  final bool istOriginal;
  final bool istEntfernt;
  final bool istKorrigiert;
  final bool istAktion;
}

class _ProtokollZeile extends StatelessWidget {
  const _ProtokollZeile({
    required this.zeile,
    required this.startzeit,
    this.onTap,
  });

  final _Zeile zeile;
  final DateTime startzeit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final textColor = zeile.istOriginal ? muted : theme.colorScheme.onSurface;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: zeile.istOriginal ? FontWeight.w400 : FontWeight.w600,
      color: textColor,
      decoration: zeile.istEntfernt ? TextDecoration.lineThrough : null,
    );
    final detail = protokollDatenDetail(zeile.daten);
    final status = zeile.istOriginal
        ? l10n.protokollCorrected
        : zeile.istEntfernt
        ? l10n.protokollRemoved
        : zeile.istKorrigiert
        ? l10n.protokollCorrected
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PageLayout.space16,
          vertical: PageLayout.space6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: PageLayout.timelineTimeWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatReanimationsdauer(zeile.zeitpunkt),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    formatWallTime(startzeit.add(zeile.zeitpunkt)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              protokollEintragIcon(zeile.daten),
              size: PageLayout.iconSmall,
              color: zeile.istOriginal ? muted : theme.colorScheme.primary,
            ),
            const SizedBox(width: PageLayout.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    protokollDatenText(
                      l10n,
                      zeile.daten,
                      nummer: zeile.eintrag.nummer,
                    ),
                    style: textStyle,
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  if (status != null) ...[
                    const SizedBox(height: PageLayout.space4),
                    _StatusChip(label: status),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: PageLayout.iconSmall,
                color: muted,
              )
            else if (zeile.eintrag.istGesperrt && !zeile.istOriginal)
              Tooltip(
                message: l10n.protokollLockedTooltip,
                child: Icon(
                  Icons.lock_outline,
                  size: PageLayout.iconSmall,
                  color: muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PageLayout.space6,
        vertical: PageLayout.space2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(PageLayout.radius4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
