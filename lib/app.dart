import 'package:flutter/material.dart';

import 'package:hp_cpr/core/clock.dart';
import 'package:hp_cpr/core/vibrator.dart';
import 'package:hp_cpr/core/wake_lock.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_session.dart';
import 'package:hp_cpr/features/reanimationsfall/data/reanimationsfall_store.dart';
import 'package:hp_cpr/features/reanimationsfall/presentation/start_page.dart';
import 'package:hp_cpr/features/settings/domain/app_settings.dart';
import 'package:hp_cpr/l10n/app_localizations.dart';
import 'package:hp_cpr/ui/navigation/app_routes.dart';
import 'package:hp_cpr/ui/theme/due_colors.dart';

class HpCprApp extends StatefulWidget {
  const HpCprApp({
    super.key,
    this.clock,
    this.settings,
    this.wakeLock,
    this.vibrator,
    this.store,
  });

  /// Injectable for tests; defaults to the monotonic system clock.
  final AppClock? clock;

  /// Injectable for tests; defaults to app-wide settings.
  final AppSettings? settings;

  /// Injectable for tests; defaults to the platform wake lock.
  final WakeLock? wakeLock;

  /// Injectable for tests; defaults to the platform haptic feedback.
  final Vibrator? vibrator;

  /// Injectable for tests; defaults to the local preferences store.
  final ReanimationsfallStore? store;

  @override
  State<HpCprApp> createState() => _HpCprAppState();
}

class _HpCprAppState extends State<HpCprApp> {
  late final AppClock _clock = widget.clock ?? SystemClock();
  late final WakeLock _wakeLock =
      widget.wakeLock ?? const WakelockPlusWakeLock();
  late final Vibrator _vibrator = widget.vibrator ?? const HapticVibrator();
  late final AppSettings _settings = widget.settings ?? AppSettings();
  late final bool _ownsSettings = widget.settings == null;
  late final ReanimationsfallStore _store =
      widget.store ?? const SharedPreferencesReanimationsfallStore();
  late final ReanimationsfallSession _session = ReanimationsfallSession(
    store: _store,
    clock: _clock,
  );
  late final AppRoutes _routes = AppRoutes(
    settings: _settings,
    clock: _clock,
    vibrator: _vibrator,
    session: _session,
  );

  @override
  void dispose() {
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const inputDecorationTheme = InputDecorationTheme(
      border: OutlineInputBorder(),
    );
    // A calm blue keeps primary emphasis apart from the error red, which is
    // reserved for overdue states. "Due" uses [DueColors] (amber).
    const seedColor = Color(0xFF1565C0);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        extensions: const [DueColors.light],
        useMaterial3: true,
        inputDecorationTheme: inputDecorationTheme,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        extensions: const [DueColors.dark],
        useMaterial3: true,
        inputDecorationTheme: inputDecorationTheme,
      ),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: StartPage(
        clock: _clock,
        routes: _routes,
        wakeLock: _wakeLock,
        vibrator: _vibrator,
        session: _session,
      ),
    );
  }
}
