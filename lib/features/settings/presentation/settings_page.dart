import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/vibrator.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/content_page_scaffold.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The app-wide settings for the Leitlinienprofil and alert signals.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.vibrator,
    required this.routes,
  });

  final AppSettings settings;
  final Vibrator vibrator;
  final AppRoutes routes;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  /// Null while unknown or on platforms that cannot report it.
  bool? _systemHapticsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkSystemHaptics());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The Zeitnehmer may have changed the system setting in the meantime.
    if (state == AppLifecycleState.resumed) unawaited(_checkSystemHaptics());
  }

  Future<void> _checkSystemHaptics() async {
    final enabled = await widget.vibrator.isSystemHapticsEnabled();
    if (mounted) setState(() => _systemHapticsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = widget.settings;

    return ContentPageScaffold.builder(
      title: l10n.settingsTitle,
      routes: widget.routes,
      currentDestination: AppDestination.einstellungen,
      bodyBuilder: (context) => AnimatedBuilder(
        animation: settings,
        builder: (context, _) => ListView(
          padding: PageLayout.contentPagePadding,
          children: [
            Text(
              l10n.settingsLeitlinienprofilSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PageLayout.space4),
            Text(
              l10n.settingsLeitlinienprofilDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PageLayout.space16),
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
            const Divider(height: PageLayout.space40),
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
            if (settings.vibrationEnabled && _systemHapticsEnabled == false)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: PageLayout.iconSmall,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: PageLayout.space8),
                  Expanded(
                    child: Text(
                      l10n.settingsVibrationSystemHapticsOff,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
