import 'package:flutter/widgets.dart';

/// The layout decisions and shared design tokens for the app.
///
/// The page has two modes: landscape/portrait, and a compact density for short
/// viewports. Compact is a height heuristic for landscape phones, not a
/// phone/tablet device class.
///
/// Spacing, radii, icon sizes, touch targets, and the timer-page font sizes
/// live here. Feature widgets must not introduce their own pixel offsets or
/// compact/regular ternaries; use the shared tokens or a semantic getter.
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

  // Spacing scale. These are the only spacing values used by layout code.
  static const double space0 = 0;
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space40 = 40;

  // Corner radii.
  static const double radius2 = 2;
  static const double radius4 = 4;
  static const double radius16 = 16;
  static const double radius28 = 28;

  // Icon and control sizes.
  static const double iconSmall = 18;
  static const double iconLarge = 36;
  static const double dialogActionWidth = 200;
  static const double dialogActionHeight = 56;
  static const double dialogOptionHeight = 52;
  static const double settingsContentWidth = 720;
  static const double touchTargetSize = 48;

  // The Adrenalin Zeitfenster bar.
  static const double barHeight = 8;
  static const double barTickWidth = 2;
  static const double barMarkerWidth = 4;
  static const double barOverhang = 2;

  // Timer typography.
  static const double druckphaseTimerFontSize = 150;
  static const double analysephaseTimerFontSize = 84;
  static const double appTitleLetterSpacing = 1.2;
  static const double timerLineHeight = 1;

  // The landscape split between the elapsed panel and the timer panel.
  static const int elapsedPanelFlex = 4;
  static const int timerPanelFlex = 6;

  final bool isLandscape;
  final bool isCompact;

  EdgeInsets get pagePadding => isCompact
      ? const EdgeInsets.fromLTRB(space16, space4, space16, space8)
      : const EdgeInsets.fromLTRB(space16, space8, space16, space16);

  double get sectionGap => isCompact ? space8 : space12;

  /// The gap between the two main panels in landscape.
  double get panelGap => isCompact ? space12 : space16;

  EdgeInsets get cardPadding => EdgeInsets.all(isCompact ? space10 : space16);

  double get primaryActionHeight => isCompact ? 52 : 60;

  double get actionHeight => isCompact ? 48 : 54;

  double get secondaryActionHeight => isCompact ? 48 : 52;

  /// The gap between a card title and its subtitle.
  double get cardTitleGap => isCompact ? space2 : space4;

  /// The gap between a card subtitle and its controls.
  double get cardLabelGap => isCompact ? space6 : space8;

  /// The gap between a card's controls and its primary action.
  double get cardActionGap => isCompact ? space6 : space12;

  /// The gap between the main content and a full-width status strip.
  double get contentGap => isCompact ? space4 : space10;

  /// The gap between stacked status rows in the phase action bar.
  double get statusGap => isCompact ? space2 : space8;

  /// The gap after the Rhythmusanalyse result summary.
  double get resultSummaryGap => isCompact ? space2 : space10;

  /// The gap after the required-result hint.
  double get hintGap => isCompact ? space4 : space8;

  /// The horizontal gap between compact action buttons.
  double get compactActionGap => space8;

  /// The spacing between wrapped action buttons.
  double get actionWrapSpacing => space12;

  /// The run spacing between wrapped action buttons.
  double get actionWrapRunSpacing => space8;

  /// The minimum width of a phase action button.
  double get phaseActionMinWidth => isCompact ? 0 : 180;

  /// The horizontal padding of a compact phase action button.
  EdgeInsets? get phaseActionPadding =>
      isCompact ? const EdgeInsets.symmetric(horizontal: space14) : null;

  /// The padding inside a phase timer panel.
  EdgeInsets get phasePanelPadding =>
      EdgeInsets.all(isCompact ? space4 : space20);

  /// The padding inside the Adrenalin panel.
  EdgeInsets get medicationPanelPadding => EdgeInsets.symmetric(
    horizontal: isCompact ? space10 : space14,
    vertical: isCompact ? space0 : space8,
  );

  /// The padding inside the rhythm-analysis result summary.
  EdgeInsets get resultSummaryPadding => EdgeInsets.symmetric(
    horizontal: isCompact ? space10 : space14,
    vertical: isCompact ? space0 : space10,
  );

  /// The minimum touch target for secondary actions.
  double get touchTarget => touchTargetSize;

  /// The corner radius for status and medication cards.
  double get cardRadius => radius16;

  /// The corner radius for a phase timer panel.
  double get phasePanelRadius => radius28;

  /// The border width of an alerting phase panel.
  double get alertBorderWidth => 3;

  /// The border width of a normal phase panel.
  double get panelBorderWidth => 1;
}
