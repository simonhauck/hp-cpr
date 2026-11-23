import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/wrapping_button_label.dart';

enum PhaseActionEmphasis { filled, outlined }

/// The secondary actions for the running Reanimationsfall.
///
/// Phase-specific primary actions live in the timer panel; this bar keeps the
/// Aktionen entry point and the Demo-Modus control within reach.
class PhaseActionBar extends StatelessWidget {
  const PhaseActionBar({
    super.key,
    required this.layout,
    required this.onOpenActions,
    this.onRecordVorbehandlung,
    this.onAdvanceDemoTime,
  });

  final PageLayout layout;
  final VoidCallback onOpenActions;

  /// Opens the Vorbehandlung form; null once it was saved or the case ended.
  final VoidCallback? onRecordVorbehandlung;

  /// Advances the simulated case time; null outside Demo-Modus.
  final VoidCallback? onAdvanceDemoTime;

  @override
  Widget build(BuildContext context) {
    final advanceDemoTime = onAdvanceDemoTime;
    final recordVorbehandlung = onRecordVorbehandlung;
    // Phones keep the buttons and Aktionen on one row. The Demo-Modus button
    // is dense and keeps its short width, so the Vorbehandlung button gets
    // the room.
    final inline = recordVorbehandlung != null && layout.isPhone;

    return PhaseActionRow(
      layout: layout,
      inline: inline,
      buttons: [
        if (advanceDemoTime != null)
          DemoAdvanceButton(
            layout: layout,
            onPressed: advanceDemoTime,
            dense: recordVorbehandlung != null ? true : null,
          ),
        if (recordVorbehandlung != null)
          VorbehandlungButton(layout: layout, onPressed: recordVorbehandlung),
      ],
      actionsButton: ActionsButton(layout: layout, onPressed: onOpenActions),
    );
  }
}

/// A phase action with a short label that keeps its own width in a
/// [PhaseActionRow] instead of sharing the row equally.
abstract interface class ShortPhaseAction implements Widget {}

/// The shared responsive row for phase actions and the Aktionen entry point.
class PhaseActionRow extends StatelessWidget {
  const PhaseActionRow({
    super.key,
    required this.layout,
    required this.buttons,
    required this.actionsButton,
    this.inline = false,
  });

  final PageLayout layout;
  final List<Widget> buttons;
  final Widget actionsButton;

  /// Whether to lay the buttons out in one row beside the Aktionen entry even
  /// when the layout is not compact. The buttons must then be dense.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    if (layout.isCompact || inline) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) SizedBox(width: layout.compactActionGap),
            if (buttons[i] is ShortPhaseAction)
              buttons[i]
            else
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
class DemoAdvanceButton extends StatelessWidget implements ShortPhaseAction {
  const DemoAdvanceButton({
    super.key,
    required this.layout,
    required this.onPressed,
    this.dense,
  });

  final PageLayout layout;
  final VoidCallback onPressed;

  /// Overrides the dense style; null follows the layout.
  final bool? dense;

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
        dense: dense,
      ),
    );
  }
}

/// Opens the Vorbehandlung form until it was saved once in the case.
class VorbehandlungButton extends StatelessWidget {
  const VorbehandlungButton({
    super.key,
    required this.layout,
    required this.onPressed,
  });

  final PageLayout layout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PhaseActionButton(
      layout: layout,
      label: l10n.vorbehandlungErfassen,
      icon: Icons.history,
      onPressed: onPressed,
      emphasis: PhaseActionEmphasis.outlined,
      dense: layout.usesDensePhaseActions,
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
    this.dense,
  });

  final PageLayout layout;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final PhaseActionEmphasis emphasis;

  /// Whether to use the dense icon-less style; defaults to the compact layout.
  /// A dense label wraps onto a second line before it scales down.
  final bool? dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDense = dense ?? layout.isCompact;
    final style = _style(theme, isDense);

    if (isDense) {
      final child = WrappingButtonLabel(label);
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

  ButtonStyle _style(ThemeData theme, bool isDense) {
    final minimumSize = Size(
      isDense ? PageLayout.space0 : layout.phaseActionMinWidth,
      layout.actionHeight,
    );
    final padding = isDense
        ? PageLayout.densePhaseActionPadding
        : layout.phaseActionPadding;
    final textStyle = isDense
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
