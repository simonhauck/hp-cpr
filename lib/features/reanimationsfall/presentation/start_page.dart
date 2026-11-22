import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/core/vibrator.dart';
import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_page.dart';
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
    required this.vibrator,
    required this.session,
  });

  final AppClock clock;
  final AppRoutes routes;
  final WakeLock wakeLock;
  final Vibrator vibrator;
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
          vibrator: widget.vibrator,
          routes: widget.routes,
          session: widget.session,
        ),
      ),
    );
    if (!mounted) return;
    await _loadActive();
  }

  Future<void> _startReanimationsfall() async {
    final settings = widget.routes.settings;
    final reanimationsfall = Reanimationsfall.start(
      clock: widget.clock,
      leitlinienprofil: settings.leitlinienprofil,
      vibrationEnabled: settings.vibrationEnabled,
      soundEnabled: settings.soundEnabled,
      demoMode: settings.demoMode,
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
      endDrawer: AppDrawer(routes: widget.routes),
      footer: !_loading && _activeFall == null
          ? (context, layout) => _DemoModusToggle(
              settings: widget.routes.settings,
              layout: layout,
            )
          : null,
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

        // A resuscitation that was already running is captured afterwards in
        // the Vorbehandlung form, so the start page asks nothing up front.
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PageLayout.activeCaseMaxWidth,
              ),
              child: _StartNowCard(
                layout: layout,
                onStart: _startReanimationsfall,
              ),
            ),
          ),
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
    final appTitleStyle =
        (layout.isCompact
                ? theme.textTheme.labelSmall
                : theme.textTheme.labelLarge)
            ?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: PageLayout.appTitleLetterSpacing,
            );
    final titleStyle =
        (layout.isCompact
                ? theme.textTheme.titleMedium
                : theme.textTheme.headlineSmall)
            ?.copyWith(fontWeight: FontWeight.w700);

    final chip = AnimatedBuilder(
      animation: settings,
      builder: (context, _) => LeitlinienprofilChip(
        leitlinienprofil: settings.leitlinienprofil,
        compact: layout.isCompact,
        onPressed: onOpenSettings,
      ),
    );

    if (layout.stacksStartHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.appTitle, style: appTitleStyle),
              const Spacer(),
              chip,
              const SizedBox(width: PageLayout.space8),
              const AppMenuButton(),
            ],
          ),
          const SizedBox(height: PageLayout.space4),
          Text(l10n.newCaseTitle, style: titleStyle),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appTitle, style: appTitleStyle),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(l10n.newCaseTitle, style: titleStyle),
              ),
            ],
          ),
        ),
        chip,
        const SizedBox(width: PageLayout.space8),
        const AppMenuButton(),
      ],
    );
  }
}

class _DemoModusToggle extends StatelessWidget {
  const _DemoModusToggle({required this.settings, required this.layout});

  final AppSettings settings;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PageLayout.activeCaseMaxWidth,
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: layout.demoModeToggleDensity,
              title: Text(l10n.demoModusToggleLabel),
              subtitle: layout.showSettingDescriptions
                  ? Text(l10n.demoModusToggleDescription)
                  : null,
              value: settings.demoMode,
              onChanged: (value) => settings.demoMode = value,
            ),
          ),
        );
      },
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
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.startNowButton),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(layout.primaryActionHeight),
              textStyle: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}
