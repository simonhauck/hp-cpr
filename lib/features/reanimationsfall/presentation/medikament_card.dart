import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/theme/panel_tone.dart';

/// Shared shell of the medication cards: container, title row with status,
/// the "Gabe erfassen" button and the arrangement for the current layout.
///
/// A due or overdue [tone] tints the card, outlines it, turns the status into
/// a filled badge and fills the button, so the state does not depend on color
/// alone.
class MedikamentCard extends StatelessWidget {
  const MedikamentCard({
    super.key,
    required this.layout,
    required this.icon,
    required this.label,
    required this.stateLabel,
    required this.tone,
    required this.onRecord,
    this.details,
  });

  final PageLayout layout;
  final IconData icon;
  final String label;
  final String stateLabel;
  final PanelTone tone;

  /// Null disables the button.
  final VoidCallback? onRecord;

  /// Builds the detail content below the title; null shows nothing.
  /// The argument is true when the content may use several lines.
  final Widget Function(bool allowWrap)? details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = tone.colors(context);

    final buttonStyle = FilledButton.styleFrom(
      minimumSize: Size(PageLayout.space0, layout.medicationActionHeight),
      padding: const EdgeInsets.symmetric(horizontal: PageLayout.space8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: theme.textTheme.titleSmall,
    );
    final buttonLabel = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(l10n.medikamentGabeButton),
    );
    final gabeButton = tone.isEmphasized
        ? FilledButton(
            onPressed: onRecord,
            style: buttonStyle.copyWith(
              backgroundColor: WidgetStatePropertyAll(colors.accent),
              foregroundColor: WidgetStatePropertyAll(colors.onAccent),
            ),
            child: buttonLabel,
          )
        : FilledButton.tonal(
            onPressed: onRecord,
            style: buttonStyle,
            child: buttonLabel,
          );

    final status = tone.isEmphasized
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(layout.statusBadgeRadius),
            ),
            child: Padding(
              padding: layout.statusBadgePadding,
              child: Text(
                stateLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
        : Text(
            stateLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w700,
            ),
          );

    Widget titleRow({Widget? trailing}) {
      Widget row({Widget? trailing}) {
        return Row(
          children: [
            Icon(
              icon,
              size: PageLayout.iconSmall,
              color: tone.isEmphasized
                  ? colors.accent
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: PageLayout.space6),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: PageLayout.space8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, child: status),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: PageLayout.space8),
              trailing,
            ],
          ],
        );
      }

      if (trailing == null) return row();

      // Caps the button so a long label scales down instead of overflowing
      // the row on narrow phones or with large text.
      return LayoutBuilder(
        builder: (context, constraints) => row(
          trailing: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  constraints.maxWidth *
                  PageLayout.medicationActionMaxWidthFactor,
            ),
            child: trailing,
          ),
        ),
      );
    }

    Widget body({required bool allowWrap, Widget? trailing}) {
      return Column(
        crossAxisAlignment: allowWrap
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleRow(trailing: trailing),
          if (details != null) ...[
            const SizedBox(height: PageLayout.space2),
            details!(allowWrap),
          ],
        ],
      );
    }

    final Widget content;
    if (layout.placesMedicationBeside) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          body(allowWrap: false),
          SizedBox(height: layout.cardLabelGap),
          gabeButton,
        ],
      );
    } else if (layout.stacksMedicationPanel) {
      content = body(allowWrap: true, trailing: gabeButton);
    } else {
      content = Row(
        children: [
          Expanded(child: body(allowWrap: false)),
          const SizedBox(width: PageLayout.space8),
          gabeButton,
        ],
      );
    }

    return Container(
      padding: layout.medicationPanelPadding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        boxShadow: [
          if (tone.isEmphasized)
            BoxShadow(
              color: colors.border,
              spreadRadius: layout.medicationOutlineWidth,
            ),
        ],
      ),
      child: content,
    );
  }
}

/// "Letzte Gabe: 12:03 Uhr, vor 02:15", shared by all medication cards.
class MedikamentLetzteGabeText extends StatelessWidget {
  const MedikamentLetzteGabeText({
    super.key,
    required this.snapshot,
    required this.zeitpunkt,
    required this.color,
    required this.allowWrap,
  });

  final ReanimationsfallSnapshot snapshot;

  /// Reanimationsdauer at which the dose was given.
  final Duration zeitpunkt;
  final Color color;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Text(
      l10n.medikamentLetzteGabe(
        formatWallTimeMinutes(snapshot.startzeit.add(zeitpunkt)),
        formatElapsed(snapshot.reanimationsdauer - zeitpunkt),
      ),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    return allowWrap
        ? text
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: text,
          );
  }
}
