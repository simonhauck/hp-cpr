import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/core/vibrator.dart';
import 'package:hp_cpr/features/about/presentation/about_page.dart';
import 'package:hp_cpr/features/einsatzlog/presentation/einsatzlog_page.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/features/settings/presentation/settings_page.dart';
import 'package:hp_cpr/features/tutorial/data/tutorial_store.dart';
import 'package:hp_cpr/features/tutorial/presentation/demo_start_request.dart';
import 'package:hp_cpr/ui/navigation/app_destination.dart';

/// Builds the pages behind the app menu.
///
/// The app shell owns the dependencies; pages only ask for a destination.
class AppRoutes {
  const AppRoutes({
    required this.settings,
    required this.clock,
    required this.vibrator,
    required this.session,
    required this.tutorialStore,
    required this.demoStartRequest,
  });

  final AppSettings settings;
  final AppClock clock;
  final Vibrator vibrator;
  final ReanimationsfallSession session;
  final TutorialStore tutorialStore;

  /// Lets the tutorial ask the start page for a demo Reanimationsfall.
  final DemoStartRequest demoStartRequest;

  Widget page(AppDestination destination) => switch (destination) {
    AppDestination.einsatzlog => EinsatzlogPage(session: session, routes: this),
    AppDestination.einstellungen => SettingsPage(
      settings: settings,
      vibrator: vibrator,
      routes: this,
    ),
    AppDestination.ueber => AboutPage(routes: this),
  };
}
