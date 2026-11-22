# Live structural Protokoll corrections

**Status:** accepted

This supersedes the live edit-scope paragraph of [ADR 0005](0005-append-only-protokoll-corrections.md). Keeping structural entries read-only while the case is open made mis-taps in the Analysephase wizard unfixable exactly when they matter. Every structural entry (`Analysephasenbeginn`, `Rhythmusanalyse`, `Überspringung`, `DruckphaseNeustart`, `ROSC`, `Reanimationswiederbeginn`) can now be corrected in time, removed, and restored at any time. `Rhythmusanalyse` entries can also be corrected in result, but not to `ROSC`, which stays owned by the `ROSC` entry. This includes the entry that defines the current phase.

After every structural correction the live state (`zustand`, `Reanimationsphase`, compression cycle, pause, and Adrenalin trigger) is replayed from the effective structural entries as if the corrected history had happened. Events that do not fit the replayed state are ignored. Corrected structural times must stay between the neighbouring structural entries, so the replay order never changes.

Entering the Analysephase is recorded as its own Protokolleintrag "Analyse begonnen", separate from the result. Removing the current begin returns to the Druckphase and the earlier compression cycle continues. Removing only the result returns to the Analysephase with the pause counted from the begin. Removing a `ROSC` also removes the following `Reanimationswiederbeginn`; restoring restores both.

Corrections stay append-only and the Änderungsverlauf is unchanged.

**Considered options:** Keeping the lock was rejected because mis-taps stay unfixable while it matters. One Analyse unit of begin and result was rejected because removing only the result to redo the wizard is useful. Free reordering of times was rejected because it makes replays unpredictable. Keeping only mutable derived state was rejected because it cannot be rebuilt after a correction.

**Consequences:** Cases recorded before this change have no `Analysephasenbeginn` entries; a structural correction in such a case while it is in the Analysephase replays it into the Druckphase. `ReanimationsfallState` gains the `analysephaseBeginne` list, which decodes to empty when missing. The lock hint and lock icon in the Protokoll are removed.
