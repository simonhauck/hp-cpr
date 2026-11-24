import 'package:flutter/material.dart';

import 'package:hp_cpr/features/datenschutz/presentation/datenschutz_page.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/content_page_scaffold.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

const impressumAsset = 'assets/legal/impressum.md';

/// The Impressum, loaded from the bundled asset so it works offline.
class ImpressumPage extends StatelessWidget {
  const ImpressumPage({
    super.key,
    required this.routes,
    this.linkOpener = openLegalLinkExternally,
  });

  final AppRoutes routes;
  final DatenschutzLinkOpener linkOpener;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ContentPageScaffold.builder(
      title: l10n.impressumTitle,
      routes: routes,
      bodyBuilder: (context) => LegalDocumentBody(
        asset: impressumAsset,
        loadErrorText: l10n.impressumLoadError,
        bundle: DefaultAssetBundle.of(context),
        linkOpener: linkOpener,
      ),
    );
  }
}
