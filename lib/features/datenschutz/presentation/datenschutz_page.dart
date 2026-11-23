import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hp_cpr/features/datenschutz/domain/datenschutz_markdown.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/content_page_scaffold.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

const datenschutzWebAsset = 'assets/legal/datenschutz_web.md';
const datenschutzAppAsset = 'assets/legal/datenschutz_app.md';

/// Opens an external link of the Datenschutzerklärung.
typedef DatenschutzLinkOpener = Future<void> Function(Uri uri);

Future<void> openLegalLinkExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// The Datenschutzerklärung, loaded from the bundled asset so it works offline.
///
/// The web app and the Android app show different variants.
class DatenschutzPage extends StatelessWidget {
  const DatenschutzPage({
    super.key,
    required this.routes,
    bool? isWeb,
    this.linkOpener = openLegalLinkExternally,
  }) : isWeb = isWeb ?? kIsWeb;

  final AppRoutes routes;

  /// Whether to show the web variant. Defaults to the running platform.
  final bool isWeb;
  final DatenschutzLinkOpener linkOpener;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asset = isWeb ? datenschutzWebAsset : datenschutzAppAsset;

    return ContentPageScaffold.builder(
      title: l10n.datenschutzTitle,
      routes: routes,
      bodyBuilder: (context) => LegalDocumentBody(
        key: ValueKey(asset),
        asset: asset,
        loadErrorText: l10n.datenschutzLoadError,
        bundle: DefaultAssetBundle.of(context),
        linkOpener: linkOpener,
      ),
    );
  }
}

/// Renders a bundled legal Markdown document (Datenschutz, Impressum).
class LegalDocumentBody extends StatefulWidget {
  const LegalDocumentBody({
    super.key,
    required this.asset,
    required this.loadErrorText,
    required this.bundle,
    required this.linkOpener,
  });

  final String asset;
  final String loadErrorText;
  final AssetBundle bundle;
  final DatenschutzLinkOpener linkOpener;

  @override
  State<LegalDocumentBody> createState() => _LegalDocumentBodyState();
}

class _LegalDocumentBodyState extends State<LegalDocumentBody> {
  late final Future<List<DatenschutzBlock>> _blocks = widget.bundle
      .loadString(widget.asset)
      .then(parseDatenschutzMarkdown);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DatenschutzBlock>>(
      future: _blocks,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: PageLayout.contentPagePadding,
            child: Text(widget.loadErrorText),
          );
        }
        final blocks = snapshot.data;
        if (blocks == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SelectionArea(
          child: ListView.builder(
            padding: PageLayout.contentPagePadding,
            itemCount: blocks.length,
            itemBuilder: (context, index) =>
                _BlockView(block: blocks[index], linkOpener: widget.linkOpener),
          ),
        );
      },
    );
  }
}

class _BlockView extends StatefulWidget {
  const _BlockView({required this.block, required this.linkOpener});

  final DatenschutzBlock block;
  final DatenschutzLinkOpener linkOpener;

  @override
  State<_BlockView> createState() => _BlockViewState();
}

class _BlockViewState extends State<_BlockView> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;
    final base = switch (block.headingLevel) {
      1 => theme.textTheme.headlineSmall,
      2 => theme.textTheme.titleMedium,
      _ => theme.textTheme.bodyMedium,
    };
    final style = block.isHeading
        ? base?.copyWith(fontWeight: FontWeight.w700)
        : base;

    _disposeRecognizers();
    final spans = <InlineSpan>[
      for (final span in block.spans) _toInlineSpan(span, theme),
    ];

    return Padding(
      padding: EdgeInsets.only(
        top: block.isHeading ? PageLayout.space16 : PageLayout.space0,
        bottom: block.isHeading ? PageLayout.space8 : PageLayout.space12,
      ),
      child: Semantics(
        header: block.isHeading,
        child: Text.rich(TextSpan(children: spans), style: style),
      ),
    );
  }

  InlineSpan _toInlineSpan(DatenschutzSpan span, ThemeData theme) {
    final url = span.url;
    TapGestureRecognizer? recognizer;
    if (url != null) {
      recognizer = TapGestureRecognizer()
        ..onTap = () => widget.linkOpener(Uri.parse(url));
      _recognizers.add(recognizer);
    }
    return TextSpan(
      text: span.text,
      recognizer: recognizer,
      style: TextStyle(
        fontWeight: span.bold ? FontWeight.w700 : null,
        color: url != null ? theme.colorScheme.primary : null,
        decoration: url != null ? TextDecoration.underline : null,
      ),
    );
  }
}
