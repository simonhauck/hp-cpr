import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwerte_page.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/amiodaron.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/actions_sheet.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/adrenalin_panel.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/amiodaron_panel.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/end_reanimationsfall_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/phase_action_bar.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/phase_strip.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_summary_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/demo_modus_chip.dart';
import 'package:hp_cpr/ui/dialogs/notiz_erfassen_dialog.dart';
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
  AmiodaronHinweis? _ausgeblendeterAmiodaronHinweis;

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

  void _recordSchock() {
    _mutate(() {
      widget.reanimationsfall.recordSchock();
      _ausgeblendeterAmiodaronHinweis = null;
    });
  }

  void _recordAdrenalin() {
    _mutate(widget.reanimationsfall.recordAdrenalin);
  }

  void _recordAmiodaron() {
    _mutate(() {
      widget.reanimationsfall.recordAmiodaron();
      _ausgeblendeterAmiodaronHinweis = null;
    });
  }

  void _dismissAmiodaronHinweis() {
    setState(() {
      _ausgeblendeterAmiodaronHinweis = widget.reanimationsfall
          .snapshot()
          .amiodaronHinweis;
    });
  }

  void _resumeResuscitation() {
    _mutate(widget.reanimationsfall.resumeResuscitation);
  }

  Future<void> _openActions() async {
    final snapshot = widget.reanimationsfall.snapshot();
    await showActionsSheet(
      context,
      onOpenMesswerte: _openMesswerte,
      onOpenProtokoll: _openProtokoll,
      onRecordNotiz: _recordNotiz,
      onEndCase: _endReanimationsfall,
      onRecordSchock: snapshot.istLaufend ? _recordSchock : null,
      onRestartDruckphase: snapshot.kannDruckphaseNeuStarten
          ? _restartDruckphase
          : null,
    );
  }

  void _restartDruckphase() {
    _mutate(widget.reanimationsfall.restartDruckphase);
  }

  void _advanceDemoTime() {
    _mutate(
      () =>
          widget.reanimationsfall.advanceDemoTime(const Duration(seconds: 30)),
    );
  }

  Future<void> _recordNotiz() async {
    final text = await showNotizErfassenDialog(context);
    if (text == null || !mounted) return;

    _mutate(() => widget.reanimationsfall.recordNotiz(text));
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

  Future<void> _openProtokoll() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProtokollPage(
          reanimationsfall: widget.reanimationsfall,
          session: widget.session,
          routes: widget.routes,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
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

        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ReanimationsfallSummaryPage(
              reanimationsfall: widget.reanimationsfall,
              session: widget.session,
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

  Future<void> _recordRhythmusanalyse(
    RhythmusanalyseKategorie kategorie,
  ) async {
    final abschluss = await showDialog<RhythmusanalyseAbschluss>(
      context: context,
      builder: (_) => RhythmusanalyseDialog(initialKategorie: kategorie),
    );
    if (abschluss == null || !mounted) return;

    _mutate(() {
      widget.reanimationsfall.completeRhythmusanalyse(
        abschluss.ergebnis,
        schockAbgegeben: abschluss.schockAbgegeben,
      );
      if (abschluss.schockAbgegeben) {
        _ausgeblendeterAmiodaronHinweis = null;
      }
    });
  }

  Future<void> _recordRosc() async {
    final confirmed = await showRoscConfirmDialog(context);
    if (confirmed != true || !mounted) return;

    _mutate(
      () => widget.reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.rosc,
      ),
    );
  }

  void _recordUnklar() {
    _mutate(
      () => widget.reanimationsfall.completeRhythmusanalyse(
        RhythmusanalyseErgebnis.unklar,
      ),
    );
  }

  void _skipRhythmusanalyse() {
    _mutate(widget.reanimationsfall.skipRhythmusanalyse);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).rhythmusanalyseSkippedSnackbar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.reanimationsfall.snapshot();

    return PageScaffold(
      maxWidth: PageLayout.maxContentWidth,
      drawer: AppDrawer(routes: widget.routes),
      header: (context, layout) => _ReanimationsfallHeader(
        snapshot: snapshot,
        layout: layout,
        onEndCase: _endReanimationsfall,
      ),
      content: (context, layout) {
        final reanimationsdauerPanel = _ReanimationsdauerPanel(
          snapshot: snapshot,
          layout: layout,
        );
        final timer = _PhaseTimerPanel(
          snapshot: snapshot,
          layout: layout,
          onEnterAnalysephase: _enterAnalysephase,
          onRecordRhythmusanalyse: _recordRhythmusanalyse,
          onRecordRosc: _recordRosc,
          onRecordUnklar: _recordUnklar,
          onSkipRhythmusanalyse: _skipRhythmusanalyse,
        );

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

        final istAmiodaronHinweisAusgeblendet =
            snapshot.amiodaronHinweis == _ausgeblendeterAmiodaronHinweis;
        final showAmiodaron =
            snapshot.amiodaronGaben.isNotEmpty ||
            (snapshot.amiodaronHinweis != AmiodaronHinweis.keine &&
                !istAmiodaronHinweisAusgeblendet);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: main),
            SizedBox(height: layout.contentGap),
            AdrenalinPanel(
              snapshot: snapshot,
              layout: layout,
              onRecordAdrenalin: _recordAdrenalin,
              isRecordingEnabled: snapshot.istLaufend,
            ),
            if (showAmiodaron) ...[
              SizedBox(height: layout.contentGap),
              AmiodaronPanel(
                snapshot: snapshot,
                layout: layout,
                isHintVisible: !istAmiodaronHinweisAusgeblendet,
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
              onOpenActions: _openActions,
              onAdvanceDemoTime: snapshot.demoMode ? _advanceDemoTime : null,
            )
          : PhaseActionBar(
              layout: layout,
              onOpenActions: _openActions,
              onSkipRhythmusanalyse:
                  layout.isCompact &&
                      snapshot.phase == Reanimationsphase.analysephase
                  ? _skipRhythmusanalyse
                  : null,
              onAdvanceDemoTime: snapshot.demoMode ? _advanceDemoTime : null,
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
  const _ReanimationsdauerPanel({required this.snapshot, required this.layout});

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

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
            if (snapshot.demoMode) ...[
              const SizedBox(height: PageLayout.space4),
              DemoModusChip(compact: layout.isCompact),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhaseTimerPanel extends StatelessWidget {
  const _PhaseTimerPanel({
    required this.snapshot,
    required this.layout,
    required this.onEnterAnalysephase,
    required this.onRecordRhythmusanalyse,
    required this.onRecordRosc,
    required this.onRecordUnklar,
    required this.onSkipRhythmusanalyse,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onEnterAnalysephase;
  final ValueChanged<RhythmusanalyseKategorie> onRecordRhythmusanalyse;
  final VoidCallback onRecordRosc;
  final VoidCallback onRecordUnklar;
  final VoidCallback onSkipRhythmusanalyse;

  @override
  Widget build(BuildContext context) {
    if (snapshot.istRosc) {
      return _RoscPanel(snapshot: snapshot, layout: layout);
    }

    return switch (snapshot.phase) {
      Reanimationsphase.druckphase => _DruckphaseTimerPanel(
        snapshot: snapshot,
        layout: layout,
        onEnterAnalysephase: onEnterAnalysephase,
      ),
      Reanimationsphase.analysephase => _AnalysephaseTimerPanel(
        snapshot: snapshot,
        layout: layout,
        onRecordRhythmusanalyse: onRecordRhythmusanalyse,
        onRecordRosc: onRecordRosc,
        onRecordUnklar: onRecordUnklar,
        onSkipRhythmusanalyse: onSkipRhythmusanalyse,
      ),
    };
  }
}

class _RoscPanel extends StatelessWidget {
  const _RoscPanel({required this.snapshot, required this.layout});

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _PhasePanel(
      isAlert: false,
      layout: layout,
      snapshot: snapshot,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: PageLayout.iconLarge,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: PageLayout.space8),
                Text(
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
              ],
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
    required this.onOpenActions,
    this.onAdvanceDemoTime,
  });

  final PageLayout layout;
  final VoidCallback onResumeResuscitation;
  final VoidCallback onEndCase;
  final VoidCallback onOpenActions;
  final VoidCallback? onAdvanceDemoTime;

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
    final advanceDemoTime = onAdvanceDemoTime;

    return PhaseActionRow(
      layout: layout,
      buttons: [
        resume,
        end,
        if (advanceDemoTime != null)
          DemoAdvanceButton(layout: layout, onPressed: advanceDemoTime),
      ],
      actionsButton: ActionsButton(layout: layout, onPressed: onOpenActions),
    );
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({
    required this.isAlert,
    required this.snapshot,
    required this.layout,
    required this.child,
  });

  final bool isAlert;
  final ReanimationsfallSnapshot snapshot;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhaseStrip(snapshot: snapshot, layout: layout),
          SizedBox(height: layout.phaseStripGap),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DruckphaseTimerPanel extends StatelessWidget {
  const _DruckphaseTimerPanel({
    required this.snapshot,
    required this.layout,
    required this.onEnterAnalysephase,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final VoidCallback onEnterAnalysephase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDue = snapshot.isRhythmusanalyseDue;
    final foreground = isDue
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;
    final label = isDue ? l10n.analysisDue : l10n.nextAnalysisLabel;
    final timerText = isDue
        ? l10n.overdueTimer(formatElapsed(snapshot.rhythmusanalyseOverdue))
        : formatCountdown(snapshot.compressionRemaining);
    final action = PhaseActionButton(
      layout: layout,
      label: l10n.analyseButton,
      icon: Icons.monitor_heart_outlined,
      onPressed: onEnterAnalysephase,
      emphasis: isDue
          ? PhaseActionEmphasis.filled
          : PhaseActionEmphasis.outlined,
    );

    if (layout.isCompact) {
      return _PhasePanel(
        isAlert: isDue,
        layout: layout,
        snapshot: snapshot,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDue) ...[
                          Icon(Icons.priority_high_rounded, color: foreground),
                          const SizedBox(width: PageLayout.space4),
                        ],
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: isDue
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PageLayout.space2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        timerText,
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
            ),
            SizedBox(width: layout.sectionGap),
            Expanded(flex: 4, child: action),
          ],
        ),
      );
    }

    return _PhasePanel(
      isAlert: isDue,
      layout: layout,
      snapshot: snapshot,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDue) ...[
                  Icon(Icons.priority_high_rounded, color: foreground),
                  const SizedBox(width: PageLayout.space4),
                ],
                Text(
                  label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: foreground,
                    fontWeight: isDue ? FontWeight.w800 : FontWeight.w500,
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
                timerText,
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
          SizedBox(height: layout.sectionGap),
          action,
        ],
      ),
    );
  }
}

class _AnalysephaseTimerPanel extends StatelessWidget {
  const _AnalysephaseTimerPanel({
    required this.snapshot,
    required this.layout,
    required this.onRecordRhythmusanalyse,
    required this.onRecordRosc,
    required this.onRecordUnklar,
    required this.onSkipRhythmusanalyse,
  });

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;
  final ValueChanged<RhythmusanalyseKategorie> onRecordRhythmusanalyse;
  final VoidCallback onRecordRosc;
  final VoidCallback onRecordUnklar;
  final VoidCallback onSkipRhythmusanalyse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isOverdue = snapshot.isPauseOverdue;
    final foreground = isOverdue
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;
    final choices = <Widget>[
      _RhythmusanalyseChoiceButton(
        layout: layout,
        icon: Icons.bolt,
        label: l10n.rhythmusanalyseSchockbar,
        onPressed: () =>
            onRecordRhythmusanalyse(RhythmusanalyseKategorie.schockbar),
      ),
      _RhythmusanalyseChoiceButton(
        layout: layout,
        icon: Icons.flash_off,
        label: l10n.rhythmusanalyseNichtSchockbar,
        onPressed: () =>
            onRecordRhythmusanalyse(RhythmusanalyseKategorie.nichtSchockbar),
      ),
      _RhythmusanalyseChoiceButton(
        layout: layout,
        icon: Icons.monitor_heart_outlined,
        label: l10n.rhythmusanalyseRosc,
        onPressed: onRecordRosc,
        emphasis: PhaseActionEmphasis.outlined,
      ),
      _RhythmusanalyseChoiceButton(
        layout: layout,
        icon: Icons.question_mark,
        label: l10n.rhythmusanalyseUnklar,
        onPressed: onRecordUnklar,
        emphasis: PhaseActionEmphasis.outlined,
      ),
    ];

    return _PhasePanel(
      isAlert: isOverdue,
      layout: layout,
      snapshot: snapshot,
      child: layout.isCompact
          ? _buildCompactContent(
              l10n: l10n,
              theme: theme,
              isOverdue: isOverdue,
              foreground: foreground,
              choices: choices,
            )
          : _buildRegularContent(
              l10n: l10n,
              theme: theme,
              isOverdue: isOverdue,
              foreground: foreground,
              choices: choices,
            ),
    );
  }

  Widget _buildRegularContent({
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool isOverdue,
    required Color foreground,
    required List<Widget> choices,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.pauseLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isOverdue ? foreground : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PageLayout.space4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _timerText(theme, isOverdue, foreground),
          ),
        ),
        if (isOverdue) ...[
          const SizedBox(height: PageLayout.space8),
          _overdueHint(l10n, theme, foreground),
        ],
        const SizedBox(height: PageLayout.space8),
        _choiceGrid(choices),
        const SizedBox(height: PageLayout.space4),
        TextButton(
          onPressed: onSkipRhythmusanalyse,
          child: Text(l10n.skipAnalysisButton),
        ),
      ],
    );
  }

  Widget _choiceGrid(List<Widget> choices) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: choices[0]),
            SizedBox(width: layout.actionWrapSpacing),
            Expanded(child: choices[1]),
          ],
        ),
        SizedBox(height: layout.actionWrapRunSpacing),
        Row(
          children: [
            Expanded(child: choices[2]),
            SizedBox(width: layout.actionWrapSpacing),
            Expanded(child: choices[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactContent({
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool isOverdue,
    required Color foreground,
    required List<Widget> choices,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOverdue)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _pauseOverdueHint(l10n, snapshot.leitlinienprofil),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  l10n.pauseLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(width: PageLayout.space8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _timerText(theme, isOverdue, foreground),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PageLayout.space4),
        Row(
          children: [
            for (var i = 0; i < choices.length; i++) ...[
              if (i > 0) SizedBox(width: layout.rhythmusanalyseChoiceSpacing),
              Expanded(child: choices[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _timerText(ThemeData theme, bool isOverdue, Color foreground) {
    return Text(
      formatElapsed(snapshot.pauseDuration),
      style: TextStyle(
        fontSize: PageLayout.analysephaseTimerFontSize,
        height: PageLayout.timerLineHeight,
        fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: isOverdue ? foreground : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _overdueHint(
    AppLocalizations l10n,
    ThemeData theme,
    Color foreground,
  ) {
    return FittedBox(
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
    );
  }
}

class _RhythmusanalyseChoiceButton extends StatelessWidget {
  const _RhythmusanalyseChoiceButton({
    required this.layout,
    required this.label,
    required this.onPressed,
    this.icon,
    this.emphasis = PhaseActionEmphasis.filled,
  });

  final PageLayout layout;
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final PhaseActionEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minimumSize = Size(PageLayout.space0, layout.actionHeight);
    final padding = layout.rhythmusanalyseChoicePadding;
    final textStyle = layout.isCompact
        ? theme.textTheme.labelMedium
        : theme.textTheme.titleSmall;

    return switch (emphasis) {
      PhaseActionEmphasis.filled => FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          padding: padding,
          textStyle: textStyle,
        ),
        child: _content(),
      ),
      PhaseActionEmphasis.outlined => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: minimumSize,
          padding: padding,
          textStyle: textStyle,
        ),
        child: _content(),
      ),
    };
  }

  Widget _content() {
    final icon = this.icon;
    if (icon == null || layout.isCompact) {
      return FittedBox(fit: BoxFit.scaleDown, child: Text(label));
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: PageLayout.iconSmall),
          const SizedBox(width: PageLayout.space8),
          Text(label),
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
