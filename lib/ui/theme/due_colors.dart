import 'package:flutter/material.dart';

/// Colors for "due now" states, distinct from the error red that is reserved
/// for overdue and alert states.
@immutable
class DueColors extends ThemeExtension<DueColors> {
  const DueColors({
    required this.due,
    required this.onDue,
    required this.dueContainer,
    required this.onDueContainer,
  });

  /// Accent for text, icons and bars on a neutral surface.
  final Color due;
  final Color onDue;

  /// Filled surface for a due panel.
  final Color dueContainer;
  final Color onDueContainer;

  static const light = DueColors(
    due: Color(0xFF8A5100),
    onDue: Color(0xFFFFFFFF),
    dueContainer: Color(0xFFFFDDB3),
    onDueContainer: Color(0xFF2C1700),
  );

  static const dark = DueColors(
    due: Color(0xFFFFB95C),
    onDue: Color(0xFF482900),
    dueContainer: Color(0xFF663D00),
    onDueContainer: Color(0xFFFFDDB3),
  );

  /// The due colors of the surrounding [Theme].
  static DueColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<DueColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  DueColors copyWith({
    Color? due,
    Color? onDue,
    Color? dueContainer,
    Color? onDueContainer,
  }) => DueColors(
    due: due ?? this.due,
    onDue: onDue ?? this.onDue,
    dueContainer: dueContainer ?? this.dueContainer,
    onDueContainer: onDueContainer ?? this.onDueContainer,
  );

  @override
  DueColors lerp(DueColors? other, double t) {
    if (other == null) return this;
    return DueColors(
      due: Color.lerp(due, other.due, t)!,
      onDue: Color.lerp(onDue, other.onDue, t)!,
      dueContainer: Color.lerp(dueContainer, other.dueContainer, t)!,
      onDueContainer: Color.lerp(onDueContainer, other.onDueContainer, t)!,
    );
  }
}
