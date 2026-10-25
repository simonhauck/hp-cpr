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

  @override
  String get phaseAnalysephase => 'Analysephase';

  @override
  String get analyseButton => 'Analyse';

  @override
  String get pauseLabel => 'Pause';

  @override
  String pauseOverdueAha(int seconds) {
    return 'Pulscheck über $seconds s – CPR fortsetzen';
  }

  @override
  String pauseOverdueErc(int seconds) {
    return 'Peri-Schock-Pause über $seconds s – CPR fortsetzen';
  }

  @override
  String get rhythmusanalyseTitle => 'Rhythmusanalyse';

  @override
  String get rhythmusanalyseSchockbar => 'Schockbar';

  @override
  String get rhythmusanalyseNichtSchockbar => 'Nicht schockbar';

  @override
  String get rhythmusanalyseRosc => 'ROSC';

  @override
  String get rhythmusanalyseUnklar => 'Unklar';

  @override
  String get rhythmusanalyseKammerflimmern => 'Kammerflimmern (VF)';

  @override
  String get rhythmusanalysePvt => 'Pulslose Kammertachykardie (pVT)';

  @override
  String get rhythmusanalyseAsystolie => 'Asystolie';

  @override
  String get rhythmusanalysePea => 'PEA';

  @override
  String get rhythmusanalyseUnbekanntAed => 'Unbekannt (AED)';

  @override
  String get rhythmusanalyseRecordButton => 'Ergebnis erfassen';

  @override
  String get rhythmusanalyseRecordedLabel => 'Ergebnis';

  @override
  String get rhythmusanalyseNoteAdd => 'Notiz hinzufügen';

  @override
  String get rhythmusanalyseNoteEdit => 'Notiz bearbeiten';

  @override
  String get rhythmusanalyseNoteTitle => 'Notiz zur Rhythmusanalyse';

  @override
  String get rhythmusanalyseNoteLabel => 'Notiz (optional)';

  @override
  String get rhythmusanalyseRequired => 'Ergebnis oder Unklar erforderlich';

  @override
  String get cprContinueButton => 'CPR fortsetzen';

  @override
  String get skipAnalysisButton => 'Analyse überspringen';

  @override
  String get skipAnalysisTitle => 'Analyse überspringen';

  @override
  String get skipAnalysisReasonLabel => 'Grund (optional)';

  @override
  String get skipReasonNoTime => 'Keine Zeit';

  @override
  String get skipReasonAed => 'AED übernimmt';

  @override
  String get skipReasonOther => 'Sonstiges';

  @override
  String get skipWithoutReasonButton => 'Ohne Angabe';

  @override
  String schockButton(int count) {
    return 'Schock ($count)';
  }

  @override
  String schockRecorded(int count) {
    return 'Schock $count erfasst';
  }

  @override
  String schockRecordedWithEnergy(int count, int energie) {
    return 'Schock $count erfasst · $energie J';
  }

  @override
  String get schockRecordedLabel => 'Schock erfasst';

  @override
  String get schockEnergyAction => 'Energie';

  @override
  String get schockUndoAction => 'Rückgängig';

  @override
  String get schockEnergyTitle => 'Schockenergie';

  @override
  String get schockEnergyLabel => 'Energie (J)';

  @override
  String get schockEnergyInvalid =>
      'Bitte eine ganze Zahl größer als 0 eingeben.';

  @override
  String get adrenalinLabel => 'Adrenalin';

  @override
  String get adrenalinRecordButton => 'Gabe';

  @override
  String get adrenalinFirstDoseDue => 'Erste Gabe fällig';

  @override
  String get adrenalinNotDue => 'Noch nicht fällig';

  @override
  String get adrenalinStateWaiting => 'wartet';

  @override
  String get adrenalinStateDue => 'fällig';

  @override
  String get adrenalinStateOverdue => 'überfällig';

  @override
  String adrenalinLastDose(String time) {
    return 'Letzte Gabe $time';
  }

  @override
  String get saveButton => 'Speichern';

  @override
  String get backButton => 'Zurück';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsOpenTooltip => 'Einstellungen öffnen';

  @override
  String get settingsLeitlinienprofilSection => 'Leitlinienprofil';

  @override
  String get settingsLeitlinienprofilDescription =>
      'Gilt für neue Reanimationsfälle. Laufende Fälle behalten ihr Profil.';

  @override
  String get settingsAlertsSection => 'Signale';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationDescription => 'Vibration bei fälligen Aktionen';

  @override
  String get settingsSound => 'Ton';

  @override
  String get settingsSoundDescription => 'Ton bei fälligen Aktionen';

  @override
  String get menuTitle => 'Menü';

  @override
  String get menuOpenTooltip => 'Menü öffnen';

  @override
  String get legalTitle => 'Rechtliches';

  @override
  String get legalDescription => 'Rechtliche Informationen zu HP-CPR.';

  @override
  String get legalLicensesTile => 'Lizenzen';

  @override
  String get legalLicensesDescription =>
      'Lizenztexte der App und ihrer Bibliotheken';

  @override
  String get licensesLegalese => 'MIT-Lizenz · © 2026 Simon Hauck';

  @override
  String get aboutTitle => 'Über';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'Begleit-App für den High-Performance-CPR-Standard';

  @override
  String get aboutCopyright => '© 2026 Simon Hauck';

  @override
  String get amiodaronLabel => 'Amiodaron';

  @override
  String amiodaronHint(int dosis) {
    return 'Amiodaron erwägen – $dosis mg';
  }

  @override
  String get amiodaronGiveButton => 'Gegeben';

  @override
  String get amiodaronDismissButton => 'Nicht jetzt';

  @override
  String amiodaronLastDose(String time) {
    return 'Letzte Gabe $time';
  }

  @override
  String get roscDescription => 'Kreislauf zurückgekehrt';

  @override
  String get resumeResuscitationButton => 'Reanimation wieder aufnehmen';

  @override
  String get endCaseButton => 'Fall beenden';

  @override
  String get endCaseTitle => 'Fall beenden';

  @override
  String get endCaseReasonLabel => 'Grund';

  @override
  String get endReasonHandover => 'Übergabe';

  @override
  String get endReasonAbort => 'Abbruch';

  @override
  String get endReasonOther => 'Sonstiges';

  @override
  String get summaryTitle => 'Zusammenfassung';

  @override
  String get summaryCaseEnded => 'Reanimationsfall beendet';

  @override
  String get summaryCprDuration => 'CPR-Dauer';

  @override
  String get summaryStartzeit => 'Startzeit';

  @override
  String get summaryEndzeit => 'Endzeit';

  @override
  String get summaryEndReason => 'Grund';

  @override
  String get summaryShocks => 'Schocks';

  @override
  String get summaryEvents => 'Ereignisse';

  @override
  String get summaryNotes => 'Notizen';

  @override
  String get summaryNoNotes => 'Keine Notizen';

  @override
  String get eventCaseStart => 'Reanimationsfall gestartet';

  @override
  String eventSchock(int count) {
    return 'Schock $count';
  }

  @override
  String eventSchockWithEnergy(int count, int energie) {
    return 'Schock $count · $energie J';
  }

  @override
  String eventSchockUndone(int count) {
    return 'Schock $count zurückgenommen';
  }

  @override
  String eventAdrenalin(int dosis) {
    return 'Adrenalin $dosis mg';
  }

  @override
  String eventAmiodaron(int dosis) {
    return 'Amiodaron $dosis mg';
  }

  @override
  String eventRhythmusanalyse(String ergebnis) {
    return 'Rhythmusanalyse: $ergebnis';
  }

  @override
  String get eventRhythmusanalyseSkipped => 'Rhythmusanalyse übersprungen';

  @override
  String eventRhythmusanalyseSkippedWithReason(String grund) {
    return 'Rhythmusanalyse übersprungen: $grund';
  }

  @override
  String get eventRosc => 'ROSC';

  @override
  String get eventResuscitationResumed => 'Reanimationswiederbeginn';

  @override
  String eventCaseEnded(String grund) {
    return 'Fall beendet: $grund';
  }

  @override
  String get eventCaseDiscarded => 'Fall verworfen';

  @override
  String get verworfenLabel => 'Verworfen';

  @override
  String get summaryCaseDiscarded => 'Reanimationsfall verworfen';

  @override
  String get activeCaseTitle => 'Aktiver Reanimationsfall';

  @override
  String get activeCaseDescription =>
      'Der Reanimationsfall läuft bereits. Setze ihn fort, um weiterzutimen.';

  @override
  String get resumeCaseButton => 'Fortsetzen';

  @override
  String get discardCaseButton => 'Fall verwerfen';

  @override
  String get discardCaseTitle => 'Reanimationsfall verwerfen?';

  @override
  String get discardCaseDescription =>
      'Der Fall verlässt den aktiven Ablauf und bleibt im Einsatzlog.';

  @override
  String get discardCaseConfirm => 'Verwerfen';

  @override
  String get einsatzlogTitle => 'Einsatzlog';

  @override
  String get einsatzlogEmpty => 'Noch keine abgeschlossenen Reanimationsfälle';

  @override
  String einsatzlogEntryTitle(String time) {
    return 'Reanimationsfall $time';
  }

  @override
  String einsatzlogEntrySubtitle(String cpr, String profil) {
    return 'CPR $cpr · $profil';
  }

  @override
  String get deleteCaseTooltip => 'Reanimationsfall löschen';

  @override
  String get deleteCaseTitle => 'Reanimationsfall löschen?';

  @override
  String get deleteCaseDescription =>
      'Der Reanimationsfall wird dauerhaft gelöscht.';

  @override
  String get deleteButton => 'Löschen';
}
