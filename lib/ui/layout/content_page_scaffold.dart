import 'package:flutter/material.dart';

import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The shared frame for the app's non-timer pages.
///
/// It owns the app bar with back and menu buttons, the end drawer, the safe
/// area, centering, and the width cap. Use the default constructor for a plain
/// list of [children], or [ContentPageScaffold.builder] when the body needs its
/// own builder (futures, listenables) or is not a list. A builder body applies
/// [PageLayout.contentPagePadding] itself.
class ContentPageScaffold extends StatelessWidget {
  const ContentPageScaffold({
    super.key,
    required this.title,
    required this.routes,
    this.currentDestination,
    required List<Widget> this.children,
  }) : bodyBuilder = null;

  const ContentPageScaffold.builder({
    super.key,
    required this.title,
    required this.routes,
    this.currentDestination,
    required WidgetBuilder this.bodyBuilder,
  }) : children = null;

  final String title;
  final AppRoutes routes;

  /// The menu destination this page represents, or null for other pages.
  final AppDestination? currentDestination;

  final List<Widget>? children;
  final WidgetBuilder? bodyBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(title),
        actions: const [
          AppMenuButton(),
          SizedBox(width: PageLayout.space8),
        ],
      ),
      endDrawer: AppDrawer(
        routes: routes,
        currentDestination: currentDestination,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PageLayout.settingsContentWidth,
            ),
            child: bodyBuilder != null
                ? Builder(builder: bodyBuilder!)
                : ListView(
                    padding: PageLayout.contentPagePadding,
                    children: children!,
                  ),
          ),
        ),
      ),
    );
  }
}
