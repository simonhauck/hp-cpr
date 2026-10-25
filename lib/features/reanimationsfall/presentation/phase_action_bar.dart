import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

enum PhaseActionEmphasis { filled, outlined }

/// The phase-dependent actions, status hint, and result summary.
class PhaseActionBar extends StatelessWidget {
  const PhaseActionBar({
    super.key,
    required this.snapshot,
    required this.layout,
    required this.onEnterAnalysephase,
    required this.onRecordRhythmusanalyse,
    required this.onEditRhythmusanalyseNotiz,
    required this.onSkipRhythmusanalyse,
    required this.onContinueCpr,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onEnterAnalysephase;
  final VoidCallback onRecordRhythmusanalyse;
  final VoidCallback onEditRhythmusanalyseNotiz;
  final VoidCallback onSkipRhythmusanalyse;
  final VoidCallback onContinueCpr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isAnalysephase = snapshot.phase == Reanimationsphase.analysephase;
    final ergebnis = snapshot.rhythmusanalyseErgebnis;

    final buttons = <Widget>[];
    if (!isAnalysephase) {
      buttons.add(
        PhaseActionButton(
          layout: layout,
          label: l10n.analyseButton,
          icon: Icons.monitor_heart_outlined,
          onPressed: onEnterAnalysephase,
        ),
      );
    } else if (ergebnis == null) {
      buttons.add(
        PhaseActionButton(
          layout: layout,
          label: l10n.rhythmusanalyseRecordButton,
          icon: Icons.fact_check_outlined,
          onPressed: onRecordRhythmusanalyse,
        ),
      );
      buttons.add(
        PhaseActionButton(
          layout: layout,
          emphasis: PhaseActionEmphasis.outlined,
          label: l10n.skipAnalysisButton,
          icon: Icons.skip_next_outlined,
          onPressed: onSkipRhythmusanalyse,
        ),
      );
      buttons.add(
        Tooltip(
          message: l10n.rhythmusanalyseRequired,
          child: PhaseActionButton(
            layout: layout,
            label: l10n.cprContinueButton,
            icon: Icons.lock_outline,
            onPressed: null,
          ),
        ),
      );
    } else {
      buttons.add(
        PhaseActionButton(
          layout: layout,
          label: l10n.cprContinueButton,
          icon: Icons.play_arrow,
          onPressed: onContinueCpr,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAnalysephase && ergebnis != null) ...[
          _RhythmusanalyseResultSummary(
            ergebnis: ergebnis,
            notiz: snapshot.rhythmusanalyseNotiz,
            layout: layout,
            onEditNotiz: onEditRhythmusanalyseNotiz,
          ),
          SizedBox(height: layout.isCompact ? 6 : 10),
        ] else if (isAnalysephase) ...[
          Text(
            l10n.rhythmusanalyseRequired,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: layout.isCompact ? 4 : 8),
        ],
        if (layout.isCompact)
          Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: buttons[i]),
              ],
            ],
          )
        else
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: buttons,
          ),
      ],
    );
  }
}

/// A filled or outlined action button that adapts to the page density.
class PhaseActionButton extends StatelessWidget {
  const PhaseActionButton({
    super.key,
    required this.layout,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasis = PhaseActionEmphasis.filled,
  });

  final PageLayout layout;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final PhaseActionEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _style(theme);

    if (layout.isCompact) {
      final child = FittedBox(fit: BoxFit.scaleDown, child: Text(label));
      return switch (emphasis) {
        PhaseActionEmphasis.filled => FilledButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
        PhaseActionEmphasis.outlined => OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
      };
    }

    return switch (emphasis) {
      PhaseActionEmphasis.filled => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: style,
      ),
      PhaseActionEmphasis.outlined => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: style,
      ),
    };
  }

  ButtonStyle _style(ThemeData theme) {
    final minimumSize = Size(layout.isCompact ? 0 : 180, layout.actionHeight);
    final padding = layout.isCompact
        ? const EdgeInsets.symmetric(horizontal: 14)
        : null;
    final textStyle = layout.isCompact
        ? theme.textTheme.labelLarge
        : theme.textTheme.titleMedium;

    return switch (emphasis) {
      PhaseActionEmphasis.filled => FilledButton.styleFrom(
        minimumSize: minimumSize,
        padding: padding,
        textStyle: textStyle,
      ),
      PhaseActionEmphasis.outlined => OutlinedButton.styleFrom(
        minimumSize: minimumSize,
        padding: padding,
        textStyle: textStyle,
      ),
    };
  }
}

class _RhythmusanalyseResultSummary extends StatelessWidget {
  const _RhythmusanalyseResultSummary({
    required this.ergebnis,
    required this.notiz,
    required this.layout,
    required this.onEditNotiz,
  });

  final RhythmusanalyseErgebnis ergebnis;
  final String? notiz;
  final PageLayout layout;
  final VoidCallback onEditNotiz;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notizText = notiz;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isCompact ? 10 : 14,
        vertical: layout.isCompact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.rhythmusanalyseRecordedLabel}: '
                  '${rhythmusanalyseErgebnisLabel(l10n, ergebnis)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (notizText != null)
                  Text(
                    notizText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onEditNotiz,
            icon: Icon(
              notiz == null ? Icons.note_add_outlined : Icons.edit_note,
            ),
            label: Text(
              notiz == null
                  ? l10n.rhythmusanalyseNoteAdd
                  : l10n.rhythmusanalyseNoteEdit,
            ),
          ),
        ],
      ),
    );
  }
}
