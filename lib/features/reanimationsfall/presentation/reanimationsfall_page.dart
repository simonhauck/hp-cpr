import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/phase_action_bar.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_notiz_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/schock_energie_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/skip_rhythmusanalyse_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/layout/page_scaffold.dart';

/// The running Reanimationsfall in its current Reanimationsphase.
class ReanimationsfallPage extends StatefulWidget {
  const ReanimationsfallPage({
    super.key,
    required this.reanimationsfall,
    required this.wakeLock,
  });

  final Reanimationsfall reanimationsfall;
  final WakeLock wakeLock;

  @override
  State<ReanimationsfallPage> createState() => _ReanimationsfallPageState();
}

class _ReanimationsfallPageState extends State<ReanimationsfallPage>
    with WidgetsBindingObserver {
  Timer? _ticker;

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

  void _enterAnalysephase() {
    setState(widget.reanimationsfall.enterAnalysephase);
  }

  void _continueCpr() {
    setState(widget.reanimationsfall.continueCpr);
  }

  void _recordSchock() {
    setState(widget.reanimationsfall.recordSchock);
  }

  void _undoLastSchock() {
    if (widget.reanimationsfall.snapshot().schockAnzahl == 0) return;
    setState(widget.reanimationsfall.undoLastSchock);
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

    setState(() => widget.reanimationsfall.setLastSchockEnergie(energie));
  }

  Future<void> _recordRhythmusanalyse() async {
    final ergebnis = await showDialog<RhythmusanalyseErgebnis>(
      context: context,
      builder: (_) => const RhythmusanalyseDialog(),
    );
    if (ergebnis == null || !mounted) return;

    setState(() {
      widget.reanimationsfall.recordRhythmusanalyse(ergebnis);
    });

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

    setState(() {
      widget.reanimationsfall.setRhythmusanalyseNotiz(edit.notiz);
    });
  }

  Future<void> _skipRhythmusanalyse() async {
    final choice = await showDialog<SkipRhythmusanalyseChoice>(
      context: context,
      builder: (_) => const SkipRhythmusanalyseDialog(),
    );
    if (choice == null || !mounted) return;

    setState(() {
      widget.reanimationsfall.skipRhythmusanalyse(choice.grund);
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.reanimationsfall.snapshot();

    return PageScaffold(
      maxWidth: 1200,
      header: (context, layout) =>
          _ReanimationsfallHeader(snapshot: snapshot, layout: layout),
      content: (context, layout) {
        final reanimationsdauerPanel = _ReanimationsdauerPanel(
          snapshot: snapshot,
        );
        final timer = _PhaseTimerPanel(snapshot: snapshot, layout: layout);

        return layout.isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: reanimationsdauerPanel),
                  SizedBox(width: layout.panelGap),
                  Expanded(flex: 6, child: timer),
                ],
              )
            : Column(
                children: [
                  reanimationsdauerPanel,
                  const SizedBox(height: 16),
                  Expanded(child: timer),
                ],
              );
      },
      footer: (context, layout) => PhaseActionBar(
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
  const _ReanimationsfallHeader({required this.snapshot, required this.layout});

  final ReanimationsfallSnapshot snapshot;
  final PageLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final phaseLabel = switch (snapshot.phase) {
      Reanimationsphase.druckphase => l10n.phaseDruckphase,
      Reanimationsphase.analysephase => l10n.phaseAnalysephase,
    };

    return Row(
      children: [
        const BackButton(),
        const SizedBox(width: 8),
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
        const SizedBox(width: 12),
        LeitlinienprofilChip(
          leitlinienprofil: snapshot.leitlinienprofil,
          compact: layout.isCompact,
        ),
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
            const SizedBox(height: 4),
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

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({
    required this.isAlert,
    required this.padding,
    required this.child,
  });

  final bool isAlert;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isAlert
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isAlert
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
          width: isAlert ? 3 : 1,
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
      padding: EdgeInsets.all(layout.isCompact ? 12 : 20),
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
                  const SizedBox(width: 4),
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
          const SizedBox(height: 4),
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
                  fontSize: 150,
                  height: 1,
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
      padding: EdgeInsets.all(layout.isCompact ? 12 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.pauseLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isOverdue
                  ? foreground
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatElapsed(snapshot.pauseDuration),
                style: TextStyle(
                  fontSize: 84,
                  height: 1,
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
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: foreground),
                  const SizedBox(width: 6),
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
