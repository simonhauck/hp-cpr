import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Shared shell of the medication cards: container, title row with status
/// label, the "Gabe erfassen" button and the stacked or side-by-side layout.
class MedikamentCard extends StatelessWidget {
  const MedikamentCard({
    super.key,
    required this.layout,
    required this.icon,
    required this.label,
    required this.stateLabel,
    required this.stateColor,
    required this.onRecord,
    this.details,
  });

  final PageLayout layout;
  final IconData icon;
  final String label;
  final String stateLabel;
  final Color stateColor;

  /// Null disables the button.
  final VoidCallback? onRecord;

  /// Builds the detail content below the title; null shows nothing.
  /// The argument is true when the content may use several lines.
  final Widget Function(bool allowWrap)? details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final gabeButton = FilledButton.tonal(
      onPressed: onRecord,
      style: FilledButton.styleFrom(
        minimumSize: Size(PageLayout.space0, layout.medicationActionHeight),
        padding: const EdgeInsets.symmetric(horizontal: PageLayout.space8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: theme.textTheme.titleSmall,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(l10n.medikamentGabeButton),
      ),
    );

    Widget titleRow({Widget? trailing}) {
      return Row(
        children: [
          Icon(
            icon,
            size: PageLayout.iconSmall,
            color: theme.colorScheme.primary,
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
          if (trailing != null) ...[
            const SizedBox(width: PageLayout.space8),
            trailing,
          ],
        ],
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

    return Container(
      padding: layout.medicationPanelPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(layout.cardRadius),
      ),
      child: layout.stacksMedicationPanel
          ? body(allowWrap: true, trailing: gabeButton)
          : Row(
              children: [
                Expanded(child: body(allowWrap: false)),
                const SizedBox(width: PageLayout.space8),
                gabeButton,
              ],
            ),
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
