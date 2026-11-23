import 'package:flutter/material.dart';

import 'package:hp_cpr/ui/layout/page_layout.dart';

/// A SnackBar-styled notice pinned to the top of the running case.
///
/// It confirms a one-tap entry and offers to undo it. It sits over the
/// header, so the phase, medication, and footer actions stay reachable while
/// it is shown. Swiping it up dismisses it.
class UndoBanner extends StatelessWidget {
  const UndoBanner({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onUndo,
    required this.onDismissed,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onUndo;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final snackBarTheme = theme.snackBarTheme;

    return Dismissible(
      key: ValueKey(text),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismissed(),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Material(
          color: snackBarTheme.backgroundColor ?? colors.inverseSurface,
          elevation: snackBarTheme.elevation ?? PageLayout.space6,
          borderRadius: BorderRadius.circular(PageLayout.radius4),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: PageLayout.space16,
              end: PageLayout.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: PageLayout.space14,
                    ),
                    child: Text(
                      text,
                      style:
                          (snackBarTheme.contentTextStyle ??
                                  theme.textTheme.bodyMedium)
                              ?.copyWith(color: colors.onInverseSurface),
                    ),
                  ),
                ),
                const SizedBox(width: PageLayout.space8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        snackBarTheme.actionTextColor ?? colors.inversePrimary,
                  ),
                  onPressed: onUndo,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
