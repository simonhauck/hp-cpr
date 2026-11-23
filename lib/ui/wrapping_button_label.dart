import 'package:flutter/material.dart';

import 'package:hp_cpr/ui/layout/page_layout.dart';

/// A button label that wraps onto a second line before it shrinks.
///
/// The label keeps the button's text size and breaks between words when the
/// button is too narrow for one line. It scales down only as far as needed
/// when even [maxLines] lines do not fit, for example when a single word is
/// wider than the button.
class WrappingButtonLabel extends StatelessWidget {
  const WrappingButtonLabel(
    this.label, {
    super.key,
    this.maxLines = PageLayout.buttonLabelMaxLines,
  });

  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final text = Text(
          label,
          maxLines: maxLines,
          textAlign: TextAlign.center,
        );
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite) return text;

        final width = _fittingWidth(
          maxWidth,
          TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: textDirection,
            textScaler: textScaler,
            maxLines: maxLines,
          ),
        );
        if (width <= maxWidth) return text;

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(width: width, child: text),
        );
      },
    );
  }

  /// The narrowest width from [maxWidth] up at which the label fits into
  /// [maxLines] lines without breaking inside a word.
  static double _fittingWidth(double maxWidth, TextPainter painter) {
    try {
      bool fits(double width) {
        painter.layout(maxWidth: width);
        return !painter.didExceedMaxLines &&
            !_breaksInsideWord(painter) &&
            painter.width <= width;
      }

      if (fits(maxWidth)) return maxWidth;

      painter.layout();
      var low = maxWidth;
      var high = painter.width.ceilToDouble();
      while (high - low > 1) {
        final middle = (low + high) / 2;
        if (fits(middle)) {
          high = middle;
        } else {
          low = middle;
        }
      }
      return high;
    } finally {
      painter.dispose();
    }
  }

  /// Whether a line break of the laid-out [painter] falls inside a word.
  static bool _breaksInsideWord(TextPainter painter) {
    final text = painter.plainText;
    for (final line in painter.computeLineMetrics().skip(1)) {
      final offset = painter
          .getPositionForOffset(Offset(0, line.baseline))
          .offset;
      if (offset > 0 &&
          offset < text.length &&
          text[offset - 1] != ' ' &&
          text[offset] != ' ') {
        return true;
      }
    }
    return false;
  }
}
