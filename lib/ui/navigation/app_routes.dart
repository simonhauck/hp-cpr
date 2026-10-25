import 'package:flutter/material.dart';

import 'package:hp_cpr/features/about/presentation/about_page.dart';
import 'package:hp_cpr/features/legal/presentation/legal_page.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/features/settings/presentation/settings_page.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';

/// Builds the pages behind the app menu.
///
/// The app shell owns the dependencies; pages only ask for a destination.
class AppRoutes {
  const AppRoutes({required this.settings});

  final AppSettings settings;

  Widget page(AppDestination destination) => switch (destination) {
    AppDestination.einstellungen => SettingsPage(
      settings: settings,
      routes: this,
    ),
    AppDestination.rechtliches => LegalPage(routes: this),
    AppDestination.ueber => AboutPage(routes: this),
  };
}
