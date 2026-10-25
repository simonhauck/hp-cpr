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
    required this.onRecordRhythmusanalyse,
    required this.onSkipRhythmusanalyse,
    required this.onOpenActions,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onEnterAnalysephase;
  final VoidCallback onRecordRhythmusanalyse;
  final VoidCallback onSkipRhythmusanalyse;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAnalysephase = snapshot.phase == Reanimationsphase.analysephase;

    final phaseButtons = <Widget>[
      if (isAnalysephase) ...[
        PhaseActionButton(
          layout: layout,
          label: l10n.rhythmusanalyseRecordButton,
          icon: Icons.fact_check_outlined,
          onPressed: onRecordRhythmusanalyse,
        ),
        PhaseActionButton(
          layout: layout,
          emphasis: PhaseActionEmphasis.outlined,
          label: l10n.skipAnalysisButton,
          icon: Icons.skip_next_outlined,
          onPressed: onSkipRhythmusanalyse,
        ),
      ] else
        PhaseActionButton(
          layout: layout,
          label: l10n.analyseButton,
          icon: Icons.monitor_heart_outlined,
          onPressed: onEnterAnalysephase,
        ),
    ];
    final actionsButton = ActionsButton(
      layout: layout,
      onPressed: onOpenActions,
    );

    if (layout.isCompact) {
      return Row(
        children: [
          for (var i = 0; i < phaseButtons.length; i++) ...[
            if (i > 0) SizedBox(width: layout.compactActionGap),
            Expanded(child: phaseButtons[i]),
          ],
          SizedBox(width: layout.compactActionGap),
          actionsButton,
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: layout.actionWrapSpacing,
      runSpacing: layout.actionWrapRunSpacing,
      children: [...phaseButtons, actionsButton],
    );
  }
}

/// The secondary entry point for measurements, notes, and manual events.
class ActionsButton extends StatelessWidget {
  const ActionsButton({
    super.key,
    required this.layout,
    required this.onPressed,
  });

  final PageLayout layout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.more_horiz),
      label: Text(l10n.actionsButton),
      style: TextButton.styleFrom(
        minimumSize: Size(PageLayout.space0, layout.actionHeight),
        padding: layout.actionsButtonPadding,
        textStyle: layout.isCompact
            ? theme.textTheme.labelLarge
            : theme.textTheme.titleMedium,
      ),
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
