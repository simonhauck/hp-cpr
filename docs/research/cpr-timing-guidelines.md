# CPR timing guidance for an adult cardiac arrest companion app

**Status:** design research, **not medical advice**. This note summarises published American Heart Association (AHA) 2025 and European Resuscitation Council (ERC) 2025 guidance as two selectable timing baselines, so that the domain model and UI can be designed against a citable baseline. It is not a protocol and must not be used to treat patients.

**Research date:** 2026-10-24
**Guideline baseline:** AHA 2025 and ERC 2025 are both first-class profiles; the app selects one per case in its settings. *2025 American Heart Association Guidelines for Cardiopulmonary Resuscitation and Emergency Cardiovascular Care*, published 21 October 2025 in *Circulation* volume 152, supplement 2; *European Resuscitation Council Guidelines 2025*, launched 22 October 2025 and published in *Resuscitation* volume 215, supplement 1.
**Population in scope:** adults in cardiac arrest (VF/pVT, asystole, PEA), in-hospital and out-of-hospital.
**Out of scope:** paediatrics, neonatal, pregnancy, special circumstances (Part 10), peri-arrest tachycardias/bradycardias, and national or institutional protocols. The note documents two selectable profiles and does not blend them into one protocol.

---

## 1. Scope and source edition

### 1.1 Which edition is current

