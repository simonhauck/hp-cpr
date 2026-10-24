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
