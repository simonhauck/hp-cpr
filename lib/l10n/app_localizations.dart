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
  /// **'Pause über {seconds} s – CPR fortsetzen'**
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

  /// Schaltfläche zum Überspringen der Rhythmusanalyse
  ///
  /// In de, this message translates to:
  /// **'Analyse überspringen'**
  String get skipAnalysisButton;

  /// Schaltfläche zum Erfassen eines Schocks mit der aktuellen Anzahl
  ///
  /// In de, this message translates to:
  /// **'Schock ({count})'**
  String schockButton(int count);

  /// Beschriftung des Adrenalin-Zeitfensters
  ///
  /// In de, this message translates to:
  /// **'Adrenalin'**
  String get adrenalinLabel;

  /// Schaltfläche zum Erfassen einer Adrenalin-Gabe
  ///
  /// In de, this message translates to:
  /// **'Gabe'**
  String get adrenalinRecordButton;

  /// Hinweis, dass die erste Adrenalin-Gabe jetzt fällig ist
  ///
  /// In de, this message translates to:
  /// **'Erste Gabe fällig'**
  String get adrenalinFirstDoseDue;

  /// Hinweis, dass die erste Adrenalin-Gabe noch nicht fällig ist
  ///
  /// In de, this message translates to:
  /// **'Noch nicht fällig'**
  String get adrenalinNotDue;

  /// Zustand des Adrenalin-Zeitfensters vor 3 Minuten
  ///
  /// In de, this message translates to:
  /// **'wartet'**
  String get adrenalinStateWaiting;

  /// Zustand des Adrenalin-Zeitfensters zwischen 3 und 5 Minuten
  ///
  /// In de, this message translates to:
  /// **'fällig'**
  String get adrenalinStateDue;

  /// Zustand des Adrenalin-Zeitfensters nach 5 Minuten
  ///
  /// In de, this message translates to:
  /// **'überfällig'**
  String get adrenalinStateOverdue;

  /// Zeitpunkt der letzten Adrenalin-Gabe
  ///
  /// In de, this message translates to:
  /// **'Letzte Gabe {time}'**
  String adrenalinLastDose(String time);

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

  /// Überschrift im App-Menü
  ///
  /// In de, this message translates to:
  /// **'Menü'**
  String get menuTitle;

  /// Tooltip der Menü-Schaltfläche
  ///
  /// In de, this message translates to:
  /// **'Menü öffnen'**
  String get menuOpenTooltip;

  /// Titel der Seite mit rechtlichen Informationen
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get legalTitle;

  /// Einleitung auf der Rechtliches-Seite
  ///
  /// In de, this message translates to:
  /// **'Rechtliche Informationen zu HP-CPR.'**
  String get legalDescription;

  /// Eintrag zu den Lizenztexten
  ///
  /// In de, this message translates to:
  /// **'Lizenzen'**
  String get legalLicensesTile;

  /// Erklärung des Lizenzen-Eintrags
  ///
  /// In de, this message translates to:
  /// **'Lizenztexte der App und ihrer Bibliotheken'**
  String get legalLicensesDescription;

  /// Copyright-Hinweis auf der Lizenzseite
  ///
  /// In de, this message translates to:
  /// **'MIT-Lizenz · © 2026 Simon Hauck'**
  String get licensesLegalese;

  /// Titel der Über-Seite
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get aboutTitle;

  /// Anzeige der installierten Version
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// Kurzbeschreibung der App auf der Über-Seite
  ///
  /// In de, this message translates to:
  /// **'Begleit-App für den High-Performance-CPR-Standard'**
  String get aboutDescription;

  /// Copyright-Hinweis auf der Über-Seite
  ///
  /// In de, this message translates to:
  /// **'© 2026 Simon Hauck'**
  String get aboutCopyright;

  /// Beschriftung des Amiodaron-Hinweises
  ///
  /// In de, this message translates to:
  /// **'Amiodaron'**
  String get amiodaronLabel;

  /// Hinweis auf eine mögliche Amiodaron-Gabe
  ///
  /// In de, this message translates to:
  /// **'Amiodaron erwägen – {dosis} mg'**
  String amiodaronHint(int dosis);

  /// Schaltfläche zum Erfassen einer Amiodaron-Gabe
  ///
  /// In de, this message translates to:
  /// **'Gegeben'**
  String get amiodaronGiveButton;

  /// Schaltfläche zum Ausblenden des Amiodaron-Hinweises
  ///
  /// In de, this message translates to:
  /// **'Nicht jetzt'**
  String get amiodaronDismissButton;

  /// Zeitpunkt der letzten Amiodaron-Gabe
  ///
  /// In de, this message translates to:
  /// **'Letzte Gabe {time}'**
  String amiodaronLastDose(String time);

  /// Erklärung des ROSC-Zustands auf dem laufenden Fall
  ///
  /// In de, this message translates to:
  /// **'Kreislauf zurückgekehrt'**
  String get roscDescription;

  /// Schaltfläche zum Start eines neuen Reanimationsabschnitts nach ROSC
  ///
  /// In de, this message translates to:
  /// **'Reanimation wieder aufnehmen'**
  String get resumeResuscitationButton;

  /// Schaltfläche zum Beenden des Reanimationsfalls
  ///
  /// In de, this message translates to:
  /// **'Fall beenden'**
  String get endCaseButton;

  /// Titel des Dialogs zum Beenden des Reanimationsfalls
  ///
  /// In de, this message translates to:
  /// **'Fall beenden'**
  String get endCaseTitle;

  /// Beschriftung der Grundauswahl beim Beenden
  ///
  /// In de, this message translates to:
  /// **'Grund'**
  String get endCaseReasonLabel;

  /// Grund für das Beenden: Übergabe
  ///
  /// In de, this message translates to:
  /// **'Übergabe'**
  String get endReasonHandover;

  /// Grund für das Beenden: Abbruch
  ///
  /// In de, this message translates to:
  /// **'Abbruch'**
  String get endReasonAbort;

  /// Sonstiger Grund für das Beenden
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get endReasonOther;

  /// Titel der Zusammenfassung eines beendeten Reanimationsfalls
  ///
  /// In de, this message translates to:
  /// **'Zusammenfassung'**
  String get summaryTitle;

  /// Überschrift der Zusammenfassung
  ///
  /// In de, this message translates to:
  /// **'Reanimationsfall beendet'**
  String get summaryCaseEnded;

  /// Beschriftung der gesamten CPR-Dauer
  ///
  /// In de, this message translates to:
  /// **'CPR-Dauer'**
  String get summaryCprDuration;

  /// Beschriftung der Startzeit in der Zusammenfassung
  ///
  /// In de, this message translates to:
  /// **'Startzeit'**
  String get summaryStartzeit;

  /// Beschriftung der Endzeit in der Zusammenfassung
  ///
  /// In de, this message translates to:
  /// **'Endzeit'**
  String get summaryEndzeit;

  /// Beschriftung des Beendigungsgrunds
  ///
  /// In de, this message translates to:
  /// **'Grund'**
  String get summaryEndReason;

  /// Beschriftung der Schockanzahl in der Zusammenfassung
  ///
  /// In de, this message translates to:
  /// **'Schocks'**
  String get summaryShocks;

  /// Überschrift der Ereignisliste in der Zusammenfassung
  ///
  /// In de, this message translates to:
  /// **'Ereignisse'**
  String get summaryEvents;

  /// Überschrift der Notizen in der Zusammenfassung
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get summaryNotes;

  /// Hinweis, dass keine Notizen erfasst wurden
  ///
  /// In de, this message translates to:
  /// **'Keine Notizen'**
  String get summaryNoNotes;

  /// Ereignis: Beginn des Reanimationsfalls
  ///
  /// In de, this message translates to:
  /// **'Reanimationsfall gestartet'**
  String get eventCaseStart;

  /// Ereignis: Schock ohne Energie
  ///
  /// In de, this message translates to:
  /// **'Schock {count}'**
  String eventSchock(int count);

  /// Ereignis: Schock mit Energie
  ///
  /// In de, this message translates to:
  /// **'Schock {count} · {energie} J'**
  String eventSchockWithEnergy(int count, int energie);

  /// Ereignis: Adrenalin-Gabe
  ///
  /// In de, this message translates to:
  /// **'Adrenalin {dosis} mg'**
  String eventAdrenalin(int dosis);

  /// Ereignis: Amiodaron-Gabe
  ///
  /// In de, this message translates to:
  /// **'Amiodaron {dosis} mg'**
  String eventAmiodaron(int dosis);

  /// Ereignis: Ergebnis einer Rhythmusanalyse
  ///
  /// In de, this message translates to:
  /// **'Rhythmusanalyse: {ergebnis}'**
  String eventRhythmusanalyse(String ergebnis);

  /// Ereignis: Rhythmusanalyse übersprungen
  ///
  /// In de, this message translates to:
  /// **'Rhythmusanalyse übersprungen'**
  String get eventRhythmusanalyseSkipped;

  /// Ereignis: Manueller Neustart der Druckphase
  ///
  /// In de, this message translates to:
  /// **'Druckphase neu gestartet'**
  String get eventDruckphaseRestarted;

  /// Ereignis: Wiedererlangung eines Spontankreislaufs
  ///
  /// In de, this message translates to:
  /// **'ROSC'**
  String get eventRosc;

  /// Ereignis: Wiederbeginn der Reanimation nach ROSC
  ///
  /// In de, this message translates to:
  /// **'Reanimationswiederbeginn'**
  String get eventResuscitationResumed;

  /// Ereignis: Ende des Reanimationsfalls mit Grund
  ///
  /// In de, this message translates to:
  /// **'Fall beendet: {grund}'**
  String eventCaseEnded(String grund);

  /// Ereignis: Reanimationsfall als Verworfen markiert
  ///
  /// In de, this message translates to:
  /// **'Fall verworfen'**
  String get eventCaseDiscarded;

  /// Status eines verworfenen Reanimationsfalls
  ///
  /// In de, this message translates to:
  /// **'Verworfen'**
  String get verworfenLabel;

  /// Überschrift der Zusammenfassung eines verworfenen Reanimationsfalls
  ///
  /// In de, this message translates to:
  /// **'Reanimationsfall verworfen'**
  String get summaryCaseDiscarded;

  /// Überschrift der Karte für einen gespeicherten aktiven Fall
  ///
  /// In de, this message translates to:
  /// **'Aktiver Reanimationsfall'**
  String get activeCaseTitle;

  /// Erklärung der Fortsetzen-Karte
  ///
  /// In de, this message translates to:
  /// **'Der Reanimationsfall läuft bereits. Setze ihn fort, um weiterzutimen.'**
  String get activeCaseDescription;

  /// Schaltfläche zum Fortsetzen des gespeicherten aktiven Falls
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get resumeCaseButton;

  /// Schaltfläche zum Verwerfen des Reanimationsfalls
  ///
  /// In de, this message translates to:
  /// **'Fall verwerfen'**
  String get discardCaseButton;

  /// Titel der Bestätigung zum Verwerfen
  ///
  /// In de, this message translates to:
  /// **'Reanimationsfall verwerfen?'**
  String get discardCaseTitle;

  /// Erklärung der Folgen des Verwerfens
  ///
  /// In de, this message translates to:
  /// **'Der Fall verlässt den aktiven Ablauf und bleibt im Einsatzlog.'**
  String get discardCaseDescription;

  /// Bestätigung des Verwerfens
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discardCaseConfirm;

  /// Titel des Einsatzlogs
  ///
  /// In de, this message translates to:
  /// **'Einsatzlog'**
  String get einsatzlogTitle;

  /// Leerer Zustand des Einsatzlogs
  ///
  /// In de, this message translates to:
  /// **'Noch keine abgeschlossenen Reanimationsfälle'**
  String get einsatzlogEmpty;

  /// Titel eines Einsatzlog-Eintrags
  ///
  /// In de, this message translates to:
  /// **'Reanimationsfall {time}'**
  String einsatzlogEntryTitle(String time);

  /// Zusammenfassung eines Einsatzlog-Eintrags
  ///
  /// In de, this message translates to:
  /// **'CPR {cpr} · {profil}'**
  String einsatzlogEntrySubtitle(String cpr, String profil);

  /// Tooltip der Löschen-Schaltfläche im Einsatzlog
  ///
  /// In de, this message translates to:
  /// **'Reanimationsfall löschen'**
  String get deleteCaseTooltip;

  /// Titel der Löschbestätigung
  ///
  /// In de, this message translates to:
  /// **'Reanimationsfall löschen?'**
  String get deleteCaseTitle;

  /// Erklärung der Folgen des Löschens
  ///
  /// In de, this message translates to:
  /// **'Der Reanimationsfall wird dauerhaft gelöscht.'**
  String get deleteCaseDescription;

  /// Bestätigung des Löschens
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get deleteButton;

  /// Titel der Messwerte-Seite und Menüeintrag
  ///
  /// In de, this message translates to:
  /// **'Messwerte'**
  String get messwerteTitle;

  /// Leerer Zustand der Messwerte
  ///
  /// In de, this message translates to:
  /// **'Noch keine Messwerte'**
  String get messwerteEmpty;

  /// Schaltfläche zum Öffnen der Messwerte aus der Zusammenfassung
  ///
  /// In de, this message translates to:
  /// **'Messwerte öffnen'**
  String get messwerteOpenButton;

  /// Schaltfläche zum Erfassen eines Messwerts
  ///
  /// In de, this message translates to:
  /// **'Messwert erfassen'**
  String get messwertErfassenButton;

  /// Titel des Dialogs für einen Messwert
  ///
  /// In de, this message translates to:
  /// **'Messwert erfassen'**
  String get messwertErfassenTitle;

  /// Beschriftung der Messwert-Auswahl
  ///
  /// In de, this message translates to:
  /// **'Messwert'**
  String get messwertTypLabel;

  /// Name des Temperatur-Messwerts
  ///
  /// In de, this message translates to:
  /// **'Temperatur'**
  String get messwertTemperatur;

  /// Name des Blutzucker-Messwerts
  ///
  /// In de, this message translates to:
  /// **'Blutzucker'**
  String get messwertBlutzucker;

  /// Name des Blutdruck-Messwerts
  ///
  /// In de, this message translates to:
  /// **'Blutdruck'**
  String get messwertBlutdruck;

  /// Name des Herzfrequenz-Messwerts
  ///
  /// In de, this message translates to:
  /// **'Herzfrequenz'**
  String get messwertHerzfrequenz;

  /// Eingabefeld für die Temperatur
  ///
  /// In de, this message translates to:
  /// **'Temperatur (°C)'**
  String get messwertTemperaturLabel;

  /// Eingabefeld für den Blutzucker
  ///
  /// In de, this message translates to:
  /// **'Blutzucker (mg/dL)'**
  String get messwertBlutzuckerLabel;

  /// Eingabefeld für den systolischen Blutdruck
  ///
  /// In de, this message translates to:
  /// **'Systolisch (mmHg)'**
  String get messwertSystolischLabel;

  /// Eingabefeld für den diastolischen Blutdruck
  ///
  /// In de, this message translates to:
  /// **'Diastolisch (mmHg)'**
  String get messwertDiastolischLabel;

  /// Eingabefeld für die Herzfrequenz
  ///
  /// In de, this message translates to:
  /// **'Herzfrequenz (/min)'**
  String get messwertHerzfrequenzLabel;

  /// Anzeige einer Temperatur
  ///
  /// In de, this message translates to:
  /// **'{value} °C'**
  String messwertTemperaturValue(String value);

  /// Anzeige eines Blutzuckerwerts
  ///
  /// In de, this message translates to:
  /// **'{value} mg/dL'**
  String messwertBlutzuckerValue(int value);

  /// Anzeige eines Blutdruckwerts
  ///
  /// In de, this message translates to:
  /// **'{systolisch}/{diastolisch} mmHg'**
  String messwertBlutdruckValue(int systolisch, int diastolisch);

  /// Anzeige einer Herzfrequenz
  ///
  /// In de, this message translates to:
  /// **'{value} /min'**
  String messwertHerzfrequenzValue(int value);

  /// Fehlermeldung bei einem ungültigen Messwert
  ///
  /// In de, this message translates to:
  /// **'Bitte einen gültigen Wert eingeben.'**
  String get messwertInvalid;

  /// Fehlermeldung bei vertauschten Blutdruckwerten
  ///
  /// In de, this message translates to:
  /// **'Systolisch muss größer als diastolisch sein.'**
  String get messwertBloodPressureInvalid;

  /// Beschriftung eines Notizfelds
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get noteLabel;

  /// Beschriftung eines optionalen Notizfelds
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get noteOptionalLabel;

  /// Schaltfläche zum Erfassen einer freien Notiz
  ///
  /// In de, this message translates to:
  /// **'Notiz erfassen'**
  String get notizErfassenButton;

  /// Titel des Dialogs für eine freie Notiz
  ///
  /// In de, this message translates to:
  /// **'Notiz erfassen'**
  String get notizErfassenTitle;

  /// Fehlermeldung bei einer leeren Notiz
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Notiz eingeben.'**
  String get notizEmptyInvalid;

  /// Überschrift der freien Notizen
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get notizenTitle;

  /// Leerer Zustand der freien Notizen
  ///
  /// In de, this message translates to:
  /// **'Noch keine Notizen'**
  String get notizenEmpty;

  /// Ereignis: erfasster Messwert
  ///
  /// In de, this message translates to:
  /// **'{typ}: {value}'**
  String eventMesswert(String typ, String value);

  /// Ereignis: erfasste freie Notiz
  ///
  /// In de, this message translates to:
  /// **'Notiz: {text}'**
  String eventNotiz(String text);

  /// Version mit Buildnummer
  ///
  /// In de, this message translates to:
  /// **'{version} (Build {build})'**
  String versionWithBuild(String version, String build);
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
