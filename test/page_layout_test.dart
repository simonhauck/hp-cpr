import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/ui/layout/page_layout.dart';

void main() {
  PageLayout layout(double width, double height) =>
      PageLayout.from(BoxConstraints.tightFor(width: width, height: height));

  test('classifies small and large portrait phones', () {
    final small = layout(360, 640);
    expect(small.windowSize, WindowSizeClass.smallPhone);
    expect(small.isPhone, isTrue);
    expect(small.isLandscape, isFalse);
    expect(small.isCompact, isFalse);
    expect(small.stacksMedicationPanel, isTrue);
    expect(small.stacksStartHeader, isTrue);
    expect(small.usesTwoColumnStartCards, isFalse);
    expect(small.usesCompactHeaderChip, isTrue);
    expect(small.druckphaseTimerFontSize, PageLayout.phonePhaseTimerFontSize);
    expect(small.analysephaseTimerFontSize, PageLayout.phonePhaseTimerFontSize);

    final large = layout(430, 932);
    expect(large.windowSize, WindowSizeClass.largePhone);
    expect(large.isPhone, isTrue);
    expect(large.stacksMedicationPanel, isTrue);
    expect(large.stacksStartHeader, isTrue);
    expect(large.usesTwoColumnStartCards, isFalse);
  });

  test('keeps landscape phones compact and side by side', () {
    final smallLandscape = layout(568, 320);
    expect(smallLandscape.windowSize, WindowSizeClass.smallPhone);
    expect(smallLandscape.isLandscape, isTrue);
    expect(smallLandscape.isCompact, isTrue);
    expect(smallLandscape.stacksMedicationPanel, isFalse);
    expect(smallLandscape.stacksStartHeader, isFalse);
    expect(smallLandscape.usesTwoColumnStartCards, isTrue);

    final largeLandscape = layout(844, 390);
    expect(largeLandscape.windowSize, WindowSizeClass.largePhone);
    expect(largeLandscape.isLandscape, isTrue);
    expect(largeLandscape.isCompact, isTrue);
    expect(largeLandscape.stacksMedicationPanel, isFalse);
    expect(largeLandscape.usesTwoColumnStartCards, isTrue);
  });

  test('uses the tablet layout above the phone breakpoint', () {
    final tablet = layout(768, 1024);
    expect(tablet.windowSize, WindowSizeClass.tablet);
    expect(tablet.isPhone, isFalse);
    expect(tablet.isTablet, isTrue);
    expect(tablet.stacksMedicationPanel, isFalse);
    expect(tablet.stacksStartHeader, isFalse);
    expect(tablet.usesTwoColumnStartCards, isTrue);
    expect(
      tablet.druckphaseTimerFontSize,
      PageLayout.wideDruckphaseTimerFontSize,
    );
    expect(
      tablet.analysephaseTimerFontSize,
      PageLayout.wideAnalysephaseTimerFontSize,
    );

    expect(layout(1199, 800).windowSize, WindowSizeClass.tablet);
    expect(layout(1024, 768).windowSize, WindowSizeClass.tablet);
  });

  test('uses the desktop layout at 1200 width', () {
    final desktop = layout(1280, 800);
    expect(desktop.windowSize, WindowSizeClass.desktop);
    expect(desktop.isDesktop, isTrue);
    expect(desktop.isPhone, isFalse);
    expect(desktop.usesTwoColumnStartCards, isTrue);
    expect(
      desktop.druckphaseTimerFontSize,
      PageLayout.wideDruckphaseTimerFontSize,
    );

    expect(layout(1200, 800).windowSize, WindowSizeClass.desktop);
  });

  test('classifies phones by their shortest side', () {
    expect(layout(389, 844).windowSize, WindowSizeClass.smallPhone);
    expect(layout(390, 844).windowSize, WindowSizeClass.largePhone);
    expect(layout(844, 390).windowSize, WindowSizeClass.largePhone);
  });
}
