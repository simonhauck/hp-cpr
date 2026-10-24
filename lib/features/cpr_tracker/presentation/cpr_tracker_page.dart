import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';

class CprTrackerPage extends StatelessWidget {
  const CprTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.homeSubtitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.homeTitle,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.homeDescription, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.elapsedTimeLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.elapsedTimePlaceholder,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Chip(label: Text(l10n.statusNotStarted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startCprButton),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.comingSoonHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.setupCompleteTitle),
                    subtitle: Text(l10n.setupCompleteDescription),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
