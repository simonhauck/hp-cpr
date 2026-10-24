// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'HP-CPR';

  @override
  String get homeTitle => 'Reanimations-Tracker';

  @override
  String get homeSubtitle => 'High-Performance-CPR';

  @override
  String get homeDescription =>
      'Die Companion-App begleitet künftig den Reanimationsablauf mit Timer, Medikamenten- und Analyse-Erinnerungen.';

  @override
  String get elapsedTimeLabel => 'Reanimationsdauer';

  @override
  String get elapsedTimePlaceholder => '00:00';

  @override
  String get statusNotStarted => 'Noch nicht gestartet';

  @override
  String get startCprButton => 'Reanimation starten';

  @override
  String get comingSoonHint =>
      'Der Timer wird im nächsten Entwicklungsschritt ergänzt.';

  @override
  String get setupCompleteTitle => 'Projekt eingerichtet';

  @override
  String get setupCompleteDescription =>
      'Flutter, die Android- und Web-Ziele sowie die deutsche Oberfläche sind vorbereitet.';
}
