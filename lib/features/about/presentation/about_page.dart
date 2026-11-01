import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hp_cpr/core/app_info.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/layout/page_layout.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';
import 'package:hp_cpr/ui/navigation/app_drawer.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';

const _githubUrl = 'https://github.com/simonhauck/hp-cpr';

/// The app name, installed version, description, copyright, and links.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key, required this.routes});

  final AppRoutes routes;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<AppInfo?> _appInfo = AppInfo.load();

  Future<void> _openGithub() async {
    await launchUrl(
      Uri.parse(_githubUrl),
      mode: LaunchMode.externalApplication,
    );
  }

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n.aboutTitle),
        actions: const [
          AppMenuButton(),
          SizedBox(width: PageLayout.space8),
        ],
      ),
      drawer: AppDrawer(
        routes: widget.routes,
        currentDestination: AppDestination.ueber,
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
                  l10n.appTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: PageLayout.appTitleLetterSpacing,
                  ),
                ),
                FutureBuilder<AppInfo?>(
                  future: _appInfo,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    if (info == null) return const SizedBox.shrink();
                    return Text(
                      l10n.aboutVersion(
                        info.versionLabel(l10n.versionWithBuild),
                      ),
                      style: theme.textTheme.titleMedium,
                    );
                  },
                ),
                const SizedBox(height: PageLayout.space16),
                Text(l10n.aboutDescription, style: theme.textTheme.bodyLarge),
                const SizedBox(height: PageLayout.space8),
                Text(
                  l10n.aboutCopyright,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PageLayout.space24),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: Text(l10n.aboutGithubTitle),
                        subtitle: Text(l10n.aboutGithubDescription),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: _openGithub,
                      ),
                      const Divider(height: PageLayout.dividerHeight),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(l10n.aboutLicensesTile),
                        subtitle: Text(l10n.aboutLicensesDescription),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openLicenses,
                      ),
                    ],
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
