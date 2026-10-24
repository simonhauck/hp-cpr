import 'package:flutter/material.dart';

import 'package:hp_cpr/features/cpr_tracker/presentation/cpr_tracker_page.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

class HpCprApp extends StatelessWidget {
  const HpCprApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFB3261E);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const CprTrackerPage(),
    );
  }
}
