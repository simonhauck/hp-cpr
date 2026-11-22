import 'package:flutter/material.dart';

import 'package:hp_cpr/features/messwerte/presentation/messwert_format.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/zeitstempel_zeile.dart';

/// One recorded Messwert with its type, time, and optional note.
class MesswertTile extends StatelessWidget {
  const MesswertTile({
    super.key,
    required this.messwert,
    required this.startzeit,
  });

  final Messwert messwert;
  final DateTime startzeit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ZeitstempelZeile(
      zeitpunkt: messwert.zeitpunkt,
      startzeit: startzeit,
      icon: messwertIcon(messwert.typ),
      title: formatMesswert(l10n, messwert),
      detail: [
        messwertTypLabel(l10n, messwert.typ),
        ?messwert.notiz,
      ].join(' · '),
    );
  }
}
