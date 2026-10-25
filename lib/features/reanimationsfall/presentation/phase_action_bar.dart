import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

enum PhaseActionEmphasis { filled, outlined }

/// The phase-dependent actions for the running Reanimationsfall.
class PhaseActionBar extends StatelessWidget {
  const PhaseActionBar({
    super.key,
    required this.snapshot,
    required this.layout,
    required this.onEnterAnalysephase,
    required this.onRecordSchock,
    required this.onRecordRhythmusanalyse,
    required this.onSkipRhythmusanalyse,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onEnterAnalysephase;
  final VoidCallback onRecordSchock;
  final VoidCallback onRecordRhythmusanalyse;
  final VoidCallback onSkipRhythmusanalyse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAnalysephase = snapshot.phase == Reanimationsphase.analysephase;

    final buttons = <Widget>[
      if (isAnalysephase)
        PhaseActionButton(
          layout: layout,
          label: l10n.rhythmusanalyseRecordButton,
          icon: Icons.fact_check_outlined,
          onPressed: onRecordRhythmusanalyse,
        )
      else
        PhaseActionButton(
          layout: layout,
          label: l10n.analyseButton,
          icon: Icons.monitor_heart_outlined,
          onPressed: onEnterAnalysephase,
        ),
      PhaseActionButton(
        layout: layout,
        emphasis: PhaseActionEmphasis.outlined,
        label: l10n.schockButton(snapshot.schockAnzahl),
        icon: Icons.bolt_outlined,
        onPressed: onRecordSchock,
      ),
      if (isAnalysephase)
        PhaseActionButton(
          layout: layout,
          emphasis: PhaseActionEmphasis.outlined,
          label: l10n.skipAnalysisButton,
          icon: Icons.skip_next_outlined,
          onPressed: onSkipRhythmusanalyse,
        ),
    ];

    if (layout.isCompact) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) SizedBox(width: layout.compactActionGap),
            Expanded(child: buttons[i]),
          ],
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: layout.actionWrapSpacing,
      runSpacing: layout.actionWrapRunSpacing,
      children: buttons,
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
