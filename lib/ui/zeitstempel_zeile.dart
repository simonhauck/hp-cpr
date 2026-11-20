import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';

/// The case time over wall time column shared by all time-stamped rows.
class ZeitstempelSpalte extends StatelessWidget {
  const ZeitstempelSpalte({
    super.key,
    required this.zeitpunkt,
    required this.startzeit,
  });

  final Duration zeitpunkt;
  final DateTime startzeit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return SizedBox(
      width: PageLayout.timelineTimeWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatReanimationsdauer(zeitpunkt),
            style: theme.textTheme.labelLarge?.copyWith(
              color: muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            formatWallTime(startzeit.add(zeitpunkt)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// A time-stamped row: time column, icon, title, and optional detail.
class ZeitstempelZeile extends StatelessWidget {
  const ZeitstempelZeile({
    super.key,
    required this.zeitpunkt,
    required this.startzeit,
    required this.icon,
    required this.title,
    this.detail,
  });

  final Duration zeitpunkt;
  final DateTime startzeit;
  final IconData icon;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PageLayout.space16,
        vertical: PageLayout.space6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZeitstempelSpalte(zeitpunkt: zeitpunkt, startzeit: startzeit),
          Icon(
            icon,
            size: PageLayout.iconSmall,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: PageLayout.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
