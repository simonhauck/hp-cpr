import 'package:flutter/material.dart';

import 'package:hp_cpr/ui/theme/due_colors.dart';

/// How urgently a panel asks for attention. Due is amber; red is reserved for
/// overdue.
enum PanelTone {
  neutral,
  due,
  overdue;

  bool get isEmphasized => this != neutral;

  PanelToneColors colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = DueColors.of(context);

    return switch (this) {
      neutral => PanelToneColors(
        background: scheme.surfaceContainerHighest,
        border: scheme.outlineVariant,
        accent: scheme.onSurfaceVariant,
        onAccent: scheme.surface,
      ),
      PanelTone.due => PanelToneColors(
        background: due.dueContainer,
        border: due.due,
        accent: due.due,
        onAccent: due.onDue,
      ),
      overdue => PanelToneColors(
        background: scheme.errorContainer,
        border: scheme.error,
        accent: scheme.error,
        onAccent: scheme.onError,
      ),
    };
  }
}

@immutable
class PanelToneColors {
  const PanelToneColors({
    required this.background,
    required this.border,
    required this.accent,
    required this.onAccent,
  });

  final Color background;
  final Color border;

  /// Text, bars, and filled badges and buttons on [background].
  final Color accent;

  /// Content on a filled [accent] surface.
  final Color onAccent;
}
