import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwerte_page.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/adrenalin_panel.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/amiodaron_panel.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/end_reanimationsfall_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/phase_action_bar.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_summary_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_notiz_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/schock_energie_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/skip_rhythmusanalyse_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/layout/page_scaffold.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The running Reanimationsfall in its current Reanimationsphase.
class ReanimationsfallPage extends StatefulWidget {
  const ReanimationsfallPage({
    super.key,
    required this.reanimationsfall,
    required this.wakeLock,
    required this.routes,
    required this.session,
  });

  final Reanimationsfall reanimationsfall;
  final WakeLock wakeLock;
  final AppRoutes routes;
  final ReanimationsfallSession session;

  @override
  State<ReanimationsfallPage> createState() => _ReanimationsfallPageState();
}

class _ReanimationsfallPageState extends State<ReanimationsfallPage>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool _amiodaronHinweisAusgeblendet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.wakeLock.enable());
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.wakeLock.disable());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      widget.reanimationsfall.reconcileWithWallClock();
      setState(() {});
    }
  }

  void _mutate(VoidCallback action) {
    setState(action);
    unawaited(widget.session.persist(widget.reanimationsfall));
  }

  void _enterAnalysephase() {
    _mutate(widget.reanimationsfall.enterAnalysephase);
  }

  void _continueCpr() {
    _mutate(widget.reanimationsfall.continueCpr);
  }

  void _recordSchock() {
    _mutate(() {
      widget.reanimationsfall.recordSchock();
      _amiodaronHinweisAusgeblendet = false;
    });
  }

  void _recordAdrenalin() {
    _mutate(widget.reanimationsfall.recordAdrenalin);
  }

  void _recordAmiodaron() {
    _mutate(() {
      widget.reanimationsfall.recordAmiodaron();
      _amiodaronHinweisAusgeblendet = false;
    });
  }

  void _dismissAmiodaronHinweis() {
    setState(() => _amiodaronHinweisAusgeblendet = true);
  }

  void _resumeResuscitation() {
    _mutate(widget.reanimationsfall.resumeResuscitation);
  }

  void _openMesswerte() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MesswertePage(
          snapshot: widget.reanimationsfall.snapshot(),
          routes: widget.routes,
          reanimationsfall: widget.reanimationsfall,
          session: widget.session,
        ),
      ),
    );
  }

  Future<void> _endReanimationsfall() async {
    final choice = await showDialog<ReanimationsfallEndChoice>(
      context: context,
      builder: (_) => const EndReanimationsfallDialog(),
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case EndWithReason(:final grund):
        setState(() => widget.reanimationsfall.endReanimationsfall(grund));
        await widget.session.persist(widget.reanimationsfall);
        if (!mounted) return;

        final snapshot = widget.reanimationsfall.snapshot();
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ReanimationsfallSummaryPage(
              snapshot: snapshot,
              routes: widget.routes,
            ),
          ),
        );
      case DiscardReanimationsfall():
        await _discardReanimationsfall();
    }
  }

  Future<void> _discardReanimationsfall() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.discardCaseTitle),
        content: Text(l10n.discardCaseDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.discardCaseConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(widget.reanimationsfall.discardReanimationsfall);
    await widget.session.persist(widget.reanimationsfall);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _undoLastSchock() {
    if (widget.reanimationsfall.snapshot().schockAnzahl == 0) return;
    _mutate(() {
      widget.reanimationsfall.undoLastSchock();
      _amiodaronHinweisAusgeblendet = false;
    });
  }

  Future<void> _editLastSchockEnergie() async {
    final lastSchock = widget.reanimationsfall.snapshot().letzterAktiverSchock;
    if (lastSchock == null) return;

    final energie = await showDialog<int>(
      context: context,
      builder: (_) =>
          SchockEnergieDialog(initialEnergie: lastSchock.energieJoule),
    );
    if (energie == null || !mounted) return;

    _mutate(() => widget.reanimationsfall.setLastSchockEnergie(energie));
  }

  Future<void> _recordRhythmusanalyse() async {
    final ergebnis = await showDialog<RhythmusanalyseErgebnis>(
      context: context,
      builder: (_) => const RhythmusanalyseDialog(),
    );
    if (ergebnis == null || !mounted) return;

    _mutate(() => widget.reanimationsfall.recordRhythmusanalyse(ergebnis));

    if (ergebnis == RhythmusanalyseErgebnis.unklar) {
      await _editRhythmusanalyseNotiz();
    }
  }

  Future<void> _editRhythmusanalyseNotiz() async {
    final snapshot = widget.reanimationsfall.snapshot();
    final edit = await showDialog<RhythmusanalyseNotizEdit>(
      context: context,
      builder: (_) => RhythmusanalyseNotizDialog(
        initialNotiz: snapshot.rhythmusanalyseNotiz,
      ),
    );
    if (edit == null || !mounted) return;

    _mutate(() => widget.reanimationsfall.setRhythmusanalyseNotiz(edit.notiz));
  }

  Future<void> _skipRhythmusanalyse() async {
    final choice = await showDialog<SkipRhythmusanalyseChoice>(
      context: context,
      builder: (_) => const SkipRhythmusanalyseDialog(),
    );
    if (choice == null || !mounted) return;

    _mutate(() => widget.reanimationsfall.skipRhythmusanalyse(choice.grund));
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.reanimationsfall.snapshot();

    return PageScaffold(
      maxWidth: PageLayout.maxContentWidth,
      drawer: AppDrawer(routes: widget.routes, onOpenMesswerte: _openMesswerte),
      header: (context, layout) => _ReanimationsfallHeader(
        snapshot: snapshot,
        layout: layout,
        onEndCase: _endReanimationsfall,
      ),
      content: (context, layout) {
        final reanimationsdauerPanel = _ReanimationsdauerPanel(
          snapshot: snapshot,
        );
        final timer = _PhaseTimerPanel(snapshot: snapshot, layout: layout);

        final main = layout.isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: PageLayout.elapsedPanelFlex,
                    child: reanimationsdauerPanel,
                  ),
                  SizedBox(width: layout.panelGap),
                  Expanded(flex: PageLayout.timerPanelFlex, child: timer),
                ],
              )
            : Column(
                children: [
                  reanimationsdauerPanel,
                  SizedBox(height: layout.panelGap),
                  Expanded(child: timer),
                ],
              );

        final showAmiodaron =
            snapshot.amiodaronGaben.isNotEmpty ||
            (snapshot.amiodaronHinweis != AmiodaronHinweis.keine &&
                !_amiodaronHinweisAusgeblendet);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: main),
            SizedBox(height: layout.contentGap),
            AdrenalinPanel(
              snapshot: snapshot,
              layout: layout,
              onRecordAdrenalin: _recordAdrenalin,
            ),
            if (showAmiodaron) ...[
              SizedBox(height: layout.contentGap),
              AmiodaronPanel(
                snapshot: snapshot,
                layout: layout,
                isHintVisible: !_amiodaronHinweisAusgeblendet,
                onRecordAmiodaron: _recordAmiodaron,
                onDismiss: _dismissAmiodaronHinweis,
              ),
            ],
          ],
        );
      },
      footer: (context, layout) => snapshot.istRosc
          ? _RoscActionBar(
              layout: layout,
              onResumeResuscitation: _resumeResuscitation,
              onEndCase: _endReanimationsfall,
            )
          : PhaseActionBar(
              snapshot: snapshot,
              layout: layout,
              onEnterAnalysephase: _enterAnalysephase,
              onRecordSchock: _recordSchock,
              onUndoLastSchock: _undoLastSchock,
              onEditSchockEnergie: _editLastSchockEnergie,
              onRecordRhythmusanalyse: _recordRhythmusanalyse,
              onEditRhythmusanalyseNotiz: _editRhythmusanalyseNotiz,
              onSkipRhythmusanalyse: _skipRhythmusanalyse,
              onContinueCpr: _continueCpr,
            ),
    );
  }
}

