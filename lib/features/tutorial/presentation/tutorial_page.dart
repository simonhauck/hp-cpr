import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/wrapping_button_label.dart';

/// How the tutorial was left.
enum TutorialOutcome { closed, startDemo }

/// Opens the tutorial and resolves how it was left.
Future<TutorialOutcome> showTutorial(
  BuildContext context, {
  required bool canStartDemo,
}) async {
  final outcome = await Navigator.of(context).push<TutorialOutcome>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TutorialPage(canStartDemo: canStartDemo),
    ),
  );
  return outcome ?? TutorialOutcome.closed;
}

/// A short swipeable introduction to the app.
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, required this.canStartDemo});

  /// Whether the last page offers to start a Reanimationsfall in Demo-Modus.
  /// It is false while another Reanimationsfall is active.
  final bool canStartDemo;

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([TutorialOutcome outcome = TutorialOutcome.closed]) {
    Navigator.of(context).pop(outcome);
  }

  void _next() {
    _controller.nextPage(
      duration: PageLayout.tutorialPageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  List<_Slide> _slides(AppLocalizations l10n) => [
    _Slide(
      Icons.favorite_outline,
      l10n.tutorialWelcomeTitle,
      l10n.tutorialWelcomeBody,
    ),
    _Slide(
      Icons.play_circle_outline,
      l10n.tutorialStartTitle,
      l10n.tutorialStartBody,
    ),
    _Slide(
      Icons.timer_outlined,
      l10n.tutorialDruckphaseTitle,
      l10n.tutorialDruckphaseBody,
    ),
    _Slide(
      Icons.medication_outlined,
      l10n.tutorialMedikamenteTitle,
      l10n.tutorialMedikamenteBody,
    ),
    _Slide(
      Icons.edit_note,
      l10n.tutorialAktionenTitle,
      l10n.tutorialAktionenBody,
    ),
    _Slide(Icons.flag_outlined, l10n.tutorialEndTitle, l10n.tutorialEndBody),
    _Slide(
      Icons.science_outlined,
      l10n.tutorialDemoTitle,
      widget.canStartDemo
          ? l10n.tutorialDemoBody
          : l10n.tutorialDemoActiveCaseBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = _slides(l10n);
    final isLast = _page == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = PageLayout.from(constraints);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PageLayout.activeCaseMaxWidth,
                ),
                child: Padding(
                  padding: layout.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.tutorialTitle,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    letterSpacing:
                                        PageLayout.appTitleLetterSpacing,
                                  ),
                            ),
                          ),
                          Visibility(
                            visible: !isLast,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: TextButton(
                              onPressed: _close,
                              child: Text(l10n.tutorialSkip),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: PageView(
                          controller: _controller,
                          onPageChanged: (page) => setState(() => _page = page),
                          children: [
                            for (final slide in slides)
                              _TutorialSlide(slide: slide, layout: layout),
                          ],
                        ),
                      ),
                      SizedBox(height: layout.sectionGap),
                      _PageDots(count: slides.length, current: _page),
                      SizedBox(height: layout.sectionGap),
                      ..._actions(context, l10n, layout, isLast),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    AppLocalizations l10n,
    PageLayout layout,
    bool isLast,
  ) {
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: Size.fromHeight(layout.actionHeight),
      textStyle: Theme.of(context).textTheme.titleMedium,
    );

    if (!isLast) {
      return [
        FilledButton(
          onPressed: _next,
          style: buttonStyle,
          child: Text(l10n.tutorialNext),
        ),
      ];
    }

    if (!widget.canStartDemo) {
      return [
        FilledButton(
          onPressed: _close,
          style: buttonStyle,
          child: Text(l10n.tutorialDone),
        ),
      ];
    }

    return [
      FilledButton.icon(
        onPressed: () => _close(TutorialOutcome.startDemo),
        style: buttonStyle,
        icon: const Icon(Icons.play_arrow),
        label: WrappingButtonLabel(l10n.tutorialStartDemoButton),
      ),
      SizedBox(height: layout.compactActionGap),
      TextButton(
        onPressed: _close,
        style: TextButton.styleFrom(
          minimumSize: Size.fromHeight(layout.touchTarget),
        ),
        child: Text(l10n.tutorialLater),
      ),
    ];
  }
}

class _Slide {
  const _Slide(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class _TutorialSlide extends StatelessWidget {
  const _TutorialSlide({required this.slide, required this.layout});

  final _Slide slide;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (layout.showsTutorialIcon) ...[
              Icon(
                slide.icon,
                size: PageLayout.tutorialIconSize,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: PageLayout.space24),
            ],
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style:
                  (layout.isCompact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: layout.hintGap),
            Text(
              slide.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.tutorialPageIndicator(current + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: PageLayout.tutorialPageDuration,
                margin: const EdgeInsets.symmetric(
                  horizontal: PageLayout.space4,
                ),
                width: i == current
                    ? PageLayout.tutorialActiveDotWidth
                    : PageLayout.tutorialDotSize,
                height: PageLayout.tutorialDotSize,
                decoration: BoxDecoration(
                  color: i == current ? colors.primary : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(
                    PageLayout.tutorialDotSize,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
