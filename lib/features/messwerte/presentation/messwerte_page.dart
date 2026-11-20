import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/features/messwerte/presentation/messwert_erfassen_dialog.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwert_format.dart';
import 'package:hp_cpr/features/messwerte/presentation/messwert_tile.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/dialogs/notiz_erfassen_dialog.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';
import 'package:hp_cpr/ui/zeitstempel_zeile.dart';

/// The Messwerte and free-text notes of a Reanimationsfall.
///
/// Both lists are ordered like the Protokoll: by time, then recording order.
class MesswertePage extends StatefulWidget {
  const MesswertePage({
    super.key,
    required this.routes,
    required this.reanimationsfall,
    required this.session,
  });

  final AppRoutes routes;

  final Reanimationsfall reanimationsfall;
  final ReanimationsfallSession session;

  @override
  State<MesswertePage> createState() => _MesswertePageState();
}

class _MesswertePageState extends State<MesswertePage> {
  late ReanimationsfallSnapshot _snapshot = widget.reanimationsfall.snapshot();

  Future<void> _recordMesswert(MesswertTyp typ) async {
    final eingabe = await showDialog<MesswertEingabe>(
      context: context,
      builder: (_) => MesswertErfassenDialog(typ: typ),
    );
    if (eingabe == null || !mounted) return;

    final reanimationsfall = widget.reanimationsfall;
    setState(() {
      switch (eingabe) {
        case TemperaturEingabe(:final celsius, :final notiz):
          reanimationsfall.recordTemperatur(celsius, notiz: notiz);
        case BlutzuckerEingabe(:final mgDl, :final notiz):
          reanimationsfall.recordBlutzucker(mgDl, notiz: notiz);
        case BlutdruckEingabe(
          :final systolisch,
          :final diastolisch,
          :final notiz,
        ):
          reanimationsfall.recordBlutdruck(
            systolisch: systolisch,
            diastolisch: diastolisch,
            notiz: notiz,
          );
        case HerzfrequenzEingabe(:final proMinute, :final notiz):
          reanimationsfall.recordHerzfrequenz(proMinute, notiz: notiz);
      }
      _snapshot = reanimationsfall.snapshot();
    });
    unawaited(widget.session.persist(reanimationsfall));
  }

  Future<void> _recordNotiz() async {
    final text = await showNotizErfassenDialog(context);
    if (text == null || !mounted) return;

    final reanimationsfall = widget.reanimationsfall;
    setState(() {
      reanimationsfall.recordNotiz(text);
      _snapshot = reanimationsfall.snapshot();
    });
    unawaited(widget.session.persist(reanimationsfall));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n.messwerteTitle),
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
                Wrap(
                  spacing: PageLayout.space12,
                  runSpacing: PageLayout.space8,
                  children: [
                    for (final typ in MesswertTyp.values)
                      FilledButton.tonalIcon(
                        onPressed: () => _recordMesswert(typ),
                        icon: Icon(messwertIcon(typ)),
                        label: Text(messwertTypLabel(l10n, typ)),
                      ),
                    OutlinedButton.icon(
                      onPressed: _recordNotiz,
                      icon: const Icon(Icons.notes),
                      label: Text(l10n.notizErfassenButton),
                    ),
                  ],
                ),
                const SizedBox(height: PageLayout.space20),
                Text(
                  l10n.messwerteTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PageLayout.space8),
                if (_snapshot.messwerte.isEmpty)
                  Text(
                    l10n.messwerteEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (index, messwert) in _sortedByTime(
                          _snapshot.messwerte,
                          (m) => m.zeitpunkt,
                        ).indexed) ...[
                          if (index > 0)
                            const Divider(height: PageLayout.dividerHeight),
                          MesswertTile(
                            messwert: messwert,
                            startzeit: _snapshot.startzeit,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: PageLayout.space20),
                Text(
                  l10n.notizenTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PageLayout.space8),
                if (_snapshot.notizen.isEmpty)
                  Text(
                    l10n.notizenEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (index, notiz) in _sortedByTime(
                          _snapshot.notizen,
                          (n) => n.zeitpunkt,
                        ).indexed) ...[
                          if (index > 0)
                            const Divider(height: PageLayout.dividerHeight),
                          ZeitstempelZeile(
                            zeitpunkt: notiz.zeitpunkt,
                            startzeit: _snapshot.startzeit,
                            icon: Icons.notes,
                            title: notiz.text,
                          ),
                        ],
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

/// Orders by time, keeping recording order for equal times (as the Protokoll).
List<T> _sortedByTime<T>(List<T> items, Duration Function(T) zeitpunkt) {
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final byTime = zeitpunkt(a.$2).compareTo(zeitpunkt(b.$2));
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return [for (final (_, item) in indexed) item];
}
