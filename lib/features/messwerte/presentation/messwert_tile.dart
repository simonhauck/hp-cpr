import 'package:flutter/material.dart';

import 'package:hp_cpr/features/messwerte/presentation/messwert_format.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/messwert.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/timer_format.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

/// One recorded Messwert with its type, time, and optional note.
class MesswertTile extends StatelessWidget {
  const MesswertTile({super.key, required this.messwert});

  final Messwert messwert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      leading: Icon(messwertIcon(messwert.typ)),
      title: Text(formatMesswert(l10n, messwert)),
      subtitle: Text(
        [
          messwertTypLabel(l10n, messwert.typ),
          formatReanimationsdauer(messwert.zeitpunkt),
          ?messwert.notiz,
        ].join(' · '),
      ),
    );
  }
}
