import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwert_format.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwert_tile.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwerte_page.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/end_reanimationsfall_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/rhythmusanalyse_format.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The in-app summary of an ended Reanimationsfall.
class ReanimationsfallSummaryPage extends StatelessWidget {
  const ReanimationsfallSummaryPage({
    super.key,
    required this.snapshot,
    required this.routes,
  });

  final ReanimationsfallSnapshot snapshot;
  final AppRoutes routes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ende = snapshot.ende;
    final endZeitpunkt = ende?.zeitpunkt ?? snapshot.verworfenAm;

    final notes = <_SummaryNote>[
      for (final notiz in snapshot.notizen)
        _SummaryNote(zeitpunkt: notiz.zeitpunkt, text: notiz.text),
    ]..sort((a, b) => a.zeitpunkt.compareTo(b.zeitpunkt));

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
      drawer: AppDrawer(routes: routes),
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
                        LeitlinienprofilChip(
                          leitlinienprofil: snapshot.leitlinienprofil,
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
                Text(
                  l10n.summaryEvents,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PageLayout.space8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PageLayout.space16,
                      vertical: PageLayout.space4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (index, event) in _events(l10n).indexed) ...[
                          if (index > 0)
                            const Divider(height: PageLayout.dividerHeight),
                          _TimelineRow(event: event),
                        ],
                      ],
                    ),
                  ),
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
                    onPressed: () => _openMesswerte(context),
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
                if (notes.isEmpty)
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
                        for (final note in notes)
                          ListTile(
                            leading: Text(
                              formatReanimationsdauer(note.zeitpunkt),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            title: Text(note.text),
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

  List<_SummaryEvent> _events(AppLocalizations l10n) {
    final events = <_SummaryEvent>[];
    var order = 0;

    void add(Duration zeitpunkt, IconData icon, String text, {String? detail}) {
      events.add(
        _SummaryEvent(
          zeitpunkt: zeitpunkt,
          order: order++,
          icon: icon,
          text: text,
          detail: detail,
        ),
      );
    }

    add(Duration.zero, Icons.play_arrow, l10n.eventCaseStart);

    for (final (index, schock) in snapshot.schocks.indexed) {
      final energie = schock.energieJoule;
      add(
        schock.zeitpunkt,
        Icons.bolt_outlined,
        energie == null
            ? l10n.eventSchock(index + 1)
            : l10n.eventSchockWithEnergy(index + 1, energie),
      );
    }

    for (final gabe in snapshot.adrenalinGaben) {
      add(
        gabe.zeitpunkt,
        Icons.medication_outlined,
        l10n.eventAdrenalin(gabe.dosisMg),
      );
    }

    for (final gabe in snapshot.amiodaronGaben) {
      add(
        gabe.zeitpunkt,
        Icons.vaccines_outlined,
        l10n.eventAmiodaron(gabe.dosisMg),
      );
    }

    for (final eintrag in snapshot.rhythmusanalyseEintraege) {
      add(
        eintrag.zeitpunkt,
        Icons.monitor_heart_outlined,
        l10n.eventRhythmusanalyse(
          rhythmusanalyseErgebnisLabel(l10n, eintrag.ergebnis),
        ),
      );
    }

    for (final messwert in snapshot.messwerte) {
      add(
        messwert.zeitpunkt,
        messwertIcon(messwert.typ),
        l10n.eventMesswert(
          messwertTypLabel(l10n, messwert.typ),
          formatMesswert(l10n, messwert),
        ),
        detail: messwert.notiz,
      );
    }

    for (final notiz in snapshot.notizen) {
      add(notiz.zeitpunkt, Icons.notes, l10n.eventNotiz(notiz.text));
    }

    for (final ueberspringung in snapshot.uebersprungeneRhythmusanalysen) {
      add(
        ueberspringung.zeitpunkt,
        Icons.skip_next_outlined,
        l10n.eventRhythmusanalyseSkipped,
      );
    }

    for (final neustart in snapshot.druckphaseNeustarts) {
      add(neustart.zeitpunkt, Icons.restart_alt, l10n.eventDruckphaseRestarted);
    }

    for (final rosc in snapshot.roscEreignisse) {
      add(rosc.zeitpunkt, Icons.favorite_outline, l10n.eventRosc);
    }

    for (final wiederbeginn in snapshot.wiederbeginnEreignisse) {
      add(wiederbeginn.zeitpunkt, Icons.replay, l10n.eventResuscitationResumed);
    }

    final ende = snapshot.ende;
    if (ende != null) {
      add(
        ende.zeitpunkt,
        Icons.stop_circle_outlined,
        l10n.eventCaseEnded(beendigungsgrundLabel(l10n, ende.grund)),
      );
    }

    final verworfenAm = snapshot.verworfenAm;
    if (verworfenAm != null) {
      add(verworfenAm, Icons.block, l10n.eventCaseDiscarded);
    }

    events.sort((a, b) {
      final byTime = a.zeitpunkt.compareTo(b.zeitpunkt);
      return byTime != 0 ? byTime : a.order.compareTo(b.order);
    });
    return events;
  }

  void _openMesswerte(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MesswertePage(snapshot: snapshot, routes: routes),
      ),
    );
  }
}

class _SummaryNote {
  const _SummaryNote({required this.zeitpunkt, required this.text});

  final Duration zeitpunkt;
  final String text;
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

class _SummaryEvent {
  const _SummaryEvent({
    required this.zeitpunkt,
    required this.order,
    required this.icon,
    required this.text,
    this.detail,
  });

  final Duration zeitpunkt;
  final int order;
  final IconData icon;
  final String text;
  final String? detail;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final _SummaryEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PageLayout.space6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: PageLayout.timelineTimeWidth,
            child: Text(
              formatReanimationsdauer(event.zeitpunkt),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Icon(
            event.icon,
            size: PageLayout.iconSmall,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: PageLayout.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.detail != null)
                  Text(
                    event.detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