class _ReanimationsfallHeader extends StatelessWidget {
  const _ReanimationsfallHeader({
    required this.snapshot,
    required this.layout,
    required this.onEndCase,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onEndCase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final phaseLabel = switch (snapshot.zustand) {
      ReanimationsfallZustand.laufend => switch (snapshot.phase) {
        Reanimationsphase.druckphase => l10n.phaseDruckphase,
        Reanimationsphase.analysephase => l10n.phaseAnalysephase,
      },
      ReanimationsfallZustand.rosc => l10n.rhythmusanalyseRosc,
      ReanimationsfallZustand.beendet => l10n.summaryCaseEnded,
      ReanimationsfallZustand.verworfen => l10n.verworfenLabel,
    };

    return Row(
      children: [
        const BackButton(),
        const SizedBox(width: PageLayout.space8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                phaseLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: PageLayout.space12),
        LeitlinienprofilChip(
          leitlinienprofil: snapshot.leitlinienprofil,
          compact: layout.isCompact,
        ),
        const SizedBox(width: PageLayout.space8),
        IconButton(
          onPressed: onEndCase,
          tooltip: l10n.endCaseButton,
          icon: const Icon(Icons.stop_circle_outlined),
          constraints: const BoxConstraints.tightFor(
            width: PageLayout.touchTargetSize,
            height: PageLayout.touchTargetSize,
          ),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: PageLayout.space8),
        const AppMenuButton(),
      ],
    );
  }
}

class _ReanimationsdauerPanel extends StatelessWidget {
  const _ReanimationsdauerPanel({required this.snapshot});

