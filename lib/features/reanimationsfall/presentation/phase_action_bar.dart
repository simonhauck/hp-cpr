import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

enum PhaseActionEmphasis { filled, outlined }

/// The secondary actions for the running Reanimationsfall.
///
/// Phase-specific primary actions live in the timer panel; this bar keeps the
/// compact Überspringen fallback, the Aktionen entry point, and the Demo-Modus
/// control within reach.
class PhaseActionBar extends StatelessWidget {
  const PhaseActionBar({
    super.key,
    required this.layout,
    required this.onOpenActions,
    this.onSkipRhythmusanalyse,
    this.onAdvanceDemoTime,
  });

  final PageLayout layout;
  final VoidCallback onOpenActions;

  /// Shown only on compact layouts, where the timer panel has no room for it.
  final VoidCallback? onSkipRhythmusanalyse;

  /// Advances the simulated case time; null outside Demo-Modus.
  final VoidCallback? onAdvanceDemoTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skipRhythmusanalyse = onSkipRhythmusanalyse;
    final advanceDemoTime = onAdvanceDemoTime;

    return PhaseActionRow(
      layout: layout,
      buttons: [
        if (skipRhythmusanalyse != null)
          PhaseActionButton(
            layout: layout,
            emphasis: PhaseActionEmphasis.outlined,
            label: l10n.skipAnalysisButton,
            icon: Icons.skip_next_outlined,
            onPressed: skipRhythmusanalyse,
          ),
        if (advanceDemoTime != null)
          DemoAdvanceButton(layout: layout, onPressed: advanceDemoTime),
      ],
      actionsButton: ActionsButton(layout: layout, onPressed: onOpenActions),
    );
  }
}

/// The shared responsive row for phase actions and the Aktionen entry point.
class PhaseActionRow extends StatelessWidget {
  const PhaseActionRow({
    super.key,
    required this.layout,
    required this.buttons,
    required this.actionsButton,
  });

  final PageLayout layout;
  final List<Widget> buttons;
  final Widget actionsButton;

  @override
  Widget build(BuildContext context) {
    if (layout.isCompact) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) SizedBox(width: layout.compactActionGap),
            Expanded(child: buttons[i]),
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
      children: [...buttons, actionsButton],
    );
  }
}

/// The Demo-Modus action that advances the simulated case time.
class DemoAdvanceButton extends StatelessWidget {
  const DemoAdvanceButton({
    super.key,
    required this.layout,
    required this.onPressed,
  });

  final PageLayout layout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Tooltip(
      message: l10n.demoModusAdvanceTooltip,
      child: PhaseActionButton(
        layout: layout,
        label: l10n.demoModusAdvanceButton,
        icon: Icons.fast_forward,
        onPressed: onPressed,
        emphasis: PhaseActionEmphasis.outlined,
      ),
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
