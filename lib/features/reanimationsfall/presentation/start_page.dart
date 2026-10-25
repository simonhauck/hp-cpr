import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/custom_startzeit_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/start_card.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/layout/page_scaffold.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// Starts a new Reanimationsfall, either now or with a corrected Startzeit.
class StartPage extends StatelessWidget {
  const StartPage({
    super.key,
    required this.clock,
    required this.routes,
    required this.wakeLock,
  });

  final AppClock clock;
  final AppRoutes routes;
  final WakeLock wakeLock;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      maxWidth: PageLayout.maxContentWidth,
      drawer: AppDrawer(routes: routes),
      header: (context, layout) => _StartHeader(
        layout: layout,
        settings: routes.settings,
        onOpenSettings: () => _openSettings(context),
      ),
      content: (context, layout) {
        final startNowCard = _StartNowCard(
          layout: layout,
          onStart: () => _startReanimationsfall(context, Duration.zero),
        );
        final runningReanimationsfallCard = _RunningReanimationsfallCard(
          layout: layout,
          onStartBackdated: (backdate) =>
              _startReanimationsfall(context, backdate),
          onCustomStartzeit: () => _showCustomStartzeit(context),
        );

        return layout.isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: startNowCard),
                  const SizedBox(width: PageLayout.space12),
                  Expanded(child: runningReanimationsfallCard),
                ],
              )
            : ListView(
                children: [
                  startNowCard,
                  const SizedBox(height: PageLayout.space12),
                  runningReanimationsfallCard,
                ],
              );
      },
    );
  }

  void _startReanimationsfall(BuildContext context, Duration backdate) {
    final settings = routes.settings;
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
          routes: routes,
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => routes.page(AppDestination.einstellungen),
      ),
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

class _StartHeader extends StatelessWidget {
  const _StartHeader({
    required this.layout,
    required this.settings,
    required this.onOpenSettings,
  });

  final PageLayout layout;
  final AppSettings settings;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                style:
                    (layout.isCompact
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.labelLarge)
                        ?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: PageLayout.appTitleLetterSpacing,
                        ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.newCaseTitle,
                  style:
                      (layout.isCompact
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: settings,
          builder: (context, _) => LeitlinienprofilChip(
            leitlinienprofil: settings.leitlinienprofil,
            compact: layout.isCompact,
            onPressed: onOpenSettings,
          ),
        ),
        const SizedBox(width: PageLayout.space8),
        const AppMenuButton(),
      ],
    );
  }
}

class _StartNowCard extends StatelessWidget {
  const _StartNowCard({required this.layout, required this.onStart});

  final PageLayout layout;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return StartCard(
      layout: layout,
      children: [
        if (!layout.isCompact) ...[
          Icon(
            Icons.play_circle_outline,
            size: PageLayout.iconLarge,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: PageLayout.space4),
        ],
        StartCardTitle(l10n.startNowTitle, layout: layout),
        if (!layout.isCompact) ...[
          const SizedBox(height: PageLayout.space4),
          Text(
            l10n.startNowDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PageLayout.space16),
        ] else
          const SizedBox(height: PageLayout.space8),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.startNowButton),
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(layout.primaryActionHeight),
            textStyle: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _RunningReanimationsfallCard extends StatelessWidget {
  const _RunningReanimationsfallCard({
    required this.layout,
    required this.onStartBackdated,
    required this.onCustomStartzeit,
  });

  final PageLayout layout;
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

    return StartCard(
      layout: layout,
      children: [
        StartCardTitle(l10n.runningCaseTitle, layout: layout),
        SizedBox(height: layout.cardTitleGap),
        Text(
          l10n.backdateMinutesLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: layout.cardLabelGap),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: layout.actionWrapRunSpacing,
          runSpacing: layout.actionWrapRunSpacing,
          children: [
            for (final backdate in _backdatePresets)
              ActionChip(
                label: Text('${backdate.inMinutes}'),
                labelStyle: theme.textTheme.titleSmall,
                padding: const EdgeInsets.symmetric(
                  horizontal: PageLayout.space8,
                  vertical: PageLayout.space4,
                ),
                tooltip: l10n.backdateChip(backdate.inMinutes),
                onPressed: () => onStartBackdated(backdate),
              ),
          ],
        ),
        SizedBox(height: layout.cardActionGap),
        OutlinedButton.icon(
          onPressed: onCustomStartzeit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.customStartzeitButton),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(layout.secondaryActionHeight),
          ),
        ),
      ],
    );
  }
}
