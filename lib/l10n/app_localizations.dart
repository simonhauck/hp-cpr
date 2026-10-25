import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// Name der App
  ///
  /// In de, this message translates to:
  /// **'HP-CPR'**
  String get appTitle;

  /// Überschrift der Startseite
  ///
  /// In de, this message translates to:
  /// **'Neuer Reanimationsfall'**
  String get newCaseTitle;

  /// Beschriftung des Leitlinien-Chips
  ///
  /// In de, this message translates to:
  /// **'Leitlinie'**
  String get guidelineLabel;

  /// Name des ERC-2025-Leitlinienprofils
  ///
  /// In de, this message translates to:
  /// **'ERC 2025'**
  String get guidelineErc2025;

  /// Name des AHA-2025-Leitlinienprofils
  ///
  /// In de, this message translates to:
  /// **'AHA 2025'**
  String get guidelineAha2025;

  /// Überschrift der Sofort-Start-Karte
  ///
  /// In de, this message translates to:
  /// **'Reanimation startet jetzt'**
  String get startNowTitle;

  /// Erklärung der Sofort-Start-Karte
  ///
  /// In de, this message translates to:
  /// **'Die erste Thoraxkompression ist die Startzeit.'**
  String get startNowDescription;

  /// Schaltfläche zum sofortigen Start
  ///
  /// In de, this message translates to:
  /// **'Jetzt starten'**
  String get startNowButton;

  /// Überschrift der Karte für eine bereits laufende Reanimation
  ///
  /// In de, this message translates to:
  /// **'Laufende Reanimation'**
  String get runningCaseTitle;

  /// Beschriftung der Minuten-Auswahl für eine zurückdatierte Startzeit
  ///
  /// In de, this message translates to:
  /// **'Minuten seit Beginn'**
  String get backdateMinutesLabel;

  /// Voreinstellung für eine zurückdatierte Startzeit
  ///
  /// In de, this message translates to:
  /// **'{minutes} min'**
  String backdateChip(int minutes);

  /// Schaltfläche zum Eingeben einer eigenen Startzeit
  ///
  /// In de, this message translates to:
  /// **'Eigene Startzeit'**
  String get customStartzeitButton;

  /// Titel des Dialogs für eine eigene Startzeit
  ///
  /// In de, this message translates to:
  /// **'Eigene Startzeit'**
  String get customStartzeitTitle;

  /// Erklärung im Dialog für eine eigene Startzeit
  ///
  /// In de, this message translates to:
  /// **'Wie lange läuft die Reanimation bereits?'**
  String get customStartzeitDescription;

  /// Beschriftung des Minutenfelds
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get minutesLabel;

  /// Beschriftung des Sekundenfelds
  ///
  /// In de, this message translates to:
  /// **'Sekunden'**
  String get secondsLabel;

  /// Schaltfläche zum Abbrechen eines Dialogs
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancelButton;

  /// Schaltfläche zum Starten eines Falls aus einem Dialog
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get startCaseButton;

  /// Fehlermeldung bei einer leeren oder nullwertigen Startzeit
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Dauer größer als 0 eingeben.'**
  String get invalidBackdateMessage;

  /// Fehlermeldung bei einem ungültigen Sekundenwert
  ///
  /// In de, this message translates to:
  /// **'Sekunden müssen zwischen 0 und 59 liegen.'**
  String get invalidSecondsMessage;

  /// Beschriftung der Anzeige der Fall-Dauer
  ///
  /// In de, this message translates to:
  /// **'Reanimationsdauer'**
  String get elapsedTimeLabel;

  /// Anzeige der Startzeit mit Uhrzeit
  ///
  /// In de, this message translates to:
  /// **'Startzeit {time}'**
  String startzeitValue(String time);

  /// Name der aktiven Phase mit Thoraxkompressionen
  ///
  /// In de, this message translates to:
  /// **'Druckphase'**
  String get phaseDruckphase;

  /// Beschriftung des Kompressionstimers vor Ablauf
  ///
  /// In de, this message translates to:
  /// **'Nächste Analyse'**
  String get nextAnalysisLabel;

  /// Hinweis, dass die Rhythmusanalyse jetzt fällig ist
  ///
  /// In de, this message translates to:
  /// **'Analyse fällig'**
  String get analysisDue;

  /// Anzeige der überfälligen Zeit seit dem Analysezeitpunkt
  ///
  /// In de, this message translates to:
  /// **'+{time}'**
  String overdueTimer(String time);

  /// Name der aktiven Phase mit pausierter Kompression
  ///
  /// In de, this message translates to:
  /// **'Analysephase'**
  String get phaseAnalysephase;

  /// Schaltfläche zum Starten der Analysephase
  ///
  /// In de, this message translates to:
  /// **'Analyse'**
  String get analyseButton;

  /// Beschriftung des Pausenzählers in der Analysephase
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get pauseLabel;

  /// Überfälligkeitshinweis in der Analysephase für AHA 2025
  ///
  /// In de, this message translates to:
  /// **'Pulscheck über {seconds} s – CPR fortsetzen'**
  String pauseOverdueAha(int seconds);

  /// Überfälligkeitshinweis in der Analysephase für ERC 2025
  ///
  /// In de, this message translates to:
  /// **'Peri-Schock-Pause über {seconds} s – CPR fortsetzen'**
  String pauseOverdueErc(int seconds);

  /// Titel des Dialogs für das Rhythmusanalyse-Ergebnis
  ///
  /// In de, this message translates to:
  /// **'Rhythmusanalyse'**
  String get rhythmusanalyseTitle;

  /// Erste Ergebnisstufe: schockbarer Rhythmus
  ///
  /// In de, this message translates to:
  /// **'Schockbar'**
  String get rhythmusanalyseSchockbar;

  /// Erste Ergebnisstufe: nicht schockbarer Rhythmus
  ///
  /// In de, this message translates to:
  /// **'Nicht schockbar'**
  String get rhythmusanalyseNichtSchockbar;

  /// Ergebnis: Wiedererlangung eines Spontankreislaufs
  ///
  /// In de, this message translates to:
  /// **'ROSC'**
  String get rhythmusanalyseRosc;

  /// Ergebnis: Rhythmus unklar
  ///
  /// In de, this message translates to:
  /// **'Unklar'**
  String get rhythmusanalyseUnklar;

  /// Schockbarer Rhythmus: Kammerflimmern
  ///
  /// In de, this message translates to:
  /// **'Kammerflimmern (VF)'**
  String get rhythmusanalyseKammerflimmern;

  /// Schockbarer Rhythmus: pulslose Kammertachykardie
  ///
  /// In de, this message translates to:
  /// **'Pulslose Kammertachykardie (pVT)'**
  String get rhythmusanalysePvt;

  /// Nicht schockbarer Rhythmus: Asystolie
  ///
  /// In de, this message translates to:
  /// **'Asystolie'**
  String get rhythmusanalyseAsystolie;

  /// Nicht schockbarer Rhythmus: elektrische Aktivität ohne Puls
  ///
  /// In de, this message translates to:
  /// **'PEA'**
  String get rhythmusanalysePea;

  /// Rhythmus unbekannt, Ergebnis stammt aus einer AED-Empfehlung
  ///
  /// In de, this message translates to:
  /// **'Unbekannt (AED)'**
  String get rhythmusanalyseUnbekanntAed;

  /// Schaltfläche zum Erfassen des Rhythmusanalyse-Ergebnisses
  ///
  /// In de, this message translates to:
  /// **'Ergebnis erfassen'**
  String get rhythmusanalyseRecordButton;

  /// Beschriftung des erfassten Rhythmusanalyse-Ergebnisses
  ///
  /// In de, this message translates to:
  /// **'Ergebnis'**
  String get rhythmusanalyseRecordedLabel;

  /// Schaltfläche zum Ergänzen einer Notiz am Ergebnis
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen'**
  String get rhythmusanalyseNoteAdd;

  /// Schaltfläche zum Bearbeiten einer vorhandenen Notiz
  ///
  /// In de, this message translates to:
  /// **'Notiz bearbeiten'**
  String get rhythmusanalyseNoteEdit;

  /// Titel des Dialogs für die Notiz zur Rhythmusanalyse
  ///
  /// In de, this message translates to:
  /// **'Notiz zur Rhythmusanalyse'**
  String get rhythmusanalyseNoteTitle;

  /// Beschriftung des optionalen Notizfelds
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get rhythmusanalyseNoteLabel;

  /// Hinweis, dass vor dem Fortsetzen ein Ergebnis erfasst werden muss
  ///
  /// In de, this message translates to:
  /// **'Ergebnis oder Unklar erforderlich'**
  String get rhythmusanalyseRequired;

  /// Schaltfläche zum Beenden der Analysephase
  ///
  /// In de, this message translates to:
  /// **'CPR fortsetzen'**
  String get cprContinueButton;

  /// Schaltfläche zum Überspringen der Rhythmusanalyse
  ///
  /// In de, this message translates to:
  /// **'Analyse überspringen'**
  String get skipAnalysisButton;

  /// Titel des Dialogs zum Überspringen der Rhythmusanalyse
  ///
  /// In de, this message translates to:
  /// **'Analyse überspringen'**
  String get skipAnalysisTitle;

  /// Beschriftung der Grundauswahl beim Überspringen
  ///
  /// In de, this message translates to:
  /// **'Grund (optional)'**
  String get skipAnalysisReasonLabel;

  /// Grund für eine übersprungene Rhythmusanalyse
  ///
  /// In de, this message translates to:
  /// **'Keine Zeit'**
  String get skipReasonNoTime;

  /// Grund für eine übersprungene Rhythmusanalyse: AED übernimmt
  ///
  /// In de, this message translates to:
  /// **'AED übernimmt'**
  String get skipReasonAed;

  /// Sonstiger Grund für eine übersprungene Rhythmusanalyse
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get skipReasonOther;

  /// Überspringen ohne Angabe eines Grundes
  ///
  /// In de, this message translates to:
  /// **'Ohne Angabe'**
  String get skipWithoutReasonButton;

  /// Schaltfläche zum Speichern eines Dialogs
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get saveButton;

  /// Schaltfläche zum Zurückgehen in einem Dialog
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get backButton;

  /// Titel des Einstellungsbildschirms
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// Tooltip des Leitlinien-Chips auf der Startseite
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get settingsOpenTooltip;

  /// Überschrift der Leitlinienprofil-Einstellung
  ///
  /// In de, this message translates to:
  /// **'Leitlinienprofil'**
  String get settingsLeitlinienprofilSection;

  /// Erklärung, dass das Leitlinienprofil pro Fall gespeichert wird
  ///
  /// In de, this message translates to:
  /// **'Gilt für neue Reanimationsfälle. Laufende Fälle behalten ihr Profil.'**
  String get settingsLeitlinienprofilDescription;

  /// Überschrift der Signal-Einstellungen
  ///
  /// In de, this message translates to:
  /// **'Signale'**
  String get settingsAlertsSection;

  /// Einstellung für Vibrationssignale
  ///
  /// In de, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// Erklärung der Vibrationseinstellung
  ///
  /// In de, this message translates to:
  /// **'Vibration bei fälligen Aktionen'**
  String get settingsVibrationDescription;

  /// Einstellung für Tonsignale
  ///
  /// In de, this message translates to:
  /// **'Ton'**
  String get settingsSound;

  /// Erklärung der Toneinstellung
  ///
  /// In de, this message translates to:
  /// **'Ton bei fälligen Aktionen'**
  String get settingsSoundDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
