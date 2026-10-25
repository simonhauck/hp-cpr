# HP-CPR Companion

Domain language for the prehospital adult ALS timekeeping app. The UI is German; the definitions are English so the code and docs use one shared vocabulary.

## Language

**Zeitnehmer**:
The dedicated team role that operates the app, watches the timers, and tells the team when an action is due.
_Avoid_: Timekeeper, timer operator

**Reanimationsfall**:
One resuscitation case, from the first compression to the end of the case.
_Avoid_: Session, run, event

**Startzeit**:
The corrected time zero of a case, set from the first compression; it can be backdated on the start screen.
_Avoid_: Start timestamp, begin time

**Reanimationsdauer**:
The time from the Startzeit to now, shown on the running case screen.
_Avoid_: Case time, elapsed time

**Leitlinienprofil**:
The AHA 2025 or ERC 2025 timing baseline selected in settings and snapshotted for each Reanimationsfall.
_Avoid_: Guideline profile, guideline standard

**Reanimationsphase**:
The current part of a Reanimationsfall: Druckphase or Analysephase.
_Avoid_: Case phase, CPR phase

**Druckphase**:
The period in which chest compressions run and the 2-minute compression timer counts down.
_Avoid_: Compression phase, CPR phase

**DruckphaseNeustart**:
The manual reset of the current Druckphase to a fresh 2-minute cycle after an interruption; it starts no new Reanimationsabschnitt and does not reset the Adrenalin or Amiodaron Zeitfenster.
_Avoid_: Cycle restart, timer reset

**Analysephase**:
The paused period in which the team performs the rhythm analysis and may deliver a shock; the compression timer is stopped.
_Avoid_: Analysis phase, rhythm phase

**Schockbar**:
An analysis result indicating a shockable rhythm (VF or pVT), or an AED shock advisory when the rhythm itself is unknown.
_Avoid_: Shockable rhythm in UI copy

**Nicht schockbar**:
An analysis result indicating a non-shockable rhythm (asystole or PEA), or an AED no-shock advisory when the rhythm itself is unknown.
_Avoid_: Non-shockable rhythm in UI copy

**Reanimationsabschnitt**:
A continuous period of resuscitation within a case, from first compression or rearrest until ROSC or case end.
_Avoid_: Arrest segment, run

**Reanimationswiederbeginn**:
The event that starts a new resuscitation segment after ROSC when the patient rearrests.
_Avoid_: Restart, rearrest in UI copy

**Einsatzlog**:
The persistent list of completed or discarded resuscitation cases; the only place where a case can be deleted.
_Avoid_: History, archive, mission list

**Verworfen**:
A case status for a mis-started or abandoned case; the case remains in the Einsatzlog until deliberately deleted.
_Avoid_: Deleted, cancelled

**Messwerte**:
Timestamped patient observations recorded alongside a case, such as temperature, blood sugar, blood pressure, and heart rate.
_Avoid_: Vitals, measurements in UI copy

**AED**:
Automated external defibrillator. AED use is compatible with the normal timing model; no separate app mode is required.
_Avoid_: Defibrillator when the manual device is meant

**Rhythmusanalyse**:
The paused assessment of the cardiac rhythm at the end of a compression cycle; it records a result and may lead to a shock.
_Avoid_: Analysis, rhythm check, rhythm control

**Kompressionswechsel**:
The handover of chest compressions from one rescuer to another; it often happens around the analysis pause.
_Avoid_: Switch, compressor change, person change

**Adrenalin**:
The drug epinephrine, recorded as an IV/IO dose in the adult ALS protocol.
_Avoid_: Epinephrine in UI copy, adrenaline

**Amiodaron**:
The antiarrhythmic drug considered for refractory VF/pVT, recorded only when actually administered.
_Avoid_: Amiodarone in UI copy

**Schock**:
A defibrillation event recorded with its time and shock count; shock energy is optional.
_Avoid_: Defibrillation in UI copy, shock delivery

**Zeitfenster**:
The interval in which a time-based drug dose should be given, for example 3–5 minutes for adrenaline.
_Avoid_: Timer, countdown

**Gabe**:
A recorded administration of a drug, with its time and dose.
_Avoid_: Dose, administration

**ROSC**:
Return of spontaneous circulation, recorded only when observed. It is optional and ends the current resuscitation segment, but not necessarily the case.
_Avoid_: Pulse return, circulation restored
