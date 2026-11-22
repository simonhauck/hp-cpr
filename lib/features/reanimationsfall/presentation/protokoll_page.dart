import 'package:flutter/material.dart';

import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/domain/reanimationsfall.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_corrections_mixin.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/protokoll_liste.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/content_page_scaffold.dart';
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

class _ProtokollPageState extends State<ProtokollPage>
    with ProtokollCorrectionsMixin<ProtokollPage> {
  @override
  Reanimationsfall get protokollFall => widget.reanimationsfall;

  @override
  ReanimationsfallSession get protokollSession => widget.session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = widget.reanimationsfall.snapshot();

    return ContentPageScaffold(
      title: l10n.protokollTitle,
      routes: widget.routes,
      children: [
        ProtokollListe(
          protokoll: snapshot.protokoll,
          startzeit: snapshot.startzeit,
          onOpenEintrag: openProtokollEintrag,
        ),
      ],
    );
  }
}
