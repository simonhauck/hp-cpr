import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/theme/due_colors.dart';

/// The current phase and the next action.
///
/// On a new case it also carries the dismissible `Vorbehandlung erfassen`
/// prompt until the Vorbehandlung is saved or the prompt is dismissed.
class PhaseStrip extends StatelessWidget {
  const PhaseStrip({
    super.key,
    required this.snapshot,
    this.onOpenVorbehandlung,
    this.onDismissVorbehandlungHinweis,
    this.compact = false,
  });

  final ReanimationsfallSnapshot snapshot;

  /// Whether the layout is height-limited (compact or landscape), so the
  /// strip must stay one line.
  final bool compact;
  final VoidCallback? onOpenVorbehandlung;
  final VoidCallback? onDismissVorbehandlungHinweis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDue = snapshot.isRhythmusanalyseDue;
    final isOverdue = snapshot.isPauseOverdue;
    final isAlert = isDue || isOverdue;
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
    final color = isOverdue
        ? theme.colorScheme.onErrorContainer
        : isDue
        ? DueColors.of(context).onDueContainer
        : theme.colorScheme.onSurfaceVariant;

    final text = Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: isAlert ? FontWeight.w800 : FontWeight.w600,
      ),
    );

    final openVorbehandlung = onOpenVorbehandlung;
    final dismissHinweis = onDismissVorbehandlungHinweis;
    if (!snapshot.zeigeVorbehandlungHinweis ||
        openVorbehandlung == null ||
        dismissHinweis == null) {
      return text;
    }

    // The prompt stays inline at the strip's line height so it never takes
    // room from the timer on compact screens.
    const inlineStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.zero),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: PageLayout.space4),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final promptStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    double widthOf(String value, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    double heightOf(String value, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    const iconButtonWidth = PageLayout.iconSmall + 2 * PageLayout.space4;
    final close = IconButton(
      onPressed: dismissHinweis,
      tooltip: l10n.vorbehandlungHinweisAusblenden,
      icon: const Icon(Icons.close, size: PageLayout.iconSmall),
      style: inlineStyle,
      constraints: const BoxConstraints(),
    );

    final textPrompt = TextButton(
      onPressed: openVorbehandlung,
      style: inlineStyle,
      child: Text(l10n.vorbehandlungErfassen, maxLines: 1, style: promptStyle),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = widthOf(label, text.style);
        final lineHeight = math.max(
          heightOf(label, text.style),
          PageLayout.iconSmall,
        );
        final promptWidth =
            widthOf(l10n.vorbehandlungErfassen, promptStyle) +
            2 * PageLayout.space4 +
            iconButtonWidth;

        // Inline when the full prompt fits beside the phase label.
        if (labelWidth + PageLayout.space8 + promptWidth <=
            constraints.maxWidth) {
          return SizedBox(
            height: lineHeight,
            child: Row(
              children: [
                Expanded(child: Text(label, maxLines: 1, style: text.style)),
                const SizedBox(width: PageLayout.space8),
                textPrompt,
                close,
              ],
            ),
          );
        }

        // Height-limited layouts keep the strip one line high so the prompt
        // never takes room from the timer: the label is shortened while the
        // prompt is shown and the prompt shrinks to an icon.
        if (compact) {
          return SizedBox(
            height: lineHeight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.style,
                  ),
                ),
                const SizedBox(width: PageLayout.space8),
                IconButton(
                  onPressed: openVorbehandlung,
                  tooltip: l10n.vorbehandlungErfassen,
                  icon: const Icon(Icons.history, size: PageLayout.iconSmall),
                  style: inlineStyle,
                  constraints: const BoxConstraints(),
                ),
                close,
              ],
            ),
          );
        }

        // Otherwise the prompt gets its own line below the label.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(child: textPrompt),
                close,
              ],
            ),
          ],
        );
      },
    );
  }
}
