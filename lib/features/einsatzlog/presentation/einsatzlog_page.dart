import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/domain/leitlinienprofil.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/reanimationsfall_summary_page.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
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
    final snapshot = widget.session.snapshotFor(state);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReanimationsfallSummaryPage(
          snapshot: snapshot,
          routes: widget.routes,
        ),
      ),
    );
  }

  Future<void> _delete(ReanimationsfallState state) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCaseTitle),
        content: Text(l10n.deleteCaseDescription),
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
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    PageLayout.space20,
                    PageLayout.space16,
                    PageLayout.space20,
                    PageLayout.space24,
                  ),
                  itemCount: states.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: PageLayout.dividerHeight),
                  itemBuilder: (context, index) {
                    return _EinsatzlogTile(
                      state: states[index],
                      session: widget.session,
                      onOpen: () => _openDetail(states[index]),
                      onDelete: () => _delete(states[index]),
                    );
                  },
                );
              },
            ),
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

    return ListTile(
      leading: Icon(
        isVerworfen ? Icons.block : Icons.check_circle_outline,
        color: isVerworfen
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
      ),
      title: Text(l10n.einsatzlogEntryTitle(formatWallTime(state.startzeit))),
      subtitle: Text(
        isVerworfen ? '$subtitle · ${l10n.verworfenLabel}' : subtitle,
      ),
      trailing: IconButton(
        onPressed: onDelete,
        tooltip: l10n.deleteCaseTooltip,
        icon: const Icon(Icons.delete_outline),
      ),
      onTap: onOpen,
    );
  }
}
