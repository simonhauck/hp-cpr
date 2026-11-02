import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_entry_actions.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_liste.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The Protokoll of the currently running Reanimationsfall.
class ProtokollPage extends StatefulWidget {
  const ProtokollPage({
    super.key,
    required this.reanimationsfall,
    required this.session,
    required this.routes,
  });

  final Reanimationsfall reanimationsfall;
  final ReanimationsfallSession session;
  final AppRoutes routes;

  @override
  State<ProtokollPage> createState() => _ProtokollPageState();
}

class _ProtokollPageState extends State<ProtokollPage> {
  bool _apply(ProtokollKorrektur korrektur) {
    try {
      setState(() {
        widget.reanimationsfall.applyProtokollKorrektur(korrektur);
      });
      unawaited(widget.session.persist(widget.reanimationsfall));
      return true;
    } on ArgumentError {
      _showError();
      return false;
    } on StateError {
      _showError();
      return false;
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).protokollCorrectionFailed),
      ),
    );
  }

  Future<void> _openEntry(ProtokollEintrag eintrag) async {
    final snapshot = widget.reanimationsfall.snapshot();
    await showProtokollEntryActions(
      context,
      eintrag: eintrag,
      startzeit: snapshot.startzeit,
      maxZeitpunkt:
          snapshot.ende?.zeitpunkt ??
          snapshot.verworfenAm ??
          snapshot.reanimationsdauer,
      onApply: _apply,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = widget.reanimationsfall.snapshot();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n.protokollTitle),
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
                ProtokollListe(
                  protokoll: snapshot.protokoll,
                  startzeit: snapshot.startzeit,
                  isLive: snapshot.istLaufend || snapshot.istRosc,
                  onOpenEntry: _openEntry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
