import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_entry_actions.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// Shared correction handling for the live and completed Protokoll pages.
mixin ProtokollCorrectionsMixin<T extends StatefulWidget> on State<T> {
  Reanimationsfall get protokollFall;
  ReanimationsfallSession get protokollSession;

  bool applyProtokollKorrektur(ProtokollKorrektur korrektur) {
    try {
      setState(() => protokollFall.applyProtokollKorrektur(korrektur));
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

  Future<void> openProtokollEintrag(ProtokollEintrag eintrag) async {
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

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).protokollCorrectionFailed),
      ),
    );
  }
}
