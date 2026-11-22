import 'package:flutter/material.dart';

import 'package:hp_cpr/features/leitlinienprofil/presentation/leitlinienprofil_chip.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/end_reanimationsfall_dialog.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_corrections_mixin.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_liste.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/demo_modus_chip.dart';
import 'package:hp_cpr/ui/layout/content_page_scaffold.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final snapshot = widget.reanimationsfall.snapshot();
    final ende = snapshot.ende;
    final endZeitpunkt = ende?.zeitpunkt ?? snapshot.verworfenAm;

    return ContentPageScaffold(
      title: l10n.summaryTitle,
      routes: widget.routes,
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
                  label: l10n.summaryReanimationsdauer,
                  value: formatReanimationsdauer(snapshot.reanimationsdauer),
                ),
                _SummaryRow(
                  label: l10n.summaryCprDuration,
                  value: formatReanimationsdauer(snapshot.cprDauer),
                ),
                _SummaryRow(
                  label: l10n.summaryShocks,
                  value: _withVorbehandlung(
                    l10n,
                    snapshot.schockAnzahl,
                    snapshot.vorbehandlung.schocks,
                  ),
                ),
                _SummaryRow(
                  label: l10n.adrenalinLabel,
                  value: _withVorbehandlung(
                    l10n,
                    snapshot.adrenalinAnzahl,
                    snapshot.vorbehandlung.adrenalin,
                  ),
                ),
                _SummaryRow(
                  label: l10n.amiodaronLabel,
                  value: _withVorbehandlung(
                    l10n,
                    snapshot.amiodaronAnzahl,
                    snapshot.vorbehandlung.amiodaron,
                  ),
                ),
                _SummaryRow(
                  label: l10n.summaryStartzeit,
                  value: l10n.wallTimeValue(formatWallTime(snapshot.startzeit)),
                ),
                if (snapshot.uebernahme != snapshot.startzeit)
                  _SummaryRow(
                    label: l10n.summaryUebernahme,
                    value: l10n.wallTimeValue(
                      formatWallTime(snapshot.uebernahme),
                    ),
                  ),
                if (endZeitpunkt != null)
                  _SummaryRow(
                    label: l10n.summaryEndzeit,
                    value: l10n.wallTimeValue(
                      formatWallTime(snapshot.startzeit.add(endZeitpunkt)),
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
          onOpenEintrag: openProtokollEintrag,
        ),
      ],
    );
  }
}

/// The total, followed by the Vorbehandlung share when there is one.
String _withVorbehandlung(AppLocalizations l10n, int total, int vorbehandlung) {
  if (vorbehandlung == 0) return '$total';
  return '$total ${l10n.summaryVorbehandlungDavon(vorbehandlung)}';
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
