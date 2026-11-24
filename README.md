# HP-CPR Companion

A timekeeping app for the **Zeitnehmer** during an adult resuscitation, built around the **High-Performance CPR (HP-CPR)** standard.

HP-CPR is a team approach to resuscitation: every team member has a defined role, chest compressions run with as few interruptions as possible, and rhythm analyses, shocks, and drugs follow a fixed rhythm. One of those roles is the Zeitnehmer, who watches the clock and tells the team when the next action is due. This app replaces the stopwatch and the paper notes of that role. It shows what is due now, what comes next, and records what happened so the case can be reviewed afterwards.

**Try it:** <https://simonhauck.github.io/hp-cpr/> (latest release, runs in the browser). An Android APK for testing is attached to each [GitHub Release](https://github.com/simonhauck/hp-cpr/releases).

> [!WARNING]
> HP-CPR Companion is under active development. It is not a medical device and must not be used to treat patients.

## A Reanimationsfall in the app

The interface is German, and so are the domain terms used here. Their meaning is defined in the [glossary](GLOSSARY.md).

1. **Start.** The Zeitnehmer starts a new **Reanimationsfall** immediately or with a corrected **Startzeit**, for example when compressions began before the app was opened. When the team takes over a resuscitation that was already running, the **Übernahme** and the **Vorbehandlung** (Schocks and drug doses given before) are recorded as well.
2. **Druckphase.** Compressions run and a 2-minute countdown shows when the next Rhythmusanalyse is due.
3. **Analysephase.** Compressions pause for the **Rhythmusanalyse**. A guided dialog records whether the rhythm is *schockbar* or *nicht schockbar* and whether a **Schock** was delivered, then returns to the next Druckphase.
4. **Medikamente.** The app shows the **Zeitfenster** for the next **Adrenalin** Gabe and when **Amiodaron** should be considered, based on the selected **Leitlinienprofil** (ERC 2025 or AHA 2025). The phone vibrates when an action becomes due.
5. **ROSC and rearrest.** ROSC interrupts the resuscitation; a **Reanimationswiederbeginn** continues the same case if the patient rearrests.
6. **Messwerte and notes.** Blood pressure, heart rate, blood sugar, temperature, and free-text notes can be recorded at any time.
7. **End.** The case ends with a reason and an in-app summary, including the Reanimationsdauer and every Schock and Gabe.

Throughout the case, the **Protokoll** lists every recorded event. Mistakes are fixed with append-only **Korrekturen**: the original entry is never lost and stays visible in the **Änderungsverlauf**. Completed and **verworfene** cases are kept in the **Einsatzlog**.

All data stays on the device. There is no account, no server, and no network sync. A **Demo-Modus** lets you fast-forward a case to try the timing behaviour without waiting.

## Domain knowledge

- [`GLOSSARY.md`](GLOSSARY.md): the shared vocabulary of the app, code, and issues.
- [`docs/research/cpr-timing-guidelines.md`](docs/research/cpr-timing-guidelines.md): the AHA 2025 and ERC 2025 timing baselines the app is designed against.
- [`docs/adr/`](docs/adr/): architecture decisions, for example how Protokoll corrections and the Demo-Modus work.

## Platforms

| Platform | Status |
| --- | --- |
| Web | ✅ available |
| Android | ✅ available as a test APK; no Play Store release yet |
| iOS | ⏳ later, requires macOS with Xcode |

## Contributing

- **Development setup:** see [`docs/development.md`](docs/development.md) for the Nix dev shell, running the app, tests, and builds.
- **CI and releases:** see [`docs/delivery.md`](docs/delivery.md).
- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<optional scope>): <description>`, in English, imperative mood, lowercase, for example `feat(timer): add cycle countdown` or `fix(ui): wrap action button labels`. PR titles use the same format, because a squash merge turns the title into the commit message. release-please derives the version and the [changelog](CHANGELOG.md) from these messages.
- **Pull requests** link the issues they resolve with `Closes #<number>` (one keyword per issue).
- **Coding agents** and anyone who wants the full rules for issues, commits, PRs, naming, and layout: see [`AGENTS.md`](AGENTS.md).

## License

HP-CPR is released under the [MIT License](LICENSE).
