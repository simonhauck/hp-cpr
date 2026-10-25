import 'package:flutter/material.dart';

import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The shared shell for the two start choices.
class StartCard extends StatelessWidget {
  const StartCard({super.key, required this.layout, required this.children});

  final PageLayout layout;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: layout.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

/// The responsive title used by a [StartCard].
class StartCardTitle extends StatelessWidget {
  const StartCardTitle(this.text, {super.key, required this.layout});

  final String text;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      textAlign: TextAlign.center,
      style:
          (layout.isCompact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge)
              ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
