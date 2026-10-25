import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/custom_startzeit_dialog.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/features/settings/presentation/settings_page.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// Starts a new Reanimationsfall, either now or with a corrected Startzeit.
class StartPage extends StatelessWidget {
  const StartPage({
    super.key,
    required this.clock,
    required this.settings,
    required this.wakeLock,
  });

  final AppClock clock;
  final AppSettings settings;
  final WakeLock wakeLock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, viewport) {
                final isLandscape = viewport.maxWidth > viewport.maxHeight;
                final isCompact = viewport.maxHeight < 400;

                final startNowCard = _StartNowCard(
                  compact: isCompact,
                  onStart: () => _startReanimationsfall(context, Duration.zero),
                );
                final runningReanimationsfallCard =
                    _RunningReanimationsfallCard(
                      compact: isCompact,
                      onStartBackdated: (backdate) =>
                          _startReanimationsfall(context, backdate),
                      onCustomStartzeit: () => _showCustomStartzeit(context),
                    );

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    isCompact ? 6 : 12,
                    16,
                    isCompact ? 6 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.appTitle,
                                  style:
                                      (isCompact
                                              ? theme.textTheme.labelSmall
                                              : theme.textTheme.labelLarge)
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            letterSpacing: 1.2,
                                          ),
                                ),
                                Text(
                                  l10n.newCaseTitle,
                                  style:
                                      (isCompact
                                              ? theme.textTheme.titleMedium
                                              : theme.textTheme.headlineSmall)
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: settings,
                            builder: (context, _) => LeitlinienprofilChip(
                              leitlinienprofil: settings.leitlinienprofil,
                              compact: isCompact,
                              onPressed: () => _openSettings(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Expanded(
                        child: isLandscape
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: startNowCard),
                                  const SizedBox(width: 12),
                                  Expanded(child: runningReanimationsfallCard),
                                ],
                              )
                            : ListView(
                                children: [
                                  startNowCard,
                                  const SizedBox(height: 12),
                                  runningReanimationsfallCard,
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _startReanimationsfall(BuildContext context, Duration backdate) {
    final reanimationsfall = Reanimationsfall.start(
      clock: clock,
      leitlinienprofil: settings.leitlinienprofil,
      vibrationEnabled: settings.vibrationEnabled,
      soundEnabled: settings.soundEnabled,
      backdate: backdate,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReanimationsfallPage(
          reanimationsfall: reanimationsfall,
          wakeLock: wakeLock,
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SettingsPage(settings: settings)),
    );
  }

  Future<void> _showCustomStartzeit(BuildContext context) async {
    final backdate = await showDialog<Duration>(
      context: context,
      builder: (_) => const CustomStartzeitDialog(),
    );

    if (backdate == null || !context.mounted) return;
    _startReanimationsfall(context, backdate);
  }
}

class _StartNowCard extends StatelessWidget {
  const _StartNowCard({required this.compact, required this.onStart});

  final bool compact;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!compact) ...[
              Icon(
                Icons.play_circle_outline,
                size: 36,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              l10n.startNowTitle,
              textAlign: TextAlign.center,
              style:
                  (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                l10n.startNowDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startNowButton),
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(compact ? 52 : 60),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningReanimationsfallCard extends StatelessWidget {
  const _RunningReanimationsfallCard({
    required this.compact,
    required this.onStartBackdated,
    required this.onCustomStartzeit,
  });

  final bool compact;
  final ValueChanged<Duration> onStartBackdated;
  final VoidCallback onCustomStartzeit;

  static const _backdatePresets = [
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 8),
    Duration(minutes: 10),
    Duration(minutes: 12),
    Duration(minutes: 15),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.runningCaseTitle,
              textAlign: TextAlign.center,
              style:
                  (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              l10n.backdateMinutesLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final backdate in _backdatePresets)
                  ActionChip(
                    label: Text('${backdate.inMinutes}'),
                    labelStyle: theme.textTheme.titleSmall,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tooltip: l10n.backdateChip(backdate.inMinutes),
                    onPressed: () => onStartBackdated(backdate),
                  ),
              ],
            ),
            SizedBox(height: compact ? 6 : 12),
            OutlinedButton.icon(
              onPressed: onCustomStartzeit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.customStartzeitButton),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(compact ? 48 : 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
