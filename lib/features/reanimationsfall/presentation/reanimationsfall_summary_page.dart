import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwert_tile.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwerte_page.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/end_reanimationsfall_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_corrections_mixin.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_liste.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/demo_modus_chip.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The in-app summary and completed Protokoll of a Reanimationsfall.
class ReanimationsfallSummaryPage extends StatefulWidget {
  const ReanimationsfallSummaryPage({
    super.key,
    required this.reanimationsfall,
    required this.session,
    required this.routes,
  });

  final Reanimationsfall reanimationsfall;
  final ReanimationsfallSession session;
  final AppRoutes routes;

  @override
  State<ReanimationsfallSummaryPage> createState() =>
      _ReanimationsfallSummaryPageState();
}

class _ReanimationsfallSummaryPageState
    extends State<ReanimationsfallSummaryPage>
    with ProtokollCorrectionsMixin<ReanimationsfallSummaryPage> {
  @override
  Reanimationsfall get protokollFall => widget.reanimationsfall;

  @override
  ReanimationsfallSession get protokollSession => widget.session;

  void _openMesswerte() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MesswertePage(
          snapshot: widget.reanimationsfall.snapshot(),
          routes: widget.routes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final snapshot = widget.reanimationsfall.snapshot();
    final ende = snapshot.ende;
    final endZeitpunkt = ende?.zeitpunkt ?? snapshot.verworfenAm;
    final notizen = [...snapshot.notizen]
      ..sort((a, b) => a.zeitpunkt.compareTo(b.zeitpunkt));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n.summaryTitle),
        actions: const [
          AppMenuButton(),
          SizedBox(width: PageLayout.space8),
        ],
      ),
      drawer: AppDrawer(routes: widget.routes),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PageLayout.settingsContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                PageLayout.space20,
                PageLayout.space16,
                PageLayout.space20,
                PageLayout.space24,
              ),
              children: [
                Text(
                  snapshot.istVerworfen
                      ? l10n.summaryCaseDiscarded
                      : l10n.summaryCaseEnded,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PageLayout.space16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(PageLayout.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: PageLayout.space8,
                          runSpacing: PageLayout.space8,
                          children: [
                            LeitlinienprofilChip(
                              leitlinienprofil: snapshot.leitlinienprofil,
                            ),
                            if (snapshot.demoMode) const DemoModusChip(),
                          ],
                        ),
                        const SizedBox(height: PageLayout.space12),
                        _SummaryRow(
                          label: l10n.summaryCprDuration,
                          value: formatReanimationsdauer(snapshot.cprDauer),
                        ),
                        _SummaryRow(
                          label: l10n.summaryShocks,
                          value: '${snapshot.schockAnzahl}',
                        ),
                        _SummaryRow(
                          label: l10n.adrenalinLabel,
                          value: '${snapshot.adrenalinGaben.length}',
                        ),
                        _SummaryRow(
                          label: l10n.amiodaronLabel,
                          value: '${snapshot.amiodaronGaben.length}',
                        ),
                        _SummaryRow(
                          label: l10n.summaryStartzeit,
                          value: formatWallTime(snapshot.startzeit),
                        ),
                        if (endZeitpunkt != null)
                          _SummaryRow(
                            label: l10n.summaryEndzeit,
                            value: formatWallTime(
                              snapshot.startzeit.add(endZeitpunkt),
                            ),
                          ),
                        if (ende != null)
                          _SummaryRow(
                            label: l10n.summaryEndReason,
                            value: beendigungsgrundLabel(l10n, ende.grund),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: PageLayout.space20),
                ProtokollListe(
                  protokoll: snapshot.protokoll,
                  startzeit: snapshot.startzeit,
                  isLive: false,
                  onOpenEintrag: openProtokollEintrag,
                ),
                const SizedBox(height: PageLayout.space20),
                Text(
                  l10n.messwerteTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PageLayout.space8),
                if (snapshot.messwerte.isEmpty)
                  Text(
                    l10n.messwerteEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (final (index, messwert)
                            in snapshot.messwerte.indexed) ...[
                          if (index > 0)
                            const Divider(height: PageLayout.dividerHeight),
                          MesswertTile(messwert: messwert),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: PageLayout.space8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openMesswerte,
                    icon: const Icon(Icons.assignment_outlined),
                    label: Text(l10n.messwerteOpenButton),
                  ),
                ),
                const SizedBox(height: PageLayout.space20),
                Text(
                  l10n.summaryNotes,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PageLayout.space8),
                if (notizen.isEmpty)
                  Text(
                    l10n.summaryNoNotes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (final notiz in notizen)
                          ListTile(
                            leading: Text(
                              formatReanimationsdauer(notiz.zeitpunkt),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            title: Text(notiz.text),
                            subtitle: Text(
                              formatWallTime(
                                snapshot.startzeit.add(notiz.zeitpunkt),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PageLayout.space4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: PageLayout.space12),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
