import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The app-wide settings for the Leitlinienprofil and alert signals.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AnimatedBuilder(
              animation: settings,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    l10n.settingsLeitlinienprofilSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsLeitlinienprofilDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<Leitlinienprofil>(
                    segments: [
                      ButtonSegment(
                        value: Leitlinienprofil.erc2025,
                        label: Text(l10n.guidelineErc2025),
                      ),
                      ButtonSegment(
                        value: Leitlinienprofil.aha2025,
                        label: Text(l10n.guidelineAha2025),
                      ),
                    ],
                    selected: {settings.leitlinienprofil},
                    onSelectionChanged: (selection) {
                      settings.leitlinienprofil = selection.single;
                    },
                  ),
                  const Divider(height: 40),
                  Text(
                    l10n.settingsAlertsSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsVibration),
                    subtitle: Text(l10n.settingsVibrationDescription),
                    value: settings.vibrationEnabled,
                    onChanged: (value) => settings.vibrationEnabled = value,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsSound),
                    subtitle: Text(l10n.settingsSoundDescription),
                    value: settings.soundEnabled,
                    onChanged: (value) => settings.soundEnabled = value,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
