import 'package:flutter/widgets.dart';

/// The layout decisions for a full app page.
///
/// The page has two modes: landscape/portrait, and a compact density for short
/// viewports. Compact is a height heuristic for landscape phones, not a
/// phone/tablet device class.
@immutable
class PageLayout {
  const PageLayout._({required this.isLandscape, required this.isCompact});

  factory PageLayout.from(BoxConstraints constraints) {
    return PageLayout._(
      isLandscape: constraints.maxWidth > constraints.maxHeight,
      isCompact: constraints.maxHeight < compactHeight,
    );
  }

  /// The viewport height below which the compact density is used.
  static const double compactHeight = 400;

  /// The shared maximum content width for the timer pages.
  static const double maxContentWidth = 1200;

  final bool isLandscape;
  final bool isCompact;

  EdgeInsets get pagePadding => isCompact
      ? const EdgeInsets.fromLTRB(16, 4, 16, 8)
      : const EdgeInsets.fromLTRB(16, 8, 16, 16);

  double get sectionGap => isCompact ? 8 : 12;

  /// The gap between the two main panels in landscape.
  double get panelGap => isCompact ? 12 : 16;

  EdgeInsets get cardPadding => EdgeInsets.all(isCompact ? 10 : 16);

  double get primaryActionHeight => isCompact ? 52 : 60;

  double get actionHeight => isCompact ? 48 : 54;

  double get secondaryActionHeight => isCompact ? 48 : 52;

  /// The gap between a card title and its subtitle.
  double get cardTitleGap => isCompact ? 2 : 4;

  /// The gap between a card subtitle and its controls.
  double get cardLabelGap => isCompact ? 6 : 8;

  /// The gap between a card's controls and its primary action.
  double get cardActionGap => isCompact ? 6 : 12;

  /// The gap between the main content and a full-width status strip.
  double get contentGap => isCompact ? 4 : 10;

  /// The gap between stacked status rows in the phase action bar.
  double get statusGap => isCompact ? 2 : 8;

  /// The gap after the Rhythmusanalyse result summary.
  double get resultSummaryGap => isCompact ? 2 : 10;

  /// The gap after the required-result hint.
  double get hintGap => isCompact ? 4 : 8;

  /// The horizontal gap between compact action buttons.
  double get compactActionGap => 8;

  /// The spacing between wrapped action buttons.
  double get actionWrapSpacing => 12;

  /// The run spacing between wrapped action buttons.
  double get actionWrapRunSpacing => 8;

  /// The minimum width of a phase action button.
  double get phaseActionMinWidth => isCompact ? 0 : 180;

  /// The horizontal padding of a compact phase action button.
  EdgeInsets? get phaseActionPadding =>
      isCompact ? const EdgeInsets.symmetric(horizontal: 14) : null;

  /// The padding inside a phase timer panel.
  EdgeInsets get phasePanelPadding => EdgeInsets.all(isCompact ? 4 : 20);

  /// The padding inside the Adrenalin panel.
  EdgeInsets get medicationPanelPadding => EdgeInsets.symmetric(
    horizontal: isCompact ? 10 : 14,
    vertical: isCompact ? 0 : 8,
  );

  /// The padding inside the rhythm-analysis result summary.
  EdgeInsets get resultSummaryPadding => EdgeInsets.symmetric(
    horizontal: isCompact ? 10 : 14,
    vertical: isCompact ? 0 : 10,
  );

  /// The minimum touch target for secondary actions.
  double get touchTarget => 48;

  /// The corner radius for status and medication cards.
  double get cardRadius => 16;

  /// The corner radius for a phase timer panel.
  double get phasePanelRadius => 28;

  /// The border width of an alerting phase panel.
  double get alertBorderWidth => 3;

  /// The border width of a normal phase panel.
  double get panelBorderWidth => 1;
}
