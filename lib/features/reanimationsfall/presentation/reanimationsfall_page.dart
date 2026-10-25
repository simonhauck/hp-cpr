import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/rhythmusanalyse.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_format.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_notiz_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/skip_rhythmusanalyse_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, viewport) {
                final isLandscape = viewport.maxWidth > viewport.maxHeight;
                final isCompact = viewport.maxHeight < 400;

                final reanimationsdauerPanel = _ReanimationsdauerPanel(
                  snapshot: snapshot,
                );
                final timer = _PhaseTimerPanel(snapshot: snapshot);

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    isCompact ? 4 : 8,
                    16,
                    isCompact ? 8 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReanimationsfallHeader(
                        snapshot: snapshot,
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Expanded(
                        child: isLandscape
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: reanimationsdauerPanel,
                                  ),
                                  SizedBox(width: isCompact ? 12 : 16),
                                  Expanded(flex: 6, child: timer),
                                ],
                              )
                            : Column(
                                children: [
                                  reanimationsdauerPanel,
                                  const SizedBox(height: 16),
                                  Expanded(child: timer),
                                ],
                              ),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      _ActionBar(
                        snapshot: snapshot,
                        compact: isCompact,
                        onEnterAnalysephase: _enterAnalysephase,
                        onRecordRhythmusanalyse: _recordRhythmusanalyse,
                        onEditRhythmusanalyseNotiz: _editRhythmusanalyseNotiz,
                        onSkipRhythmusanalyse: _skipRhythmusanalyse,
                        onContinueCpr: _continueCpr,
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
}

class _ReanimationsfallHeader extends StatelessWidget {
  const _ReanimationsfallHeader({
    required this.snapshot,
    required this.compact,
  });

  final ReanimationsfallSnapshot snapshot;
  final bool compact;

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
          compact: compact,
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
  const _PhaseTimerPanel({required this.snapshot});

  final ReanimationsfallSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return switch (snapshot.phase) {
      Reanimationsphase.druckphase => _DruckphaseTimerPanel(snapshot: snapshot),
      Reanimationsphase.analysephase => _AnalysephaseTimerPanel(
        snapshot: snapshot,
      ),
    };
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({required this.isAlert, required this.child});

  final bool isAlert;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
  const _DruckphaseTimerPanel({required this.snapshot});

  final ReanimationsfallSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDue = snapshot.isRhythmusanalyseDue;
    final foreground = isDue
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;

    return _PhasePanel(
      isAlert: isDue,
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
                  const SizedBox(width: 4),
                ],
                Text(
                  isDue ? l10n.analysisDue : l10n.nextAnalysisLabel,
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
  const _AnalysephaseTimerPanel({required this.snapshot});

  final ReanimationsfallSnapshot snapshot;

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

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.snapshot,
    required this.compact,
    required this.onEnterAnalysephase,
    required this.onRecordRhythmusanalyse,
    required this.onEditRhythmusanalyseNotiz,
    required this.onSkipRhythmusanalyse,
    required this.onContinueCpr,
  });

  final ReanimationsfallSnapshot snapshot;
  final bool compact;
  final VoidCallback onEnterAnalysephase;
  final VoidCallback onRecordRhythmusanalyse;
  final VoidCallback onEditRhythmusanalyseNotiz;
  final VoidCallback onSkipRhythmusanalyse;
  final VoidCallback onContinueCpr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isAnalysephase = snapshot.phase == Reanimationsphase.analysephase;
    final ergebnis = snapshot.rhythmusanalyseErgebnis;

    final buttons = <Widget>[];
    if (!isAnalysephase) {
      buttons.add(
        _filledButton(
          context,
          label: l10n.analyseButton,
          icon: Icons.monitor_heart_outlined,
          onPressed: onEnterAnalysephase,
        ),
      );
    } else if (ergebnis == null) {
      buttons.add(
        _filledButton(
          context,
          label: l10n.rhythmusanalyseRecordButton,
          icon: Icons.fact_check_outlined,
          onPressed: onRecordRhythmusanalyse,
        ),
      );
      buttons.add(
        _outlinedButton(
          context,
          label: l10n.skipAnalysisButton,
          icon: Icons.skip_next_outlined,
          onPressed: onSkipRhythmusanalyse,
        ),
      );
      buttons.add(
        Tooltip(
          message: l10n.rhythmusanalyseRequired,
          child: _filledButton(
            context,
            label: l10n.cprContinueButton,
            icon: Icons.lock_outline,
            onPressed: null,
          ),
        ),
      );
    } else {
      buttons.add(
        _filledButton(
          context,
          label: l10n.cprContinueButton,
          icon: Icons.play_arrow,
          onPressed: onContinueCpr,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAnalysephase && ergebnis != null) ...[
          _RhythmusanalyseResultSummary(
            ergebnis: ergebnis,
            notiz: snapshot.rhythmusanalyseNotiz,
            compact: compact,
            onEditNotiz: onEditRhythmusanalyseNotiz,
          ),
          SizedBox(height: compact ? 6 : 10),
        ] else if (isAnalysephase) ...[
          Text(
            l10n.rhythmusanalyseRequired,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
        ],
        if (compact)
          Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: buttons[i]),
              ],
            ],
          )
        else
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: buttons,
          ),
      ],
    );
  }

  Widget _filledButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final style = _buttonStyle(context);
    if (compact) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: style,
    );
  }

  Widget _outlinedButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final style = _buttonStyle(context);
    if (compact) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: style,
    );
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.styleFrom(
      minimumSize: Size(compact ? 0 : 180, compact ? 48 : 54),
      padding: compact ? const EdgeInsets.symmetric(horizontal: 14) : null,
      textStyle: compact
          ? theme.textTheme.labelLarge
          : theme.textTheme.titleMedium,
    );
  }
}

class _RhythmusanalyseResultSummary extends StatelessWidget {
  const _RhythmusanalyseResultSummary({
    required this.ergebnis,
    required this.notiz,
    required this.compact,
    required this.onEditNotiz,
  });

  final RhythmusanalyseErgebnis ergebnis;
  final String? notiz;
  final bool compact;
  final VoidCallback onEditNotiz;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notizText = notiz;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.rhythmusanalyseRecordedLabel}: '
                  '${rhythmusanalyseErgebnisLabel(l10n, ergebnis)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (notizText != null)
                  Text(
                    notizText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onEditNotiz,
            icon: Icon(
              notiz == null ? Icons.note_add_outlined : Icons.edit_note,
            ),
            label: Text(
              notiz == null
                  ? l10n.rhythmusanalyseNoteAdd
                  : l10n.rhythmusanalyseNoteEdit,
            ),
          ),
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
