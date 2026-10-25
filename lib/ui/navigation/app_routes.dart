import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/features/about/presentation/about_page.dart';
import 'package:hp_cpr/features/einsatzlog/presentation/einsatzlog_page.dart';
import 'package:hp_cpr/features/legal/presentation/legal_page.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/features/settings/presentation/settings_page.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';

/// Builds the pages behind the app menu.
///
/// The app shell owns the dependencies; pages only ask for a destination.
class AppRoutes {
  const AppRoutes({
    required this.settings,
    required this.clock,
    required this.session,
  });

  final AppSettings settings;
  final AppClock clock;
  final ReanimationsfallSession session;

  Widget page(AppDestination destination) => switch (destination) {
    AppDestination.einsatzlog => EinsatzlogPage(session: session, routes: this),
    AppDestination.einstellungen => SettingsPage(
      settings: settings,
      routes: this,
    ),
    AppDestination.rechtliches => LegalPage(routes: this),
    AppDestination.ueber => AboutPage(routes: this),
  };
}
