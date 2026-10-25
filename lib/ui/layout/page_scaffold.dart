import 'package:flutter/material.dart';

import 'package:hp_cpr/ui/layout/page_layout.dart';

/// Builds a page section from the computed [PageLayout].
typedef PageLayoutBuilder = Widget Function(
  BuildContext context,
  PageLayout layout,
);

/// The shared frame for the app's timer pages.
///
/// It owns the safe area, centering, width cap, layout computation, page
/// padding, and the header/content/footer column. Scrolling belongs to the
/// content builder.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.maxWidth,
    required this.header,
    required this.content,
    this.footer,
    this.drawer,
  });

  final double maxWidth;
  final PageLayoutBuilder header;
  final PageLayoutBuilder content;
  final PageLayoutBuilder? footer;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: LayoutBuilder(
              builder: (context, viewport) {
                final layout = PageLayout.from(viewport);

                return Padding(
                  padding: layout.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header(context, layout),
                      SizedBox(height: layout.sectionGap),
                      Expanded(child: content(context, layout)),
                      if (footer != null) ...[
                        SizedBox(height: layout.sectionGap),
                        footer!(context, layout),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
