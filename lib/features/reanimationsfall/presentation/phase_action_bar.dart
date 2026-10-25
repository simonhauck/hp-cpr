import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

enum PhaseActionEmphasis { filled, outlined }

const double _statusIconSize = 18;
const double _statusIconGap = 6;
const double _statusActionPadding = 8;
const double _summaryIconGap = 8;

/// The phase-dependent actions, status hint, and result summary.
class PhaseActionBar extends StatelessWidget {
  const PhaseActionBar({
    super.key,
    required this.snapshot,
    required this.layout,
    required this.onEnterAnalysephase,
    required this.onRecordSchock,
    required this.onUndoLastSchock,
    required this.onEditSchockEnergie,
    required this.onRecordRhythmusanalyse,
    required this.onEditRhythmusanalyseNotiz,
    required this.onSkipRhythmusanalyse,
    required this.onContinueCpr,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onEnterAnalysephase;
  final VoidCallback onRecordSchock;
  final VoidCallback onUndoLastSchock;
  final VoidCallback onEditSchockEnergie;
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
    final isShockable =
        isAnalysephase &&
        ergebnis?.kategorie == RhythmusanalyseKategorie.schockbar;

    final schockButton = PhaseActionButton(
      layout: layout,
      label: l10n.schockButton(snapshot.schockAnzahl),
      icon: Icons.bolt_outlined,
      onPressed: onRecordSchock,
      emphasis: isShockable
          ? PhaseActionEmphasis.filled
          : PhaseActionEmphasis.outlined,
    );
    final analyseButton = PhaseActionButton(
      layout: layout,
      label: l10n.analyseButton,
      icon: Icons.monitor_heart_outlined,
      onPressed: onEnterAnalysephase,
    );
    final pausedAnalyseButton = PhaseActionButton(
      layout: layout,
      emphasis: PhaseActionEmphasis.outlined,
      label: l10n.analyseButton,
      icon: Icons.monitor_heart_outlined,
      onPressed: onEnterAnalysephase,
    );
    final continueButton = PhaseActionButton(
      layout: layout,
      label: l10n.cprContinueButton,
      icon: Icons.play_arrow,
      onPressed: onContinueCpr,
    );
    final resultContinueButton = PhaseActionButton(
      layout: layout,
      label: l10n.cprContinueButton,
      icon: Icons.play_arrow,
      onPressed: onContinueCpr,
      emphasis: isShockable
          ? PhaseActionEmphasis.outlined
          : PhaseActionEmphasis.filled,
    );

    final buttons = <Widget>[];
    if (!isAnalysephase) {
      if (snapshot.isSchockpause) {
        buttons.add(continueButton);
        buttons.add(schockButton);
        buttons.add(pausedAnalyseButton);
      } else {
        buttons.add(analyseButton);
        buttons.add(schockButton);
      }
    } else if (ergebnis == null) {
      buttons.add(
        PhaseActionButton(
          layout: layout,
          label: l10n.rhythmusanalyseRecordButton,
          icon: Icons.fact_check_outlined,
          onPressed: onRecordRhythmusanalyse,
        ),
      );
      buttons.add(schockButton);
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
      buttons.add(schockButton);
      buttons.add(resultContinueButton);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.schockAnzahl > 0) ...[
          _SchockStatusRow(
            schockAnzahl: snapshot.schockAnzahl,
            energieJoule: snapshot.letzterAktiverSchock?.energieJoule,
            layout: layout,
            onEditEnergie: onEditSchockEnergie,
            onUndo: onUndoLastSchock,
          ),
          SizedBox(height: layout.statusGap),
        ],
        if (isAnalysephase && ergebnis != null) ...[
          _RhythmusanalyseResultSummary(
            ergebnis: ergebnis,
            notiz: snapshot.rhythmusanalyseNotiz,
            layout: layout,
            onEditNotiz: onEditRhythmusanalyseNotiz,
          ),
          SizedBox(height: layout.resultSummaryGap),
        ] else if (isAnalysephase) ...[
          Text(
            l10n.rhythmusanalyseRequired,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: layout.hintGap),
        ],
        if (layout.isCompact)
          Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) SizedBox(width: layout.compactActionGap),
                Expanded(child: buttons[i]),
              ],
            ],
          )
        else
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: layout.actionWrapSpacing,
            runSpacing: layout.actionWrapRunSpacing,
            children: buttons,
          ),
      ],
    );
  }
}

/// A persistent status row for the recorded Schocks.
class _SchockStatusRow extends StatelessWidget {
  const _SchockStatusRow({
    required this.schockAnzahl,
    required this.energieJoule,
    required this.layout,
    required this.onEditEnergie,
    required this.onUndo,
  });

  final int schockAnzahl;
  final int? energieJoule;
  final PageLayout layout;
  final VoidCallback onEditEnergie;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final buttonStyle = TextButton.styleFrom(
      minimumSize: Size(0, layout.touchTarget),
      padding: const EdgeInsets.symmetric(horizontal: _statusActionPadding),
    );
    final text = energieJoule == null
        ? l10n.schockRecorded(schockAnzahl)
        : l10n.schockRecordedWithEnergy(schockAnzahl, energieJoule!);

    return Row(
      children: [
        Icon(
          Icons.bolt_outlined,
          size: _statusIconSize,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: _statusIconGap),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onEditEnergie,
          style: buttonStyle,
          child: Text(l10n.schockEnergyAction),
        ),
        TextButton(
          onPressed: onUndo,
          style: buttonStyle,
          child: Text(l10n.schockUndoAction),
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
    final minimumSize = Size(layout.phaseActionMinWidth, layout.actionHeight);
    final padding = layout.phaseActionPadding;
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
      padding: layout.resultSummaryPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(layout.cardRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
          const SizedBox(width: _summaryIconGap),
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
          const SizedBox(width: _summaryIconGap),
          if (layout.isCompact)
            IconButton(
              onPressed: onEditNotiz,
              tooltip: notiz == null
                  ? l10n.rhythmusanalyseNoteAdd
                  : l10n.rhythmusanalyseNoteEdit,
              icon: Icon(
                notiz == null ? Icons.note_add_outlined : Icons.edit_note,
              ),
              constraints: BoxConstraints.tightFor(
                width: layout.touchTarget,
                height: layout.touchTarget,
              ),
              padding: EdgeInsets.zero,
            )
          else
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