  final ReanimationsfallSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.elapsedTimeLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              formatReanimationsdauer(snapshot.reanimationsdauer),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: PageLayout.space4),
            Text(
              l10n.startzeitValue(formatWallTime(snapshot.startzeit)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseTimerPanel extends StatelessWidget {
  const _PhaseTimerPanel({required this.snapshot, required this.layout});

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    if (snapshot.istRosc) return _RoscPanel(layout: layout);

    return switch (snapshot.phase) {
      Reanimationsphase.druckphase => _DruckphaseTimerPanel(
        snapshot: snapshot,
        layout: layout,
      ),
      Reanimationsphase.analysephase => _AnalysephaseTimerPanel(
        snapshot: snapshot,
        layout: layout,
      ),
    };
  }
}

class _RoscPanel extends StatelessWidget {
  const _RoscPanel({required this.layout});

  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _PhasePanel(
      isAlert: false,
      layout: layout,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.rhythmusanalyseRosc,
              style:
                  (layout.isCompact
                          ? theme.textTheme.headlineMedium
                          : theme.textTheme.displaySmall)
                      ?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
            ),
          ),
          const SizedBox(height: PageLayout.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.roscDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoscActionBar extends StatelessWidget {
  const _RoscActionBar({
    required this.layout,
    required this.onResumeResuscitation,
    required this.onEndCase,
  });

  final PageLayout layout;
  final VoidCallback onResumeResuscitation;
  final VoidCallback onEndCase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resume = PhaseActionButton(
      layout: layout,
      label: l10n.resumeResuscitationButton,
      icon: Icons.replay,
      onPressed: onResumeResuscitation,
    );
    final end = PhaseActionButton(
      layout: layout,
      label: l10n.endCaseButton,
      icon: Icons.stop_circle_outlined,
      onPressed: onEndCase,
      emphasis: PhaseActionEmphasis.outlined,
    );

    if (layout.isCompact) {
      return Row(
        children: [
          Expanded(child: resume),
          SizedBox(width: layout.compactActionGap),
          Expanded(child: end),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: layout.actionWrapSpacing,
      runSpacing: layout.actionWrapRunSpacing,
      children: [end, resume],
    );
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({
    required this.isAlert,
    required this.layout,
    required this.child,
  });

  final bool isAlert;
  final PageLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: layout.phasePanelPadding,
      decoration: BoxDecoration(
        color: isAlert
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(layout.phasePanelRadius),
        border: Border.all(
          color: isAlert
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
          width: isAlert ? layout.alertBorderWidth : layout.panelBorderWidth,
        ),
      ),
      child: child,
    );
  }
}

class _DruckphaseTimerPanel extends StatelessWidget {
  const _DruckphaseTimerPanel({required this.snapshot, required this.layout});

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isPaused = snapshot.isSchockpause;
    final isDue = snapshot.isRhythmusanalyseDue;
    final foreground = isDue
        ? theme.colorScheme.onErrorContainer
        : isPaused
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    final label = isDue
        ? l10n.analysisDue
        : isPaused
        ? l10n.schockRecordedLabel
        : l10n.nextAnalysisLabel;

    return _PhasePanel(
      isAlert: isDue,
      layout: layout,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDue || isPaused) ...[
                  Icon(
                    isDue ? Icons.priority_high_rounded : Icons.bolt_outlined,
                    color: foreground,
                  ),
                  const SizedBox(width: PageLayout.space4),
                ],
                Text(
                  label,
                  style:
                      (layout.isCompact
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.headlineMedium)
                          ?.copyWith(
                            color: foreground,
                            fontWeight: isDue
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PageLayout.space4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isDue
                    ? l10n.overdueTimer(
                        formatElapsed(snapshot.rhythmusanalyseOverdue),
                      )
                    : formatCountdown(snapshot.compressionRemaining),
                style: TextStyle(
                  fontSize: PageLayout.druckphaseTimerFontSize,
                  height: PageLayout.timerLineHeight,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: foreground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysephaseTimerPanel extends StatelessWidget {
  const _AnalysephaseTimerPanel({required this.snapshot, required this.layout});

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isOverdue = snapshot.isPauseOverdue;
    final foreground = isOverdue
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;

    return _PhasePanel(
      isAlert: isOverdue,
      layout: layout,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.pauseLabel,
            style:
                (layout.isCompact
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.titleMedium)
                    ?.copyWith(
                      color: isOverdue
                          ? foreground
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
          ),
          const SizedBox(height: PageLayout.space4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatElapsed(snapshot.pauseDuration),
                style: TextStyle(
                  fontSize: PageLayout.analysephaseTimerFontSize,
                  height: PageLayout.timerLineHeight,
                  fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isOverdue
                      ? foreground
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isOverdue) ...[
            const SizedBox(height: PageLayout.space8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: foreground),
                  const SizedBox(width: PageLayout.space6),
                  Text(
                    _pauseOverdueHint(l10n, snapshot.leitlinienprofil),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _pauseOverdueHint(AppLocalizations l10n, Leitlinienprofil profil) {
  final seconds = profil.pauseTarget.inSeconds;
  return switch (profil) {
    Leitlinienprofil.erc2025 => l10n.pauseOverdueErc(seconds),
    Leitlinienprofil.aha2025 => l10n.pauseOverdueAha(seconds),
  };
}