| Question | Finding | Source |
| --- | --- | --- |
| Current AHA edition | 2025 Guidelines for CPR and ECC, published 2025-10-21 | [Crossref record, Part 9](https://doi.org/10.1161/CIR.0000000000001376) |
| Current ERC edition | ERC Guidelines 2025, launched 2025-10-22; this supersedes ERC 2021. No ERC 2026 edition or 2026 focused update was listed on the ERC guidelines hub on 2026-10-24. | [ERC Guidelines 2025](https://www.erc.edu/science-research/guidelines/guidelines-2025/guidelines-2025-english/) |
| ERC corrigendum | A corrigendum to the ERC 2025 ALS guideline was published 2026-09-16. It corrects two reference citations and an ibutilide dose; it does not change any timing, drug or target used in this note. | [Corrigendum, doi:10.1016/j.resuscitation.2026.111313](https://doi.org/10.1016/j.resuscitation.2026.111313) |
| Is there a later AHA focused update? | The AHA "Guideline and Focused Update Highlights" index listed the 2025 Resuscitation Guideline Highlights and focused updates only up to 2024 (drowning) when checked on 2026-10-24. No 2026 adult ALS focused update was listed. | [AHA Guidelines Updates and Highlights](https://cpr.heart.org/en/resuscitation-science/guidelines-updates-and-highlights) |
| Relationship between the editions | Both were released in October 2025 and both are based on the 2025 ILCOR CoSTR, but the AHA and ERC writing groups made different operational choices in several places. | [ERC 2025 Executive Summary](https://www.erc.edu/media/ad5dtph1/gl2025-01-exec-e.pdf); [AHA Part 1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary) |
| Can guidance change between editions? | Yes. The AHA states that it publishes focused updates between the formal 5-yearly Guidelines because ILCOR moved to continuous evidence evaluation. | [Part 1, Introduction](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary) |
| Implication for the app | Expose the guideline standard as a settings choice, store the selected edition/version with every protocol and every case, and treat all timings as configurable data, not constants in code. | Design inference |

**Caveat on currency:** the checks above are negative checks of the AHA and ERC index pages on one date. They establish that no later edition or listed focused update exists; they cannot prove that nothing was published elsewhere. Re-check before clinical sign-off.

### 1.2 Documents used

| Short name | Document | Citation |
| --- | --- | --- |
| **Part 7 (BLS)** | Part 7: Adult Basic Life Support | *Circulation*. 2025;152(suppl 2):S448–S478. [doi:10.1161/CIR.0000000000001369](https://doi.org/10.1161/CIR.0000000000001369) |
| **Part 9 (ALS)** | Part 9: Adult Advanced Life Support | *Circulation*. 2025;152(suppl 2):S538–S577. [doi:10.1161/CIR.0000000000001376](https://doi.org/10.1161/CIR.0000000000001376) |
| **Part 11 (PCAC)** | Part 11: Post–Cardiac Arrest Care | *Circulation*. 2025;152(suppl 2):S673–S718. [doi:10.1161/CIR.0000000000001375](https://doi.org/10.1161/CIR.0000000000001375) |
| **Part 1** | Part 1: Executive Summary | [cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary) |
| **Algorithm** | 2025 Adult Cardiac Arrest Algorithm (Figure 2), PDF | [Algorithm-ACLS-CA-250527.pdf](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| **Algorithm description** | AHA accessible long description of the same algorithm (box-by-box text) | [Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf) |
| **ERC ALS** | European Resuscitation Council Guidelines 2025: Adult Advanced Life Support | *Resuscitation*. 2025;215(suppl 1):110769. [doi:10.1016/j.resuscitation.2025.110769](https://doi.org/10.1016/j.resuscitation.2025.110769); [ERC PDF](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| **ERC BLS** | European Resuscitation Council Guidelines 2025: Adult Basic Life Support | *Resuscitation*. 2025;215(suppl 1):110771. [doi:10.1016/j.resuscitation.2025.110771](https://doi.org/10.1016/j.resuscitation.2025.110771); [ERC PDF](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf) |
| **ERC post-ROSC** | European Resuscitation Council and European Society of Intensive Care Medicine Guidelines 2025: Post-Resuscitation Care | *Resuscitation*. 2025;215(suppl 1):110809. [doi:10.1016/j.resuscitation.2025.110809](https://doi.org/10.1016/j.resuscitation.2025.110809); [ERC PDF](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf) |
| **ERC Executive Summary** | European Resuscitation Council Guidelines 2025: Executive Summary | *Resuscitation*. 2025;215(suppl 1):110770. [doi:10.1016/j.resuscitation.2025.110770](https://doi.org/10.1016/j.resuscitation.2025.110770); [ERC PDF](https://www.erc.edu/media/ad5dtph1/gl2025-01-exec-e.pdf) |
| **ERC ALS algorithm** | Advanced Life Support algorithm (Figure 2) | In [ERC ALS PDF](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), p. 5 |
| **ERC corrigendum** | Corrigendum to the ERC 2025 ALS guideline | *Resuscitation*. 2026;229:111313. [doi:10.1016/j.resuscitation.2026.111313](https://doi.org/10.1016/j.resuscitation.2026.111313) |
| **2020 Part 3** | Part 3: Adult Basic and Advanced Life Support (for edition comparison only) | *Circulation*. 2020;142(suppl 2):S366–S468. [doi:10.1161/CIR.0000000000000916](https://doi.org/10.1161/CIR.0000000000000916) |

The AHA PDFs were retrieved through Internet Archive copies of the official AHA files because direct download from `cpr.heart.org` returned HTTP 403 in this environment. The HTML guideline pages were read directly from `cpr.heart.org`. The box-by-box algorithm sequence below is taken from the AHA accessible description, not from third-party summaries. The ERC PDFs were downloaded directly from `erc.edu` (HTTP 200); the *Resuscitation* full-text pages returned HTTP 403, so the DOI links are for provenance and the page-level ERC citations refer to the official ERC PDFs. No Internet Archive copy was needed for the ERC documents.

### 1.3 How to read the citations

Inline citations link to the source page and name the numbered section on that page (for example `[Part 9 §10]`). ERC citations give the page of the official ERC PDF instead, because the ERC guideline does not use the AHA's numbered-section scheme. Page-level ranges are given in the source list. COR/LOE values are reproduced as printed: **COR** = Class of Recommendation (1, 2a, 2b, 3), **LOE** = Level of Evidence (A, B-R, B-NR, C-LD, C-EO).

---

## 2. Summary table of timed actions

*This table is the AHA 2025 profile. The ERC 2025 profile and the rows where ERC differs are in §3.9; the app selects one profile per case and does not blend them.*

| # | Action | Timing / interval | Dose / energy | Rhythm applicability | COR / LOE | Source |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Initial pulse check (healthcare professional) | ≤ 10 s; if no definite pulse, assume arrest | — | all | 1 / C-LD | [Part 7 §6.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 2 | Rhythm analysis | At the end of each 2-min CPR cycle | — | all | Algorithm step; 2-min interval is not itself a graded recommendation | [Algorithm boxes 4/6/10/11](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf) |
| 3 | Pulse check during a rhythm check | ≤ 10 s; restart compressions immediately if no definite pulse | — | all | 1 / C-LD | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 4 | Rhythm/pulse check immediately after a shock | **Do not** pause for it; resume compressions immediately | — | VF/pVT | 2a / B-R | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 5 | Compressor switch | Approximately every 2 min (or ~5 cycles of 30:2); sooner if fatigued | — | all | 2a / B-R | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 6 | Compression depth | Every compression | ≥ 5 cm, avoid > 6 cm | all | 1 / B-NR | [Part 7 §7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 7 | Compression rate | Every compression | 100–120/min | all | 2a / B-NR | [Part 7 §7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 8 | Chest compression fraction (CCF) | Over the whole resuscitation | ≥ 60 % minimum; high-performance teams > 80 % | all | 2b / C-LD | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 9 | Ventilation without advanced airway | Pause compressions for 2 breaths, each over 1 s | 30:2 | all | 2a / C-LD | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| 10 | Ventilation with advanced airway | 1 breath every 6 s (10/min) with continuous compressions | — | all | 2b / C-LD | [Part 9 §14](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| 11 | Defibrillation | On identifying VF/pVT; single shock; resume CPR immediately afterwards | Biphasic: manufacturer recommendation, e.g. 120–200 J first shock; max available if unknown. Monophasic: 360 J. Subsequent shocks equivalent or higher | VF/pVT | 1 / B-NR (indication); 2a / B-NR (single shock); 2b / C-LD (energy) | [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [Algorithm Drug/Energy boxes](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| 12 | Epinephrine, first dose, non-shockable | As soon as feasible | 1 mg IV/IO | asystole/PEA | 2a / B-NR | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| 13 | Epinephrine, first dose, shockable | After initial defibrillation attempts have failed; the 2025 algorithm places it in the CPR block after the **second** shock | 1 mg IV/IO | VF/pVT | 2a / B-NR | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [Algorithm description, Box 6](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf) |
| 14 | Epinephrine, repeat | Every 3–5 min; operationally every second 2-min CPR cycle | 1 mg IV/IO | all | 2a / B-R | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| 15 | Amiodarone | VF/pVT unresponsive to defibrillation; 2025 algorithm places it in the CPR block after the **third** shock | 300 mg first dose, 150 mg second dose IV/IO | VF/pVT | 2b / B-R | [Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [Algorithm Drug Therapy box](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| 16 | Lidocaine (alternative to amiodarone) | Same position in the algorithm | 1–1.5 mg/kg first dose; 0.5–0.75 mg/kg second dose IV/IO | VF/pVT | 2b / B-R | [Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [Algorithm Drug Therapy box](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| 17 | Reversible causes (H's and T's) | Continuously, inside the 2-min CPR cycles; without interrupting CPR | — | all | Algorithm step; POCUS 2b / C-LD | [Algorithm, Boxes 8 and 11](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf); [Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| 18 | ETCO₂ during CPR | Continuous if available | Target ≥ 10 mmHg, ideally ≥ 20 mmHg; abrupt rise > 10 mmHg suggests ROSC | all | 2b / B-NR (ROSC); 2b / C-LD (optimise CPR) | [Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| 19 | ROSC recognition | During compressions or at a rhythm check | Palpable pulse; abrupt ETCO₂ rise; arterial waveform | all | 2b / B-NR; 2b / C-EO | [Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| 20 | Post-ROSC oxygenation | Immediately after ROSC; once SpO₂/PaO₂ reliable, titrate | 100 % O₂ until reliable measurement, then SpO₂ 90–98 % (PaO₂ 60–105 mmHg) | post-ROSC | 1 / B-R; 1 / B-NR; 2a / B-R | [Part 11 §4.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| 21 | Post-ROSC ventilation | Continuous | PaCO₂ 35–45 mmHg | post-ROSC, comatose | 1 / B-R | [Part 11 §4.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| 22 | Post-ROSC blood pressure | Continuous | MAP ≥ 65 mmHg | post-ROSC | 1 / B-R | [Part 11 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| 23 | Post-ROSC 12-lead ECG | As soon as feasible | — | post-ROSC | 1 / B-NR | [Part 11 §6](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| 24 | Post-ROSC temperature control | Start after ROSC; maintain ≥ 36 h in patients not following commands | 32–37.5 °C | post-ROSC, comatose | 1 / B-R; 2a / B-R | [Part 11 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| 25 | Termination-of-resuscitation ETCO₂ | After 20 min of ALS resuscitation, as one component only | ETCO₂ ≤ 10 mmHg (intubated) | OHCA, intubated | 2b / C-LD | [Part 9 §13](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |

---

## 3. Detailed findings

*Sections 3.1–3.8 describe the AHA 2025 profile. §3.9 compares it with ERC 2025; both are selectable in the app.*

### 3.1 Rhythm analysis and pulse checks

**Initial recognition.** For a healthcare professional, an unresponsive adult with absent or abnormal breathing gets a pulse check of **no more than 10 seconds**; if no definite pulse is felt, cardiac arrest is assumed and compressions start ([Part 7 §6.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support), recommendation 2, COR 1, LOE C-LD). The same 10-second ceiling applies to pulse checks during rhythm checks ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support), recommendation 2, COR 1, LOE C-LD).

**Rhythm analysis cadence.** The 2025 algorithm runs on **2-minute CPR blocks**: each of these CPR blocks is followed by a rhythm decision, and the result determines whether the next action is a shock or another CPR block ([Algorithm description, Boxes 4, 6, 10, 11](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)). The 2-minute interval is drawn in the algorithm; the AHA also lists "the optimal time interval for duration of chest compressions after shock delivery and prior to reassessing rhythm" as an open knowledge gap ([Part 1 §8.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary)). It should therefore be treated as the current convention, not as an evidence-derived constant.

**No post-shock rhythm check.** It is reasonable to **immediately resume chest compressions after a shock** rather than pause for a post-shock rhythm check (COR 2a, LOE B-R) ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)). The supporting text cites two RCTs with more than 1000 patients that found no survival increase when CPR was paused to analyse rhythm after defibrillation, and observational data showing decreased ROSC when compressions were not resumed immediately ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)).

**How long may a check take?** The only explicit numeric limit is the **10-second pulse check**. For rhythm analysis itself, the AHA requires that pre-shock and post-shock pauses be "as short as possible" (COR 1, LOE C-LD) ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) and notes that "time taken for rhythm analysis also disrupts CPR" ([Part 9 §6](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). No maximum duration for rhythm analysis is published, so an app must not invent one; it can measure the pause and flag it.

**Pulse during CPR.** The algorithm branches on **rhythm**, not on pulse. A pulse check is used to confirm ROSC when an organised rhythm appears, and an abrupt ETCO₂ rise or an arterial waveform may prompt that check ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). Outside the ALS environment, the AHA states there are insufficient data about the value of a pulse check while CPR is being performed ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support), recommendation 7, COR 2b, LOE C-LD).

### 3.2 Epinephrine

| Element | 2025 guidance | COR / LOE | Source |
| --- | --- | --- | --- |
| Give epinephrine at all | Recommended | 1 / B-R | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Dose and interval | 1 mg IV/IO every 3–5 min | 2a / B-R | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Non-shockable rhythm timing | As soon as feasible | 2a / B-NR | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Shockable rhythm timing | After initial defibrillation attempts have failed | 2a / B-NR | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Practical translation | "Administering epinephrine every second cycle of CPR, after the initial dose, meets this recommendation." | — | [Part 9 §10, supportive text 2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Vasopressin instead of / added to epinephrine | No advantage | 3: No Benefit / B-R | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| High-dose epinephrine | Not recommended routinely | 3: No Benefit / B-R | [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |

**What the 2025 algorithm actually sequences.** The box-by-box description shows:

- Shockable path: Box 3 = shock, **Box 4 = CPR 2 min + IV/IO access (no epinephrine listed)**, Box 5 = shock, **Box 6 = CPR 2 min + epinephrine every 3–5 min + advanced airway/capnography**, Box 7 = shock, Box 8 = CPR 2 min + amiodarone or lidocaine + treat reversible causes ([Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)).
- Non-shockable path: Box 9 = asystole/PEA, **"Give Epinephrine ASAP"**, then Box 10 = CPR 2 min + IV/IO + epinephrine every 3–5 min + advanced airway/capnography ([Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)).

So in a shockable arrest the first epinephrine dose follows the **second** shock in the figure, which is the operational form of "after initial defibrillation attempts have failed". In a non-shockable arrest it is given as early as possible. This asymmetry is deliberate and should be visible in the UI.

**Evidence caveat.** Epinephrine increases ROSC and survival to hospital admission, but evidence for improved survival to discharge or neurologically favourable outcome is limited ([Part 9 §10, synopsis](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). A post-hoc analysis of PARAMEDIC2 found that the effect versus placebo converged at approximately **20 minutes of pulselessness** ([Part 9 §10, supportive text 3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). Do not hard-code a "maximum dose" or a "stop after N doses" rule; the AHA explicitly calls the optimal number of doses a knowledge gap ([Part 9 §10, synopsis](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)).

**Where an institutional HP-CPR protocol may differ:** fixed cycle numbers for epinephrine (for example "with the second shock" or "every other cycle"), a different first-dose timing in shockable arrest, or a pre-filled syringe / IM-first strategy. None of these are AHA recommendations; they must come from the adopted local protocol.

### 3.3 Defibrillation

| Element | 2025 guidance | COR / LOE | Source |
| --- | --- | --- | --- |
| Indication | Defibrillators for tachyarrhythmias requiring a shock, e.g. VF/pVT | 1 / B-NR | [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Waveform | Biphasic preferred over monophasic | 2a / B-R | [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Shock strategy | Single shock preferred over stacked shocks | 2a / B-NR | [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Fixed vs escalating energy | Follow the manufacturer's instructions for that waveform | 2b / C-LD | [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Higher energy for later shocks | May be considered if the first shock fails | 2b / B-R | [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| If manufacturer dose unknown | Use the maximum available dose | 2b / C-LD | [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Vector change / double sequential defibrillation | Usefulness not established for persisting VF/pVT after ≥ 3 consecutive shocks | 2b / B-R (both) | [Part 9 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |

**Energy values in the 2025 algorithm.** Biphasic: manufacturer recommendation, example **initial dose 120–200 J**; if unknown, use the maximum available; second and subsequent doses should be equivalent, and higher doses may be considered. Monophasic: **360 J** ([Algorithm, "Shock Energy for Defibrillation"](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf)). Because energy is device-specific, the app must store the defibrillator model or at least a per-device energy policy, and must not present 200 J as a universal dose.

**Sequence immediately after a shock.** Resume chest compressions **immediately** and continue for 2 minutes. Do not pause for a rhythm or pulse check after the shock (COR 2a, LOE B-R) ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)). This is the single most important timing rule for the UI: the shock event closes one pause and immediately opens a compression segment.

**Stacked shocks.** A single-shock strategy is preferred (COR 2a, LOE B-NR) ([Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). The guidelines note that it is unknown whether stacked or single shocks are more effective in a monitored witnessed arrest, such as in-hospital arrest or after cardiac surgery ([Part 9 §5, supportive text 3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)).

**Polymorphic VT.** Sustained polymorphic VT is treated with **immediate unsynchronised shock** (COR 1, LOE B-NR) ([Part 9 §16](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). For data modelling, it is worth keeping "polymorphic VT" as a distinct rhythm value rather than folding it into "VF/pVT", because the recommendation and the energy rationale are specific to it.

**Pads and technique.** Shock success is affected by pad position, pad-skin contact and applied pressure, independently of energy ([Part 9 §5, supportive text 4–5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [Part 9 §7, synopsis](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). These are useful optional fields on a shock event.

### 3.4 Amiodarone and lidocaine in refractory VF/pVT

| Element | 2025 guidance | COR / LOE | Source |
| --- | --- | --- | --- |
| Amiodarone or lidocaine | May be considered for VF/pVT unresponsive to defibrillation | 2b / B-R | [Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Amiodarone dose | First dose 300 mg bolus; second dose 150 mg | — (algorithm) | [Algorithm, Drug Therapy](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| Lidocaine dose | First dose 1–1.5 mg/kg; second dose 0.5–0.75 mg/kg | — (algorithm) | [Algorithm, Drug Therapy](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| β-blockers, bretylium, procainamide, sotalol | Uncertain benefit | 2b / C-LD | [Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Routine calcium, sodium bicarbonate, magnesium | Not recommended | 3: No Benefit / B-R (each) | [Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Magnesium for torsades de pointes | May be considered for recurrences with long QT | 2b / C-LD | [Part 9 §16](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |

**Timing in the algorithm.** The amiodarone/lidocaine box (Box 8) follows the **third** shock (Box 7) and sits in the same CPR block as "treat reversible causes" ([Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)). The recommendation itself is qualitative ("unresponsive to defibrillation") and does not mandate a shock count; the figure is the operational form.

**Evidence caveat.** Amiodarone and lidocaine each improved survival to hospital admission over placebo, but not survival to hospital discharge; secondary analyses suggested benefit in bystander-witnessed arrest, and amiodarone given within 8 minutes of ALS arrival also improved discharge and functional survival ([Part 9 §11, supportive text 1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). Data are insufficient to distinguish the two drugs or to support combining them ([Part 9 §11, supportive text 1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)).

**Local variation to expect:** amiodarone versus lidocaine as first-line, a maximum of two doses, or a "no antiarrhythmic" policy in some services. The app should record the drug actually given and flag deviations, not assume one agent.

### 3.5 CPR quality and compressor switching

| Metric | 2025 target | COR / LOE | Source |
| --- | --- | --- | --- |
| Compression rate | 100–120/min | 2a / B-NR | [Part 7 §7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Compression depth | At least 5 cm; avoid more than 6 cm | 1 / B-NR | [Part 7 §7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Full chest recoil | Allow complete recoil; do not lean | 2a / C-LD | [Part 7 §7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Duty cycle | Compression and recoil time approximately equal | 2b / C-EO | [Part 7 §7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Compression fraction | ≥ 60 % minimum; high performers > 80 % | 2b / C-LD | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Pauses | Pre-shock and post-shock pauses as short as possible | 1 / C-LD | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Compressor switch | Approximately every 2 min, or ~5 cycles of 30:2; sooner if fatigued | 2a / B-R | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Ventilation without advanced airway | 30:2; 2 breaths, each over 1 s | 2a / C-LD | [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Ventilation with advanced airway | 1 breath every 6 s (10/min), continuous compressions | 2b / C-LD | [Part 9 §14](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |
| Avoid hyper/hypoventilation | Avoid both | 3: Harm / C-LD | [Part 7 §8.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Real-time feedback devices | Reasonable to use | 2a / B-R | [Part 7 §7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support) |
| Mechanical CPR | Routine use not recommended; may be considered in specific circumstances | 3: No Benefit / B-R; 2b / C-LD | [Part 1 §8.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary) |
| Head-up CPR | Not recommended outside clinical trials | 3: No Benefit / C-LD | [Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support) |

**Why 2 minutes.** Compression depth begins to decrease after 90–120 seconds of CPR, while compression rate does not decrease significantly over that window; rotating the compressor every 2 minutes is "sensible" because it coincides with the pause for rhythm analysis ([Part 7 §7.2, supportive text 4](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)). This is a rationale, not a comparative trial result.

**Compression fraction.** The AHA sets ≥ 60 % as the minimum and notes that "high performance teams may achieve higher levels (eg: greater than 80 %)" ([Part 7 §7.2, supportive text 6](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)). If the app targets an HP-CPR bundle, the 80 % figure is the defensible stretch target from AHA text, not a separate recommendation.

**ETCO₂.** During CPR, values below 10 mmHg are generally associated with poor outcomes, while values above 10 mmHg and ideally above 20 mmHg are associated with increased ROSC; targeting at least 10 mmHg, ideally 20 mmHg or more, may indicate mechanically adequate compressions ([Part 9 §12, supportive text 6](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). An abrupt increase may be used to detect ROSC (COR 2b, LOE B-NR), and a sudden rise greater than 10 mmHg may indicate ROSC, although ROSC can occur with smaller rises ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). ETCO₂ is affected by ventilation, drugs, airway strategy and arrest aetiology, so it is a trend signal, not a target to titrate to blindly.

### 3.6 Reversible causes (H's and T's)

The 2025 algorithm lists the classic 5 H's and 5 T's and places "treat reversible causes" inside the CPR blocks (Boxes 8 and 11), i.e. **during** compressions rather than at a separate pause ([Algorithm, Reversible Causes](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf); [Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)).

| H's | T's |
| --- | --- |
| Hypovolaemia | Tension pneumothorax |
| Hypoxia | Tamponade, cardiac |
| Hydrogen ion (acidosis) | Toxins |
| Hypo-/hyperkalaemia | Thrombosis, pulmonary |
| Hypothermia | Thrombosis, coronary |

Source: [2025 Adult Cardiac Arrest Algorithm, Reversible Causes box](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf).

Point-of-care ultrasonography may be considered to diagnose reversible causes if it can be done **without interrupting CPR** (COR 2b, LOE C-LD) ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)); it is one of the 2025 Top 10 take-home messages ([Part 9 §2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). There is no specified minute mark at which the checklist must be completed; the app should therefore model it as a checklist with optional timestamps, not as a countdown.

Specific antidotes and special-circumstance treatments (hyperkalaemia, toxidromes, hypothermia, pregnancy, cardiac surgery) are in Part 10 and are outside this note.

### 3.7 ROSC recognition and immediate post-ROSC targets

**Recognition.** ROSC is confirmed by a palpable pulse, ideally with corroborating physiology:

- An **abrupt increase in ETCO₂** may be used to detect ROSC during compressions or when a rhythm check reveals an organised rhythm (COR 2b, LOE B-NR) ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)).
- An **arterial waveform** or a sudden rise in diastolic pressure may indicate ROSC, but must correlate with a palpable pulse (COR 2b, LOE C-EO) ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)).
- The algorithm's terminal box reads: "If ROSC, go to post–cardiac arrest care"; if no ROSC, return to the CPR loop; and "consider appropriateness of continued resuscitation" ([Algorithm description, Box 12](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)).

**Immediate post-ROSC targets.**

| Target | 2025 value | COR / LOE | Source |
| --- | --- | --- | --- |
| Inspired oxygen until measurement | 100 % until SpO₂ or PaO₂ can be reliably measured | 1 / B-R | [Part 11 §4.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| Avoid hypoxaemia | — | 1 / B-NR | [Part 11 §4.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| SpO₂ target once measurable | 90–98 % (PaO₂ 60–105 mmHg) | 2a / B-R | [Part 11 §4.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| PaCO₂ | 35–45 mmHg in comatose patients | 1 / B-R | [Part 11 §4.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| MAP | ≥ 65 mmHg | 1 / B-R | [Part 11 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| 12-lead ECG | As soon as feasible | 1 / B-NR | [Part 11 §6](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| Temperature control | 32–37.5 °C, maintained ≥ 36 h if not following commands | 1 / B-R; 2a / B-R | [Part 11 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| Glucose | Avoid < 70 mg/dL and > 180 mg/dL | 2b / B-NR | [Part 11 §8](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |
| Rewarming rate | Avoid faster than 0.5 °C/h when rewarming | 2b / B-R | [Part 11 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |

**Timing nuance for the ECG.** ECGs performed within the first 8 minutes after ROSC have higher false-positive rates for STEMI than later ECGs, and about two-thirds of immediate STEMI patterns evolved to non-STEMI patterns on a repeat ECG a median of 30 minutes later; the optimal timing of the initial and repeat ECG is not well defined ([Part 11 §6, supportive text 1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)). The app should record both "ECG obtained" and "repeat ECG" without implying that one early ECG is definitive.

### 3.8 What changed versus 2020 (only where it affects timing)

| Topic | 2020 position | 2025 position | Timing impact |
| --- | --- | --- | --- |
| Epinephrine timing, shockable | "May be reasonable" after initial defibrillation attempts fail (2b / C-LD) ([2020 Part 3, Vasopressors](https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support)) | "It is reasonable" (2a / B-NR) ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) | Same timing, stronger recommendation |
| Epinephrine timing, non-shockable | As soon as feasible (2a / C-LD) ([2020 Part 3](https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support)) | As soon as feasible (2a / B-NR) ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) | None, LOE upgraded |
| ETCO₂ for ROSC detection | 2b / C-LD ([2020 Part 3, Adjuncts](https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support)) | 2b / B-NR ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) | None, LOE upgraded |
| Double sequential defibrillation | 2b / C-LD ([2020 Part 3](https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support)) | 2b / B-R, plus vector change 2b / B-R, both after ≥ 3 shocks ([Part 9 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) | Adds an explicit "after 3 shocks" boundary |
| Head-up CPR | No head-up recommendation was found in the 2020 Part 3 page used for comparison | 3: No Benefit / C-LD ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)); listed among the 2025 significant ALS changes ([Part 1 §10.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary)) | Removes a bundle that altered compression positioning |
| Polymorphic VT | Previous editions suggested multiple treatment modalities based on clinical stability, as summarised in the 2025 Executive Summary ([Part 1 §10.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary)) | Immediate unsynchronised shock (1 / B-NR) ([Part 9 §16](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) | Removes a decision delay |
| Post-ROSC SpO₂ | 92–98 % (2b / B-R) ([2020 Part 3, Post-ROSC](https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support)) | 90–98 % (2a / B-R) ([Part 11 §4.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)) | Lower bound moved from 92 % to 90 % |
| Post-ROSC blood pressure | SBP ≥ 90 mmHg **and** MAP ≥ 65 mmHg (2a / B-NR) ([2020 Part 3](https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support)) | MAP ≥ 65 mmHg only (1 / B-R) ([Part 11 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)) | Systolic target removed |
| Post-ROSC temperature | 32–36 °C for at least 24 h (1 / B-R) ([2020 Part 3](https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support)) | 32–37.5 °C for at least 36 h (1 / B-R; 2a / B-R) ([Part 11 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)) | Wider range, longer minimum duration |

**What the AHA itself flags as new in ALS.** The 2025 Executive Summary lists only four "significant new and updated recommendations" for adult ALS: first-shock energy ≥ 200 J for AF/flutter cardioversion, double sequential defibrillation, head-up CPR, and immediate defibrillation for polymorphic VT ([Part 1 §10.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary)). Epinephrine and antiarrhythmic dosing are not on that list. Epinephrine's COR/LOE wording nevertheless differs from the 2020 table as shown above, while the amiodarone/lidocaine recommendation is unchanged at 2b / B-R ([Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)).

**2026.** No 2026 adult ALS focused update was listed on the AHA index on 2026-10-24 ([AHA Guidelines Updates and Highlights](https://cpr.heart.org/en/resuscitation-science/guidelines-updates-and-highlights)). The 2025 edition is therefore the current baseline for this research.

### 3.9 ERC 2025 profile and comparison

**Edition status.** The current ERC edition is **ERC Guidelines 2025**, launched 2025-10-22 ([ERC Guidelines 2025](https://www.erc.edu/science-research/guidelines/guidelines-2025/guidelines-2025-english/)). No ERC 2026 edition or 2026 focused update was listed on 2026-10-24. A corrigendum to the ALS guideline was published 2026-09-16; it corrects two reference citations and an ibutilide dose and does not affect any timing, drug or target in this note ([Corrigendum](https://doi.org/10.1016/j.resuscitation.2026.111313)).

| Topic | AHA 2025 | ERC 2025 | Practical difference for the app | Sources |
| --- | --- | --- | --- | --- |
| Rhythm analysis cadence and pulse check | Rhythm analysis at the end of each 2-min CPR cycle; pulse check ≤ 10 s at initial recognition (healthcare professional) and during rhythm checks; no post-shock pause for rhythm/pulse. | Reassess rhythm every 2 min. If a compression-artefact-free ECG shows asystole, the pause for rhythm analysis may be omitted. BLS recognition uses unresponsiveness + abnormal breathing, not a pulse check. In ALS, a pulse check is considered only as part of the ROSC assessment when clinical/physiological signs prompt a rhythm analysis, not as a routine step in every cycle; the 2025 ALS text gives no 10-s pulse-check limit. | AHA mode prompts a ≤ 10 s pulse check at recognition; ERC mode should not require one. ERC mode may allow "analysis without pausing" for asystole on a filtered ECG, and should treat pulse checks as ROSC assessment rather than a scheduled step. Both still record every rhythm result. | AHA [Part 7 §6.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support), [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support), [Algorithm](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf); ERC [ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [BLS p. 2](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf) |
| Peri-shock pause and rhythm-analysis duration | Pre- and post-shock pauses "as short as possible" (1 / C-LD); no numeric cap for rhythm analysis. | Aim for < 5 s interruption for rhythm identification and shock delivery; manual-defibrillator users must identify the rhythm within 5 s; < 5 s for tracheal intubation. | ERC mode can show a 5-s peri-shock target; AHA mode keeps "as short as possible" plus the existing 10-s generic pause audit flag. Do not present 5 s as an AHA limit. | AHA [Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support); ERC [ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Epinephrine (adrenaline), shockable rhythm | 1 mg IV/IO after initial defibrillation attempts fail; the 2025 algorithm places it in the CPR block after the **second** shock (2a / B-NR). | 1 mg IV/IO after the **third** shock, then every 3–5 min. | Largest branch difference. `epinephrineFirstDosePolicy` = `shockableAfterSecondShock` (AHA) or `shockableAfterThirdShock` (ERC). The interval timer starts at the actual dose. | AHA [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support), [Algorithm Box 6](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf); ERC [ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [Fig. 2 p. 5](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Epinephrine (adrenaline), non-shockable; dose and interval | 1 mg IV/IO as soon as feasible (2a / B-NR); repeat every 3–5 min (2a / B-R). | 1 mg IV/IO as soon as possible; repeat every 3–5 min. In highly monitored arrest with an arterial line, start with 50–100 µg increments rather than 1 mg. | Same default. The arterial-line exception is a separate in-hospital mode and should not change the prehospital default. | AHA [Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); ERC [ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [ALS p. 32](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Defibrillation sequence and energy | Single shock preferred (2a / B-NR); first biphasic 120–200 J per manufacturer (2b / C-LD), maximum if unknown, equivalent or higher subsequent; monophasic 360 J. Stacked shocks not preferred. | Single shock followed by 2-min CPR; first biphasic ≥ 150 J (non-pulsed), 130–150 J (pulsed); escalate subsequent shocks if capable; maximum if unknown; up to 3 stacked shocks only in a witnessed, monitored arrest with a defibrillator immediately available; dual sequential defibrillation not routine. | Do not hard-code 200 J. Add a first-shock floor: AHA example lower bound 120 J, ERC ≥ 150 J for non-pulsed biphasic. Add a waveform/stacked-shock policy. Monophasic 360 J is an AHA figure; ERC 2025 gives no monophasic value in the text reviewed. | AHA [Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); ERC [ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Amiodarone and lidocaine | Amiodarone 300 mg after the third shock; second dose 150 mg (2b / B-R); lidocaine 1–1.5 mg/kg then 0.5–0.75 mg/kg as the alternative. | Amiodarone 300 mg after 3 shocks, 150 mg after 5 shocks; lidocaine 100 mg fixed, additional 50 mg after 5 shocks, only if amiodarone is unavailable or a local decision selects lidocaine. | AHA and ERC cannot share one lidocaine dose field. `lidocaineDosePolicy` = `weightBased` (AHA) or `fixed100_50` (ERC). The second amiodarone trigger differs (AHA gives no shock-count trigger; ERC says after shock 5). | AHA [Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support), [Algorithm Drug Therapy](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf); ERC [ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| CPR quality, compressor switching, compression fraction | 100–120/min; 5–6 cm; full recoil; CCF ≥ 60 % (2b / C-LD); > 80 % described for high-performance teams; switch ~every 2 min; 30:2 or 10 breaths/min with an advanced airway. | 100–120/min; 5–6 cm; full recoil; CCF at least 60 % and "as high as possible"; no 80 % target; no separate compressor-switch interval in the 2025 ALS concise text; the 2-min cycle is the practical switch point; same ventilation. | Keep 120 s as the default switch. Label 80 % as an AHA-derived stretch target, not an ERC target. No change to rate, depth or ventilation. | AHA [Part 7 §7.2–7.3](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support); ERC [BLS p. 4](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf), [BLS p. 15](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf), [ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| ETCO₂ | Target ≥ 10 mmHg, ideally ≥ 20 mmHg; abrupt rise > 10 mmHg suggests ROSC (2b / B-NR); may be used to optimise CPR (2b / C-LD). | No general ETCO₂ target; do not use a low value alone to stop resuscitation; a rise may indicate ROSC but compressions must not be interrupted on that sign alone; in physiology-guided CPR aim for ETCO₂ ≥ 25 mmHg (3.3 kPa). | AHA mode may show 10/20 advisory bands. ERC mode should show trend only, with no pass/fail, and a ROSC prompt that requires combined signs. ETCO₂ must not be the sole TOR criterion in either mode. | AHA [Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); ERC [ALS p. 9](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [ALS p. 32](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Reversible causes | 5 H's and 5 T's; POCUS 2b / C-LD if it does not interrupt CPR. | 4 H's (hypoxia; hypovolaemia; hyper-/hypokalaemia/metabolic; hypothermia, hyperthermia) and 4 T's (toxins; tamponade; tension pneumothorax; thrombosis, coronary/pulmonary). POCUS only by skilled operators and without interrupting CPR. | Checklist content is edition-specific. ERC mode should add hyperthermia and fold acidosis into the metabolic item; no timing change. | AHA [Algorithm](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf), [Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); ERC [Fig. 2 p. 5](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [ALS p. 34](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| ROSC recognition | Palpable pulse, ideally with an abrupt ETCO₂ rise or arterial waveform (2b / B-NR; 2b / C-EO). | Require a combination of clinical and physiological signs (consciousness, purposeful movement, arterial waveform, sharp ETCO₂ rise) before stopping compressions for rhythm analysis and a pulse check; an ETCO₂ rise alone must not interrupt compressions; the rise may precede a palpable pulse by ≥ 10 min. | ERC mode should not auto-pause or auto-record ROSC on ETCO₂ alone; require a combination or explicit team confirmation. ROSC stays optional per product decision. | AHA [Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); ERC [ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [ALS p. 9](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [ALS p. 33](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Immediate post-ROSC targets | 100 % O₂ until reliable measurement, then SpO₂ 90–98 % (PaO₂ 60–105 mmHg); PaCO₂ 35–45 mmHg; MAP ≥ 65 mmHg; 12-lead ECG as soon as feasible; temperature 32–37.5 °C for ≥ 36 h. | 100 % O₂ until reliable measurement, then SpO₂ 94–98 % (PaO₂ 75–100 mmHg); PaCO₂ 35–45 mmHg (4.7–6.0 kPa); MAP > 60–65 mmHg (the algorithm's immediate box says SBP > 100 mmHg); 12-lead ECG and immediate coronary angiography for STEMI; prevent fever ≤ 37.5 °C, do not actively warm 32–36 °C, prevent fever for 36–72 h. | Add an ERC post-ROSC preset: SpO₂ 94–98 %, MAP 60–65, temperature "avoid fever, do not actively warm 32–36". AHA default stays 90–98 %, 65, 32–37.5 °C. The ERC SBP > 100 and MAP > 60–65 are not the same target; clinical review needed. | AHA [Part 11 §4–7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care); ERC [post-ROSC pp. 4–7](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf), [Fig. 2 p. 5](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Termination of resuscitation | ETCO₂ ≤ 10 mmHg after 20 min of ALS in an intubated patient as one component (2b / C-LD); termination is multimodal. | No universal TOR rule. EMS may use validated TOR rules only after local validation; for IHCA no reliable rule exists and UN10 must not be used as a sole strategy; a low ETCO₂ alone must not decide to stop. | `torPolicy` remains unset/local. The AHA ETCO₂ TOR audit rule must be flagged AHA-only and disabled in ERC mode. No new default. | AHA [Part 9 §13](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); ERC [ALS p. 16](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |

**How close are the editions?** The two 2025 editions are closer than a 2021-era comparison would suggest: both were released in October 2025 and both are based on the 2025 ILCOR CoSTR ([ERC 2025 Executive Summary](https://www.erc.edu/media/ad5dtph1/gl2025-01-exec-e.pdf); [AHA Part 1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary)). The differences above are mostly operational choices, not competing evidence claims.

**The largest branch difference is epinephrine in shockable arrest.** AHA 2025 puts the first 1 mg in the CPR block after shock 2; ERC 2025 gives it after shock 3 ([AHA Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)). In a non-shockable arrest both give it as soon as possible, and both repeat every 3–5 min. The app must store the baseline per case and must not switch mid-case; a one-cycle difference changes the first-dose timestamp and any "late/early" audit.

**The second largest is lidocaine.** AHA uses weight-based 1–1.5 mg/kg then 0.5–0.75 mg/kg; ERC uses fixed 100 mg then 50 mg ([AHA Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)). These are not interchangeable, and a single dose field would produce a wrong record for one edition. Amiodarone's first dose is the same (300 mg), but ERC triggers the second dose after shock 5, whereas the AHA algorithm lists a second 150 mg dose without a shock-count trigger.

**Defibrillation energy is device-specific in both editions.** AHA's example 120–200 J first-shock range and ERC's ≥ 150 J floor overlap, but a 120–149 J device setting is not automatically a deviation under AHA and is below ERC's floor for non-pulsed biphasic ([AHA Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)). The app should store the waveform and device policy and should not display 200 J as a universal dose. ERC also gives a 130–150 J range for pulsed biphasic and allows stacked shocks only in a witnessed, monitored arrest.

**Pulse check and ETCO₂ are the safety-relevant differences.** ERC 2025 BLS does not use a pulse check at recognition ([ERC BLS p. 2](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf)), and ERC ALS treats a pulse check as part of ROSC assessment rather than a scheduled step in every cycle ([ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)). ERC also explicitly says an ETCO₂ rise alone must not interrupt compressions ([ERC ALS p. 9](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)); AHA treats an abrupt rise as a ROSC signal. The app should not auto-pause on ETCO₂ in either mode, and in ERC mode it should not require a pulse check at recognition.

**Post-ROSC targets differ at the lower edge of the SpO₂ band (90 % AHA vs 94 % ERC), at the MAP boundary (≥ 65 vs > 60–65), and in temperature strategy** (AHA 32–37.5 °C for ≥ 36 h vs ERC fever avoidance ≤ 37.5 °C with no active warming of 32–36 °C) ([AHA Part 11 §4–7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care); [ERC-ESICM post-ROSC pp. 4–7](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf)). These are handoff/report targets, not intra-arrest timers, but they must not be blended into one "90–98 %, 32–37.5 °C" band labelled as both.

**Termination is procedural in ERC:** local validation, no universal rule; the AHA ETCO₂ rule is a component, not a standalone rule ([ERC ALS p. 16](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)). The app should keep `torPolicy` unset and edition-aware.

**Recommendation.** Expose the guideline standard in app settings with two first-class profiles, AHA 2025 and ERC 2025. Select one `guidelineEdition` per case, let the profile set the dependent defaults in §5.5, and record the selection plus any overrides in the export. Do not blend editions within a case.

---

## 4. Illustrative timelines

> **These timelines are a reconstruction of the 2025 AHA Adult Cardiac Arrest Algorithm for design discussion. They are not new medical advice, not a protocol, and not a substitute for the printed algorithm or institutional policy. Minute marks are nominal; actual events will not align to them.**

### 4.1 Shockable arrest (VF/pVT), witnessed, ALS already on scene

| Nominal time | Algorithm step | Action | Timing rule / source |
| --- | --- | --- | --- |
| 0:00 | Box 1 | Recognise arrest, start compressions, bag-mask ventilation with oxygen, attach monitor/defibrillator | [Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf) |
| 0:00–0:30 | Box 2 → 3 | Rhythm check shows VF/pVT → charge and deliver **shock 1** | Pre-shock pause as short as possible (1 / C-LD) ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) |
| immediately | Box 4 | **Resume compressions for 2 min**; obtain IV/IO access | No post-shock rhythm check (2a / B-R) ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) |
| ~2:00 | Box 4 exit | Brief rhythm check; still VF/pVT → **shock 2** | Pulse check ≤ 10 s if a pulse is checked ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) |
| ~2:00–4:00 | Box 6 | CPR 2 min; **epinephrine 1 mg**; consider advanced airway + capnography | Epi after initial defibrillation attempts fail (2a / B-NR) ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| ~4:00 | Box 6 exit | Rhythm check → **shock 3** | — |
| ~4:00–6:00 | Box 8 | CPR 2 min; **amiodarone 300 mg** (or lidocaine 1–1.5 mg/kg); treat reversible causes | 2b / B-R ([Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| ~6:00 | loop | Rhythm check → **shock 4**; next CPR block; repeat epinephrine when 3–5 min have elapsed; second amiodarone dose 150 mg (or lidocaine 0.5–0.75 mg/kg) if used | Epi every 3–5 min, operationally every second cycle ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| ongoing | Boxes 6/8 loop | 2-min CPR cycles, rhythm check after each, shock if shockable, reversible-cause checklist inside each cycle | Compressor switch every ~2 min (2a / B-R) ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) |
| ROSC | Box 12 | → post–cardiac arrest care | [Part 11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |

**Note on the loop:** the AHA accessible description specifies the entry and exit arrows for Boxes 1–12 except the exit from Box 8; the printed figure should be consulted during clinical review. The app should drive the loop from "rhythm check every 2 min" rather than from hard-coded box numbers.

### 4.2 Non-shockable arrest (asystole/PEA)

| Nominal time | Algorithm step | Action | Timing rule / source |
| --- | --- | --- | --- |
| 0:00 | Box 1 | Recognise arrest, start compressions, bag-mask ventilation with oxygen, attach monitor/defibrillator | [Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf) |
| 0:00–0:30 | Box 2 → 9 | Rhythm check shows asystole/PEA → **epinephrine 1 mg as soon as feasible** | 2a / B-NR ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| 0:00–2:00 | Box 10 | CPR 2 min; IV/IO access; epinephrine every 3–5 min; consider advanced airway + capnography | ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| ~2:00 | Box 10 exit | Rhythm check; still non-shockable → Box 11 | — |
| ~2:00–4:00 | Box 11 | CPR 2 min; treat reversible causes | [Algorithm](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| ~4:00 | Box 11 exit → 12 → 10 | Rhythm check; if still non-shockable, return to Box 10 (next epinephrine dose) | Epi every 3–5 min approximated by every second cycle ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| any time | Box 10/11 exit | If the rhythm becomes shockable → proceed to **Box 5 (shock)** and switch to the shockable path | [Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf) |
| ongoing | Boxes 10/11 loop | 2-min cycles, reversible causes, epinephrine every 3–5 min, compressor switch every ~2 min | ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) |
| ROSC | Box 12 | → post–cardiac arrest care | [Part 11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care) |

**What this reconstruction deliberately does not show:** exact seconds for pauses, a pre-charge step, a fixed number of adrenaline doses, or a mandatory point-of-care ultrasound pause. None of those are specified in the 2025 AHA text used here.

---

## 5. Implications for the app

This section is **design inference**, not guideline text. Where a design choice is constrained by a guideline fact, the fact is cited; the rest is a recommendation for the product team to review.

**Current product decisions (2026-10-24):** the guideline standard is selectable in app settings (ERC 2025 default for German installs, AHA 2025 selectable); each case snapshots the selection and the resolved values. Shock energy is optional and may be reconciled later from the defibrillator/ECG device log; every rhythm analysis must record its result; ROSC is recorded when observed but is not a required field.

### 5.1 Event types to record

Model these as first-class, timestamped events rather than free-text notes. Proposed names are English; German UI labels are suggestions only and must go through `lib/l10n/app_de.arb`.

| Event | Payload | Why it matters |
| --- | --- | --- |
| `arrestRecognised` | who, witnessed (yes/no/unknown), location | Anchors "time since arrest" when known |
| `cprStarted` | start of first compression | Anchors the resuscitation clock |
| `compressionSegment` | start, end, compressor ID (optional) | Needed for CCF and compressor-switch timing |
| `compressionPause` | start, end, reason (rhythm check, shock, airway, other) | Needed for perishock pause and no-flow time |
| `rhythmCheck` | time, result (`vf`, `pvt`, `asystole`, `pea`, `organised`, `rosc`, `unknown`), pulse (`present`/`absent`/`not checked`), duration | **Required:** the analysis result drives the algorithm branch, the 2-min cadence, and the protocol |
| `shock` | time, sequence number, energy (J, optional), waveform (optional), pads position (optional), sync/unsync | Sequence matters for amiodarone timing; energy is device-specific and can be reconciled from the defibrillator/ECG device log later |
| `medication` | time, drug, dose, unit, route (IV/IO), diluent | Epinephrine interval and amiodarone dose count are derived from this |
| `vascularAccess` | time, type (IV/IO/CVC), site, success | Explains route and delays |
| `airway` | time, type (BVM/SGA/ETT), confirmation method, capnography | Changes ventilation target to 1 breath/6 s |
| `compressorChange` | time, outgoing/incoming rescuer | 2-min switch audit |
| `etco2Observation` | time, value (mmHg), source | Trend, ROSC signal, CPR-quality signal |
| `reversibleCause` | time, cause (H/T), status (suspected/treated/ruled out) | Checklist, not a timer |
| `pocus` | time, start/end, findings | Must be paired with a pause record to prove no interruption |
| `rosc` | time (optional), confirming signs (pulse, ETCO₂ rise, arterial waveform, consciousness/purposeful movement) | Record when observed; closes the arrest phase and anchors the post-ROSC timeline. Not required — first responders may hand off before ROSC. |
| `postRoscIntervention` | 12-lead ECG, MAP, SpO₂, PaCO₂, temperature target, glucose | Immediate post-ROSC targets |
| `torDecision` | time, rule used, ETCO₂ value, rationale | Termination is multimodal; ETCO₂ alone is not enough |
| `debriefNote` | free text | Quality improvement |

**Core protocol record:** the result of every rhythm analysis is the primary clinical record. Shocks, medications, compressions, and pauses are supporting events. ROSC is recorded when observed but must not be required: professional first responders may hand off before ROSC or may not be responsible for confirming it. Shock energy is optional; it can be filled in later from the defibrillator/ECG device log.

### 5.2 Timestamp semantics

The app must separate three concepts, because resuscitation documentation is frequently retrospective:

1. **Occurred-at (wall clock, with UTC offset):** when the event happened on the clock. Required for export and for matching monitor/defibrillator logs.
2. **Recorded-at:** when the user entered it. Always later than or equal to occurred-at; a large gap indicates a documentation delay that should be visible in debriefs.
3. **Elapsed offset:** seconds since a defined anchor (arrest recognition, or first compression if recognition time is unknown).

Recommended rules:

- Store `occurredAt` as UTC plus the case's UTC offset, and store `elapsedMs` from a monotonic clock (Android `SystemClock.elapsedRealtime()`), not from wall clock arithmetic. Wall clocks jump on NTP sync, timezone changes and manual edits; monotonic clocks do not.
- Anchor all derived intervals to one explicit `clockAnchor` event per case. If the anchor is "first compression", label every offset as "since first compression", never as "since arrest".
- Order events by `occurredAt`, tie-break by a monotonically increasing `sequence` assigned at creation. Do not reorder on edit.
- Support "event occurred N minutes ago" quick entry, but write both `occurredAt` (back-dated) and `recordedAt` (now); never silently rewrite history.
- Show relative time (`T+04:12`) in the live view and absolute time (`14:32:10`) in the report, with a toggle.
- Treat "unknown" as a first-class value. Do not default a missing rhythm check to "asystole" or a missing pulse to "absent".

### 5.3 Derived intervals the app can compute

| Derived value | Definition | Used for |
| --- | --- | --- |
| Cycle length | CPR start → next rhythm check | Auditing the 2-min cadence |
| Compression pause | Compression stop → compression restart | Pre-shock/post-shock pause, no-flow time |
| Perishock pause | Last compression before shock → first compression after shock | CPR-quality feedback |
| Chest compression fraction | Sum of compression segments ÷ resuscitation duration | ≥ 60 % minimum; > 80 % stretch target |
| Time to first compression | Arrest recognised → first compression | Process measure |
| Time to first shock | Arrest recognised (or first compression) → shock 1 | Process measure |
| Shock-to-shock interval | Shock n → shock n+1 | Cadence audit |
| Time to first epinephrine | Anchor → first epinephrine | Timing audit |
| Epinephrine interval | Dose n → dose n+1 | 3–5 min window |
| Time to amiodarone | Anchor → first amiodarone | "After third shock" audit |
| Time to ROSC | Anchor → ROSC (when recorded) | Outcome and debrief, if available |
| Post-ROSC time to ECG / target | ROSC → ECG, ROSC → temperature target | Post-ROSC bundle audit |

### 5.4 Validation rules (advisory, not blocking)

*Rows marked "(ERC mode)" apply only when the case baseline is ERC 2025 and replace the corresponding AHA rule.*

| Rule | Suggested behaviour | Basis |
| --- | --- | --- |
| Pulse check longer than 10 s | Warn at 10 s, require a reason to continue. This is an AHA limit; ERC 2025 gives no 10-s pulse-check limit | 1 / C-LD ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)); [ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Compression pause longer than 10 s | Warn; show accumulated pause time | AHA gives no numeric pause cap; the 10-s figure is the pulse-check limit, so this is an audit flag, not a guideline limit. ERC sets a < 5 s peri-shock target, not a 10-s cap ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support); [ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| CCF below 60 % | Warn at case end and in debrief | 2b / C-LD ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) |
| CCF above 80 % | Display as "high-performance range", not as a pass/fail | Supportive text ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)) |
| Epinephrine interval < 3 min or > 5 min | Warn; require confirmation | 2a / B-R ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| Epinephrine before the second shock in a shockable arrest | Informational flag, not a block | Algorithm Box 6 ([Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)) |
| Amiodarone before the third shock | Informational flag | Algorithm Box 8 ([Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)) |
| Third amiodarone dose | Warn: the algorithm lists a first and second dose only | [Algorithm, Drug Therapy](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf) |
| Epinephrine after the second shock in a shockable arrest (ERC mode) | Informational flag: ERC 2025 gives the first dose after the **third** shock | [ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Lidocaine dose inconsistent with the selected policy | Warn: AHA uses weight-based 1–1.5 / 0.5–0.75 mg/kg; ERC uses fixed 100 mg / 50 mg | [Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support); [ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| First shock below 150 J in ERC mode (non-pulsed biphasic) | Warn; ERC floor is at least 150 J; pulsed biphasic 130–150 J | [ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Peri-shock pause above 5 s in ERC mode | Flag as a quality metric; do not present 5 s as an AHA limit | [ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Pulse check prompted at recognition in ERC mode | Suppress; the ERC BLS recognition sequence uses unresponsiveness + abnormal breathing, not a pulse check | [ERC BLS p. 2](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf) |
| ETCO₂ rise used as the only ROSC sign in ERC mode | Warn; require a combination of clinical/physiological signs and do not stop compressions on ETCO₂ alone | [ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf), [p. 9](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Post-ROSC SpO₂ 90–93 % in ERC mode | Flag; ERC target is 94–98 % | [ERC-ESICM post-ROSC p. 4](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf) |
| Post-ROSC MAP 60–64 mmHg in ERC mode | Do not flag as below target; ERC target is > 60–65 mmHg | [ERC-ESICM post-ROSC p. 6](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf) |
| ERC temperature mode configured as one 32–37.5 °C band | Warn: ERC uses fever avoidance ≤ 37.5 °C and does not actively warm comatose patients at 32–36 °C | [ERC-ESICM post-ROSC p. 7](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf) |
| AHA ETCO₂ TOR rule applied in ERC mode | Disable or flag as AHA-only; ERC requires a locally validated TOR rule | [ERC ALS p. 16](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Rhythm check without a result | Require a result or an explicit "unknown" | The analysis outcome drives the algorithm branch and the protocol ([Algorithm description](https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf)) |
| Shock without energy | Allow save; energy is optional and flagged for later reconciliation with the defibrillator/ECG device log | Device-specific energy; the timing record does not depend on joules ([Part 9 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |
| ROSC recorded without a confirming sign | Prompt for pulse/ETCO₂/arterial waveform; in ERC mode also accept consciousness/purposeful movement as part of the combination. ROSC itself stays optional | 2b / B-NR ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)); [ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf) |
| Post-ROSC MAP < 65 mmHg | Flag | 1 / B-R ([Part 11 §5](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)) |
| Post-ROSC SpO₂ < 90 % or > 98 % | Flag | 2a / B-R ([Part 11 §4.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)) |
| Post-ROSC PaCO₂ outside 35–45 mmHg | Flag | 1 / B-R ([Part 11 §4.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)) |
| Temperature target outside 32–37.5 °C | Block configuration, not the case record | 1 / B-R ([Part 11 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)) |
| ETCO₂ used as the only TOR criterion | Warn | 2b / C-LD; ETCO₂ must not be used in isolation ([Part 9 §13](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)) |

### 5.5 Protocol fields to make configurable

`guidelineEdition` (settings label: “Guideline standard”) selects a profile; individual fields may be overridden, but every override must be stored with the case so the record shows which baseline and which deviations were used. The defaults below are the app defaults; where the two editions differ, the AHA and ERC values are both shown. The ERC 2025 profile details are in §3.9.

| Field | Type | Default / profile values | Notes |
| --- | --- | --- | --- |
| `guidelineEdition` | enum/string | ERC 2025 (German default) | Selected in app settings; store per case; never migrate old cases silently. `AHA 2025` and `ERC 2025` are first-class profiles |
| `locale` | enum | de | The app is German, but the guideline standard is an explicit settings choice and must not be inferred from locale at case time |
| `institution` | string | empty | For local HP-CPR protocol |
| `cycleSeconds` | int | 120 | 2-min CPR cycle in both editions |
| `compressorSwitchSeconds` | int | 120 | Or "5 cycles of 30:2". ERC 2025 does not state a separate interval; keep 120 s as the AHA default and a local quality convention ([ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `ccfTargetMin` / `ccfTargetStretch` | int | 60 / 80 (AHA) or 60 / empty (ERC) | 60 is a recommendation in both editions; 80 is AHA supportive text, not an ERC target ([ERC BLS p. 15](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf)) |
| `epinephrineFirstDosePolicy` | enum | per rhythm: `nonShockableAsap`; `shockableAfterSecondShock` (AHA) or `shockableAfterThirdShock` (ERC) | Values: `nonShockableAsap`, `shockableAfterSecondShock` (AHA), `shockableAfterThirdShock` ([ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `epinephrineIntervalSeconds` | range | 180–300 | 3–5 min in both editions |
| `antiarrhythmic` | enum | amiodarone | Or lidocaine, or none |
| `lidocaineDosePolicy` | enum | `weightBased` (AHA) or `fixed100_50` (ERC) | `weightBased` (AHA 1–1.5 then 0.5–0.75 mg/kg) or `fixed100_50` (ERC 100 mg then 50 mg) ([ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `amiodaroneMaxDoses` | int | 2 | Both editions list 2 doses; ERC ties the second dose to shock 5 ([ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `defibrillatorModel` / `energyPolicy` | string / list | empty (optional) | Energy is manufacturer-specific; recording joules is optional |
| `firstShockEnergyMin` | int | 120 J (AHA) or 150 J (ERC) | ERC requires ≥ 150 J for non-pulsed biphasic and 130–150 J for pulsed biphasic ([ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `periShockPauseTargetSeconds` | int | empty (AHA: "as short as possible") or 5 (ERC) | ERC sets a < 5 s target; display as a quality metric, not a hard stop ([ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `pulseCheckAtRecognition` | bool | true (AHA) or false (ERC) | ERC BLS recognition has no pulse check; suppress the prompt in ERC mode ([ERC BLS p. 2](https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf)) |
| `ventilationMode` | enum | `ratio30to2` / `advancedAirway10PerMin` | Changes with airway |
| `etco2TargetPolicy` | enum | `aha10_20` (AHA) or `ercTrendOnly` (ERC) | `aha10_20` (≥ 10, ideally ≥ 20 mmHg) or `ercTrendOnly` (no general target; optional ≥ 25 mmHg in physiology-guided CPR) ([ERC ALS pp. 9, 32](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `postRoscSpo2Range` | range | 90–98 % (AHA) or 94–98 % (ERC) | ([ERC-ESICM p. 4](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf)) |
| `postRoscPaco2Range` | range | 35–45 mmHg | Same in both editions |
| `postRoscMapMin` | int | 65 mmHg (AHA) or 60 mmHg (ERC) | ERC target > 60–65 mmHg; the ERC algorithm's immediate box says SBP > 100 mmHg ([ERC-ESICM p. 6](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf); [ERC ALS Fig. 2 p. 5](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `temperatureStrategy` | enum | `aha32to37_5` (AHA) or `ercFeverAvoidance` (ERC) | `aha32to37_5` or `ercFeverAvoidance` (≤ 37.5 °C, do not actively warm 32–36 °C) ([ERC-ESICM p. 7](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf)) |
| `temperatureRange` / `temperatureDurationHours` | range / int | 32–37.5 °C / 36 h | Used only with `aha32to37_5`; ERC uses `temperatureStrategy` |
| `torPolicy` | enum | unset (must be configured) | Values: `bls`, `als`, `universal`, `institutional`; plus "ETCO₂ only as component". ERC requires a locally validated rule; the AHA ETCO₂ rule is AHA-only ([ERC ALS p. 16](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)) |
| `promptMode` | enum | `advisory` / `silent` | Never hard-block clinical care |

**Settings behavior**

- The “Guideline standard” setting offers **ERC 2025** (default for German installs) and **AHA 2025**.
- The selected standard preselects the dependent values: adrenaline trigger, lidocaine policy, first-shock energy floor, peri-shock pause target, pulse-check-at-recognition, ETCO₂ policy, post-ROSC ranges, temperature strategy, and TOR policy.
- A case snapshots the standard and all resolved values at start. Changing the setting never rewrites an open or completed case.
- Advanced overrides are allowed but must be shown in the protocol and export as deviations from the selected standard.
- The protocol header shows the selected standard and any overrides.

### 5.6 German UI terms (suggestions for `app_de.arb`)

| English | German suggestion | Note |
| --- | --- | --- |
| Rhythm check / rhythm analysis | Rhythmusanalyse | Records the result of each analysis |
| Shock / defibrillation | Schock / Defibrillation | — |
| Epinephrine | Adrenalin | AHA uses epinephrine; German clinical usage is Adrenalin |
| Amiodarone | Amiodaron | — |
| Lidocaine | Lidocain | — |
| Chest compressions | Thoraxkompressionen | — |
| Compression fraction | Kompressionsfraktion (CCF) | — |
| Pause / interruption | Unterbrechung | — |
| Cycle | Zyklus (2-Minuten-Zyklus) | — |
| Reversible causes | Reversible Ursachen (5 H und 5 T) | — |
| ROSC | ROSC (Wiedererlangung eines Spontankreislaufs) | Keep the acronym visible |
| Post-ROSC care | Post-ROSC-Versorgung | — |
| Termination of resuscitation | Abbruch der Reanimation | — |

### 5.7 Open questions for clinical review

1. **Which standard governs?** Both AHA 2025 and ERC 2025 are selectable in app settings (decision 2026-10-24), with ERC 2025 as the default for German installs and AHA 2025 selectable. Clinical review must confirm the default for the target services and the override policy. A local HP-CPR protocol still overrides both.
2. **Is the app a medical device?** If it issues prompts or calculates doses, regulatory classification (EU MDR) needs a separate assessment. This note makes no legal claim.
3. **Enforce or advise?** Should the app block a shock without energy, or only warn? AHA guidance is not a software specification.
4. **Epinephrine timing in shockable arrest:** follow the figure (after shock 2) or the recommendation text ("after initial defibrillation attempts have failed")? They agree in spirit but differ in precision.
5. **Amiodarone after the third shock:** confirm against the printed 2025 figure and the local protocol; the accessible description gives the box sequence but not every arrow.
6. **Pediatric and neonatal scope:** explicitly out of scope here; separate research needed.
7. **Data export:** should cases export in Utstein style for registries? That affects the event model and timestamp precision.
8. **Offline clock reliability:** what is the fallback if the device clock is wrong and no monitor log is available?
9. **Epinephrine in shockable arrest:** AHA after shock 2 vs ERC after shock 3. Confirm the German default; a one-cycle difference changes the first-dose timestamp and the audit rule ([ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)).
10. **Lidocaine dosing:** AHA weight-based vs ERC fixed 100 mg / 50 mg. Confirm whether the app should calculate a weight-based dose or only record the administered dose ([ERC ALS p. 8](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)).
11. **Post-ROSC targets:** ERC SpO₂ 94–98 % and MAP > 60–65 mmHg vs AHA 90–98 % and MAP ≥ 65 mmHg. Which band should the handoff report display, and should the app show a target at all for first responders? ([ERC-ESICM pp. 4–6](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf))
12. **Post-ROSC temperature:** ERC's fever-avoidance strategy vs AHA's 32–37.5 °C band. Confirm whether temperature is in scope before adding a strategy switch ([ERC-ESICM p. 7](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf)).

---

## 6. Sources

All URLs accessed **2026-10-24**.

| ID | Source | URL | Notes |
| --- | --- | --- | --- |
| S1 | AHA 2025 Guidelines, Part 9: Adult Advanced Life Support | https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support | Sections 2, 5–14 used; published 2025-10-21 |
| S2 | AHA 2025 Guidelines, Part 7: Adult Basic Life Support | https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support | Sections 6–8 used |
| S3 | AHA 2025 Guidelines, Part 11: Post–Cardiac Arrest Care | https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care | Sections 4–8 used |
| S4 | AHA 2025 Guidelines, Part 1: Executive Summary | https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary | Sections 8 and 10 used for changes and knowledge gaps |
| S5 | 2025 Adult Cardiac Arrest Algorithm (Figure 2), PDF | https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-250527.pdf | Drug doses, energy, H's and T's; retrieved via Internet Archive copy |
| S6 | 2025 Adult Cardiac Arrest Algorithm, accessible long description | https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Accessible/Algorithm-ACLS-CA-LngDscrp-250725-Ed.pdf | Box-by-box sequence; retrieved via Internet Archive copy |
| S7 | 2025 Adult Cardiac Arrest Circular Algorithm, PDF | https://cpr.heart.org/-/media/CPR-Files/CPR-Guidelines-Files/2025-Algorithms/Algorithm-ACLS-CA-Circular-250620.pdf | Listed for completeness; no claim in this note depends on it |
| S8 | AHA Guideline and Focused Update Highlights | https://cpr.heart.org/en/resuscitation-science/guidelines-updates-and-highlights | Currency check |
| S9 | 2020 AHA Guidelines, Part 3: Adult Basic and Advanced Life Support | https://web.archive.org/web/20241212152314/https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-and-advanced-life-support | Used only for the 2020 comparison; archived 2024-12-12 |
| S10 | Crossref metadata, Part 9 | https://doi.org/10.1161/CIR.0000000000001376 | Publication date 2025-10-21 |
| S11 | Crossref metadata, Part 7 | https://doi.org/10.1161/CIR.0000000000001369 | Publication date 2025-10-21 |
| S12 | Crossref metadata, Part 11 | https://doi.org/10.1161/CIR.0000000000001375 | Publication date 2025-10-21 |
| S13 | Crossref metadata, 2020 Part 3 | https://doi.org/10.1161/CIR.0000000000000916 | Publication date 2020-10-20 |
| S14 | ERC 2025 Guidelines, Adult Advanced Life Support | https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf | Resuscitation 2025;215(suppl 1):110769; pp. 5–17, 32–34 used |
| S15 | ERC 2025 Guidelines, Adult Basic Life Support | https://www.erc.edu/media/wrhj5sye/gl2025-04-bls-e.pdf | Resuscitation 2025;215(suppl 1):110771; pp. 2, 4, 15 used |
| S16 | ERC–ESICM 2025 Guidelines, Post-Resuscitation Care | https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf | Resuscitation 2025;215(suppl 1):110809; pp. 4–7 used |
| S17 | ERC 2025 Guidelines, Executive Summary | https://www.erc.edu/media/ad5dtph1/gl2025-01-exec-e.pdf | Resuscitation 2025;215(suppl 1):110770; launch and edition context |
| S18 | ERC 2025 Adult ALS algorithm (Figure 2) | https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf | p. 5; reversible causes, drug timing and immediate post-ROSC box |
| S19 | ERC Guidelines 2025 hub | https://www.erc.edu/science-research/guidelines/guidelines-2025/guidelines-2025-english/ | Currency check; launch date 2025-10-22 |
| S20 | Corrigendum to the ERC 2025 ALS guideline | https://doi.org/10.1016/j.resuscitation.2026.111313 | Resuscitation 2026;229:111313; published 2026-09-16; no change to the timing, drugs or targets used here |

**Access note:** `cpr.heart.org` PDF URLs returned HTTP 403 to direct requests from this environment. The AHA PDFs were obtained from Internet Archive captures of the same AHA URLs; the HTML guideline pages were read live. The ERC PDFs were downloaded directly from `erc.edu` (HTTP 200). The *Resuscitation* full-text pages returned HTTP 403, so the ERC DOI links are for provenance and the page-level ERC citations refer to the official ERC PDFs; no Internet Archive copy was needed for the ERC documents. If the app's clinical reviewers need the authoritative files, download them from AHA and ERC directly in a normal browser.

---

## 7. Uncertainties / requires clinical review

> **This note is design research, not medical advice.** It summarises the 2025 AHA and ERC guidelines as two selectable profiles for software design. Every interval, dose and target must be reviewed and signed off by the clinical owner of the product before it appears in a user-facing protocol or prompt.

### 7.1 Evidence uncertainties in the guidance itself

| Uncertainty | What the source says | Consequence for the app |
| --- | --- | --- |
| The 2-minute cycle | The AHA lists "the optimal time interval for duration of chest compressions after shock delivery and prior to reassessing rhythm" as a knowledge gap ([Part 1 §8.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary)). | Treat 120 s as a configurable convention, not a biological constant. Allow local overrides. |
| Epinephrine interval | Trials used 1 mg every 3–5 min; the optimal number of doses is a knowledge gap ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). | Do not enforce a maximum dose count. |
| Epinephrine benefit | Improves ROSC and admission survival; limited evidence for discharge survival or neurological outcome ([Part 9 §10](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). | Avoid language that presents epinephrine as a proven neuroprotective intervention. |
| Amiodarone/lidocaine | Improved admission survival, not discharge survival; no proven difference between the two ([Part 9 §11](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). | Record the drug given; do not rank one as superior in UI copy. |
| ETCO₂ thresholds | Associational; no validated target, and values are confounded by ventilation, drugs and aetiology ([Part 9 §12](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). | Show trends, not pass/fail thresholds. |
| Post-ROSC temperature | Wide recommended range (32–37.5 °C); the optimal target and duration remain uncertain ([Part 11 §7](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/post-cardiac-arrest-care)). | Make the target an institutional setting. |
| Compression fraction | ≥ 60 % is a minimum; > 80 % is described for high-performance teams, not as a recommendation ([Part 7 §7.2](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-basic-life-support)). | Do not display 80 % as "required". |

### 7.2 Uncertainties in this research

1. **Selectable standards.** AHA 2025 and ERC 2025 are both first-class profiles (decision 2026-10-24), selectable in app settings and snapshotted per case; ERC is the default for German installs. The material differences are recorded in §3.9. They are operational, not evidence disputes: epinephrine after shock 2 vs 3; lidocaine weight-based vs fixed; first-shock energy 120–200 J vs ≥ 150 J; pulse check at recognition; ETCO₂ targets; post-ROSC SpO₂/MAP/temperature; TOR ([ERC ALS](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf); [ERC-ESICM post-ROSC](https://www.erc.edu/media/atqopqm4/gl2025-07-post-resus-e.pdf)). These need clinical sign-off, not more literature review.
2. **Algorithm arrows.** The accessible description gives the box sequence but not every exit arrow (notably after Box 8). The printed figure and the AHA ACLS provider manual should be checked during clinical review.
3. **Publication currency.** The "no 2026 update" finding is a negative check of the AHA and ERC index pages on one date. A focused update could be published without appearing there immediately.
4. **PDF access.** The AHA algorithm PDFs were read from Internet Archive captures of the official AHA URLs; the ERC PDFs were read directly from `erc.edu`. The clinical reviewer should confirm against the official downloads, because a captured or cached file could in principle lag the live version.
5. **No local protocol.** This note does not know the institution's HP-CPR protocol. Any local target that is stricter than the selected baseline (for example a higher CCF target, a fixed epinephrine cycle, or a different compression pause limit) must be sourced separately and versioned.
6. **Regulatory and liability.** Whether timed prompts make the app a medical device, and what disclaimers are required, is a legal question outside this research.
7. **Human factors.** The evidence here says nothing about whether clinicians want a timer, a metronome, a checklist, or silence. That needs usability research with resuscitation teams.
8. **Internal source conflict (example).** The 2025 Executive Summary quotes the AF/flutter cardioversion energy recommendation as COR 2b, LOE C-LD, while the Part 9 recommendation table gives the atrial fibrillation recommendation as COR 2a, LOE B-R (and flutter as 2b, C-LD) ([Part 1 §10.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/executive-summary); [Part 9 §18.1](https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/adult-advanced-life-support)). This does not affect arrest timing, but it shows why the app should cite the specific Part rather than the summary, and why a clinical reviewer must arbitrate when AHA documents disagree.

### 7.3 Things this note deliberately does not claim

- That either the 2025 AHA algorithm or the 2025 ERC algorithm is the legal standard of care in Germany.
- That one edition should be the default for every service, or that the two editions should be blended within a case.
- That any specific pause duration (other than the 10-second AHA pulse check and the 5-second ERC peri-shock target) is a guideline limit ([ERC ALS p. 7](https://www.erc.edu/media/vedoa2ga/gl2025-05-als-e.pdf)).
- That amiodarone is superior to lidocaine, or vice versa.
- That a CCF above 80 % is required.
- That ETCO₂ can be used alone to terminate resuscitation.
- That the app should enforce any of these values at the point of care.

---

*Prepared as design research for the HP-CPR companion app. No application code, `AGENTS.md`, `README.md` or `docs/agents/` files were modified. Not committed.*
