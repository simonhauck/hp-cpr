import 'package:flutter/material.dart';

import 'package:hp_cpr/features/tutorial/presentation/tutorial_page.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The app-wide drawer with the menu destinations.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.routes, this.currentDestination});

  final AppRoutes routes;

  /// The destination currently on screen, or null outside the menu pages.
  final AppDestination? currentDestination;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PageLayout.space20,
                PageLayout.space20,
                PageLayout.space20,
                PageLayout.space8,
              ),
              child: Text(
                l10n.appTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: PageLayout.appTitleLetterSpacing,
                ),
              ),
            ),
            const Divider(height: PageLayout.dividerHeight),
            _destination(
              context,
              AppDestination.einsatzlog,
              icon: Icons.list_alt_outlined,
              label: l10n.einsatzlogTitle,
            ),
            _destination(
              context,
              AppDestination.einstellungen,
              icon: Icons.settings_outlined,
              label: l10n.settingsTitle,
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(l10n.tutorialTitle),
              onTap: () => _openTutorial(context),
            ),
            _destination(
              context,
              AppDestination.ueber,
              icon: Icons.info_outline,
              label: l10n.aboutTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _destination(
    BuildContext context,
    AppDestination destination, {
    required IconData icon,
    required String label,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: destination == currentDestination,
      onTap: () => _select(context, destination),
    );
  }

  Future<void> _openTutorial(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    final canStartDemo = await routes.session.loadActive() == null;
    if (!navigator.mounted) return;

    final outcome = await showTutorial(
      navigator.context,
      canStartDemo: canStartDemo,
    );
    if (outcome != TutorialOutcome.startDemo || !navigator.mounted) return;

    // Only the start page creates Reanimationsfälle, so return to it first.
    navigator.popUntil((route) => route.isFirst);
    routes.demoStartRequest.request();
  }

  void _select(BuildContext context, AppDestination destination) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (destination == currentDestination) return;

    final route = MaterialPageRoute<void>(
      builder: (_) => routes.page(destination),
    );
    // Between menu pages the stack must not grow, so back returns to the page
    // the drawer was first opened from.
    if (currentDestination != null) {
      navigator.pushReplacement(route);
    } else {
      navigator.push(route);
    }
  }
}

/// Opens the end drawer ([AppDrawer]) of the surrounding [Scaffold].
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      onPressed: () => Scaffold.of(context).openEndDrawer(),
      tooltip: l10n.menuOpenTooltip,
      icon: const Icon(Icons.menu),
      constraints: const BoxConstraints.tightFor(
        width: PageLayout.touchTargetSize,
        height: PageLayout.touchTargetSize,
      ),
      padding: EdgeInsets.zero,
    );
  }
}
