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
  String get newCaseTitle => 'Neuer Reanimationsfall';

  @override
  String get guidelineLabel => 'Leitlinie';

  @override
  String get guidelineErc2025 => 'ERC 2025';

  @override
  String get guidelineAha2025 => 'AHA 2025';

  @override
  String get startNowTitle => 'Reanimation startet jetzt';

  @override
  String get startNowDescription =>
      'Die erste Thoraxkompression ist die Startzeit.';

  @override
  String get startNowButton => 'Jetzt starten';

  @override
  String get runningCaseTitle => 'Laufende Reanimation';

  @override
  String get backdateMinutesLabel => 'Minuten seit Beginn';

  @override
  String backdateChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get customStartzeitButton => 'Eigene Startzeit';

  @override
  String get customStartzeitTitle => 'Eigene Startzeit';

  @override
  String get customStartzeitDescription =>
      'Wie lange läuft die Reanimation bereits?';

  @override
  String get minutesLabel => 'Minuten';

  @override
  String get secondsLabel => 'Sekunden';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get startCaseButton => 'Starten';

  @override
  String get invalidBackdateMessage =>
      'Bitte eine Dauer größer als 0 eingeben.';

  @override
  String get invalidSecondsMessage =>
      'Sekunden müssen zwischen 0 und 59 liegen.';

  @override
  String get elapsedTimeLabel => 'Reanimationsdauer';

  @override
  String startzeitValue(String time) {
    return 'Startzeit $time';
  }

  @override
  String get phaseDruckphase => 'Druckphase';

  @override
  String get nextAnalysisLabel => 'Nächste Analyse';

  @override
  String get analysisDue => 'Analyse fällig';

  @override
  String overdueTimer(String time) {
    return '+$time';
  }
}
