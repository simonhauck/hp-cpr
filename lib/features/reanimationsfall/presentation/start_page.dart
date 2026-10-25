import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/custom_startzeit_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/start_card.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/layout/page_scaffold.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// Starts a new Reanimationsfall or resumes the stored active one.
class StartPage extends StatefulWidget {
  const StartPage({
    super.key,
    required this.clock,
    required this.routes,
    required this.wakeLock,
    required this.session,
  });

  final AppClock clock;
  final AppRoutes routes;
  final WakeLock wakeLock;
  final ReanimationsfallSession session;

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  Reanimationsfall? _activeFall;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final fall = await widget.session.loadActive();
    if (!mounted) return;
    setState(() {
      _activeFall = fall;
      _loading = false;
    });
  }

  Future<void> _openReanimationsfall(Reanimationsfall reanimationsfall) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReanimationsfallPage(
          reanimationsfall: reanimationsfall,
          wakeLock: widget.wakeLock,
          routes: widget.routes,
          session: widget.session,
        ),
      ),
    );
    if (!mounted) return;
    await _loadActive();
  }

  Future<void> _startReanimationsfall(Duration backdate) async {
    final settings = widget.routes.settings;
    final reanimationsfall = Reanimationsfall.start(
      clock: widget.clock,
      leitlinienprofil: settings.leitlinienprofil,
      vibrationEnabled: settings.vibrationEnabled,
      soundEnabled: settings.soundEnabled,
      backdate: backdate,
    );

    await widget.session.persist(reanimationsfall);
    if (!mounted) return;
    await _openReanimationsfall(reanimationsfall);
  }

  Future<void> _resumeActive() async {
    final fall = _activeFall;
    if (fall == null) return;
    await _openReanimationsfall(fall);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      maxWidth: PageLayout.maxContentWidth,
      drawer: AppDrawer(routes: widget.routes),
      header: (context, layout) => _StartHeader(
        layout: layout,
        settings: widget.routes.settings,
        onOpenSettings: () => _openSettings(context),
      ),
      content: (context, layout) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeFall = _activeFall;
        if (activeFall != null) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PageLayout.activeCaseMaxWidth,
              ),
              child: _ActiveReanimationsfallCard(
                layout: layout,
                reanimationsfall: activeFall,
                onResume: _resumeActive,
              ),
            ),
          );
        }

        final startNowCard = _StartNowCard(
          layout: layout,
          onStart: () => _startReanimationsfall(Duration.zero),
        );
        final runningReanimationsfallCard = _RunningReanimationsfallCard(
          layout: layout,
          onStartBackdated: _startReanimationsfall,
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

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.routes.page(AppDestination.einstellungen),
      ),
    );
  }

  Future<void> _showCustomStartzeit(BuildContext context) async {
    final backdate = await showDialog<Duration>(
      context: context,
      builder: (_) => const CustomStartzeitDialog(),
    );

    if (backdate == null || !context.mounted) return;
    _startReanimationsfall(backdate);
  }
}

class _ActiveReanimationsfallCard extends StatelessWidget {
  const _ActiveReanimationsfallCard({
    required this.layout,
    required this.reanimationsfall,
    required this.onResume,
  });

  final PageLayout layout;
  final Reanimationsfall reanimationsfall;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return StartCard(
      layout: layout,
      children: [
        StartCardTitle(l10n.activeCaseTitle, layout: layout),
        SizedBox(height: layout.cardTitleGap),
        Text(
          l10n.activeCaseDescription,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: layout.cardLabelGap),
        LeitlinienprofilChip(
          leitlinienprofil: reanimationsfall.leitlinienprofil,
          compact: layout.isCompact,
        ),
        SizedBox(height: layout.cardLabelGap),
        Text(
          l10n.startzeitValue(formatWallTime(reanimationsfall.startzeit)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: layout.cardActionGap),
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.resumeCaseButton),
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(layout.primaryActionHeight),
            textStyle: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
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
