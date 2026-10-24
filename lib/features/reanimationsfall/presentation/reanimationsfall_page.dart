import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// The running Reanimationsfall in its Druckphase.
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
                final timer = _CompressionTimerPanel(snapshot: snapshot);

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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.elapsedTimeLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatReanimationsdauer(snapshot.reanimationsdauer),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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
    );
  }
}

class _CompressionTimerPanel extends StatelessWidget {
  const _CompressionTimerPanel({required this.snapshot});

  final ReanimationsfallSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDue = snapshot.isRhythmusanalyseDue;
    final foreground = isDue
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDue
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDue
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
          width: isDue ? 3 : 1,
        ),
      ),
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
