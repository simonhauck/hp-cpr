import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_entry_actions.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/vorbehandlung_dialog.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// Shared correction handling for the running case, the live Protokoll and
/// the completed Protokoll.
mixin ProtokollCorrectionsMixin<T extends StatefulWidget> on State<T> {
  Reanimationsfall get protokollFall;
  ReanimationsfallSession get protokollSession;

  bool applyProtokollKorrektur(ProtokollKorrektur korrektur) {
    return _apply(() => protokollFall.applyProtokollKorrektur(korrektur));
  }

  Future<void> openProtokollEintrag(ProtokollEintrag eintrag) async {
    if (eintrag.typ == ProtokollEintragTyp.startzeit ||
        eintrag.typ == ProtokollEintragTyp.uebernahme ||
        eintrag.typ == ProtokollEintragTyp.vorbehandlung) {
      await openVorbehandlung();
      return;
    }

    final snapshot = protokollFall.snapshot();
    await showProtokollEintragActions(
      context,
      eintrag: eintrag,
      startzeit: snapshot.startzeit,
      maxZeitpunkt:
          snapshot.ende?.zeitpunkt ??
          snapshot.verworfenAm ??
          snapshot.reanimationsdauer,
      onApply: applyProtokollKorrektur,
    );
  }

  /// Opens the Vorbehandlung form and saves it as an append-only Korrektur.
  ///
  /// Returns whether the Vorbehandlung was saved.
  Future<bool> openVorbehandlung() async {
    final eingabe = await showVorbehandlungDialog(
      context,
      snapshot: protokollFall.snapshot(),
    );
    if (eingabe == null || !mounted) return false;

    final applied = _apply(
      () => protokollFall.correctVorbehandlung(
        uebernahme: eingabe.uebernahme,
        laufzeitBeiUebernahme: eingabe.laufzeitBeiUebernahme,
        schocks: eingabe.vorbehandlung.schocks,
        adrenalin: eingabe.vorbehandlung.adrenalin,
        amiodaron: eingabe.vorbehandlung.amiodaron,
        notiz: eingabe.vorbehandlung.notiz,
      ),
    );
    if (applied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).vorbehandlungSavedSnackbar,
          ),
        ),
      );
    }
    return applied;
  }

  bool _apply(VoidCallback korrektur) {
    try {
      setState(korrektur);
      unawaited(protokollSession.persist(protokollFall));
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
}
