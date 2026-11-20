import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_summary_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/dialogs/destructive_confirm_dialog.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The persistent list of completed and Verworfene Reanimationsfälle.
class EinsatzlogPage extends StatefulWidget {
  const EinsatzlogPage({
    super.key,
    required this.session,
    required this.routes,
  });

  final ReanimationsfallSession session;
  final AppRoutes routes;

  @override
  State<EinsatzlogPage> createState() => _EinsatzlogPageState();
}

class _EinsatzlogPageState extends State<EinsatzlogPage> {
  late Future<List<ReanimationsfallState>> _logFuture = widget.session
      .loadLog();

  void _reload() {
    setState(() {
      _logFuture = widget.session.loadLog();
    });
  }

  Future<void> _openDetail(ReanimationsfallState state) async {
    final reanimationsfall = widget.session.restore(state);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReanimationsfallSummaryPage(
          reanimationsfall: reanimationsfall,
          session: widget.session,
          routes: widget.routes,
        ),
      ),
    );
    if (!mounted) return;
    _reload();
  }

  Future<void> _delete(ReanimationsfallState state) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDestructiveConfirmDialog(
      context,
      title: l10n.deleteCaseTitle,
      description: l10n.deleteCaseDescription,
      confirmLabel: l10n.deleteButton,
    );
    if (!confirmed || !mounted) return;

    await widget.session.delete(state.id);
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n.einsatzlogTitle),
        actions: const [
          AppMenuButton(),
          SizedBox(width: PageLayout.space8),
        ],
      ),
      drawer: AppDrawer(
        routes: widget.routes,
        currentDestination: AppDestination.einsatzlog,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PageLayout.settingsContentWidth,
            ),
            child: FutureBuilder<List<ReanimationsfallState>>(
              future: _logFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final states = snapshot.data ?? const [];
                if (states.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(PageLayout.space24),
                      child: Text(
                        l10n.einsatzlogEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                final today = _dayOf(widget.session.clock.now());
                final yesterday = DateTime(
                  today.year,
                  today.month,
                  today.day - 1,
                );
                final rows = <Widget>[];
                DateTime? currentDay;
                for (final state in states) {
                  final day = _dayOf(state.startzeit);
                  if (day != currentDay) {
                    currentDay = day;
                    if (rows.isNotEmpty) {
                      rows.add(const SizedBox(height: PageLayout.space16));
                    }
                    rows.add(
                      _EinsatzlogDayHeader(
                        label: _dayLabel(l10n, day, today, yesterday),
                      ),
                    );
                  } else {
                    rows.add(const Divider(height: PageLayout.dividerHeight));
                  }
                  rows.add(
                    _EinsatzlogTile(
                      state: state,
                      session: widget.session,
                      onOpen: () => _openDetail(state),
                      onDelete: () => _delete(state),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    PageLayout.space20,
                    PageLayout.space16,
                    PageLayout.space20,
                    PageLayout.space24,
                  ),
                  children: rows,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The local calendar day of [time], without a time of day.
DateTime _dayOf(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// "Heute", "Gestern", or the date for any other day.
String _dayLabel(
  AppLocalizations l10n,
  DateTime day,
  DateTime today,
  DateTime yesterday,
) {
  if (day == today) return l10n.einsatzlogToday;
  if (day == yesterday) return l10n.einsatzlogYesterday;
  return formatWallDate(day);
}

class _EinsatzlogDayHeader extends StatelessWidget {
  const _EinsatzlogDayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: PageLayout.space8),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _EinsatzlogTile extends StatelessWidget {
  const _EinsatzlogTile({
    required this.state,
    required this.session,
    required this.onOpen,
    required this.onDelete,
  });

  final ReanimationsfallState state;
  final ReanimationsfallSession session;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = session.snapshotFor(state);
    final isVerworfen = state.zustand == ReanimationsfallZustand.verworfen;
    final profil = switch (state.leitlinienprofil) {
      Leitlinienprofil.erc2025 => l10n.guidelineErc2025,
      Leitlinienprofil.aha2025 => l10n.guidelineAha2025,
    };
    final subtitle = l10n.einsatzlogEntrySubtitle(
      formatReanimationsdauer(summary.cprDauer),
      profil,
    );
    final markers = [
      if (state.demoMode) l10n.demoModusLabel,
      if (isVerworfen) l10n.verworfenLabel,
    ];
    final subtitleWithMarkers = markers.isEmpty
        ? subtitle
        : '$subtitle · ${markers.join(' · ')}';

    return ListTile(
      leading: Icon(
        isVerworfen ? Icons.block : Icons.check_circle_outline,
        color: isVerworfen
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
      ),
      title: Text(
        l10n.einsatzlogEntryTitle(formatWallDateTime(state.startzeit)),
      ),
      subtitle: Text(subtitleWithMarkers),
      trailing: IconButton(
        onPressed: onDelete,
        tooltip: l10n.deleteCaseTooltip,
        icon: const Icon(Icons.delete_outline),
      ),
      onTap: onOpen,
    );
  }
}
