import 'package:flutter/material.dart';

import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// The app-wide drawer with the menu destinations.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.routes,
    this.currentDestination,
    this.onOpenMesswerte,
  });

  final AppRoutes routes;

  /// The destination currently on screen, or null outside the menu pages.
  final AppDestination? currentDestination;

  /// Opens the Messwerte of the active case; null when no case is running.
  final VoidCallback? onOpenMesswerte;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: PageLayout.appTitleLetterSpacing,
                    ),
                  ),
                  Text(
                    l10n.menuTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
            _destination(
              context,
              AppDestination.rechtliches,
              icon: Icons.gavel_outlined,
              label: l10n.legalTitle,
            ),
            _destination(
              context,
              AppDestination.ueber,
              icon: Icons.info_outline,
              label: l10n.aboutTitle,
            ),
            if (onOpenMesswerte != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: Text(l10n.messwerteTitle),
                onTap: () => _openMesswerte(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openMesswerte(BuildContext context) {
    final open = onOpenMesswerte;
    if (open == null) return;
    Navigator.of(context).pop();
    open();
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

  void _select(BuildContext context, AppDestination destination) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (destination == currentDestination) return;

    navigator.push(
      MaterialPageRoute<void>(builder: (_) => routes.page(destination)),
    );
  }
}

/// Opens the [AppDrawer] of the surrounding [Scaffold].
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      onPressed: () => Scaffold.of(context).openDrawer(),
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
