import 'package:flutter/material.dart';

import 'package:hp_cpr/core/app_info.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

/// Legal information and the bundled license texts.
class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.routes});

  final AppRoutes routes;

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late final Future<AppInfo?> _appInfo = AppInfo.load();

  Future<void> _openLicenses() async {
    final info = await _appInfo;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    showLicensePage(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: info?.versionLabel(l10n.versionWithBuild),
      applicationLegalese: l10n.licensesLegalese,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n.legalTitle),
        actions: const [
          AppMenuButton(),
          SizedBox(width: PageLayout.space8),
        ],
      ),
      drawer: AppDrawer(
        routes: widget.routes,
        currentDestination: AppDestination.rechtliches,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PageLayout.settingsContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                PageLayout.space20,
                PageLayout.space16,
                PageLayout.space20,
                PageLayout.space24,
              ),
              children: [
                Text(
                  l10n.legalDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PageLayout.space16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.legalLicensesTile),
                    subtitle: Text(l10n.legalLicensesDescription),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openLicenses,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
