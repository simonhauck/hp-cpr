import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/case_session/presentation/start_page.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';

class HpCprApp extends StatefulWidget {
  const HpCprApp({super.key, this.clock, this.settings, this.wakeLock});

  /// Injectable for tests; defaults to the monotonic system clock.
  final AppClock? clock;

  /// Injectable for tests; defaults to app-wide settings.
  final AppSettings? settings;

  /// Injectable for tests; defaults to the platform wake lock.
  final WakeLock? wakeLock;

  @override
  State<HpCprApp> createState() => _HpCprAppState();
}

class _HpCprAppState extends State<HpCprApp> {
  late final AppClock _clock = widget.clock ?? SystemClock();
  late final WakeLock _wakeLock =
      widget.wakeLock ?? const WakelockPlusWakeLock();
  late final AppSettings _settings = widget.settings ?? AppSettings();
  late final bool _ownsSettings = widget.settings == null;

  @override
  void dispose() {
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

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
      home: StartPage(clock: _clock, settings: _settings, wakeLock: _wakeLock),
    );
  }
}
