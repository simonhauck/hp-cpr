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
}
