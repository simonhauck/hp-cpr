# AGENTS.md

## Project

Flutter companion app for the High-Performance CPR standard. The app supports the resuscitation workflow with timing and sequence information.

## Commands

If the environment is not already active via `nix develop` or direnv:

```bash
nix develop --command flutter <command>
```

Quality checks before wrapping up:

```bash
flutter analyze
flutter test
```

Builds:

```bash
flutter build web --release
flutter build apk --debug
```

## Issues

- Link every sub-issue to its parent spec in GitHub: `gh issue create --parent <parent> ...`, or `gh issue edit <parent> --add-sub-issue <child>` for an existing issue. Use a `Part of #<parent>` line only when native sub-issues are unavailable.
- Express dependencies with GitHub's native blocked-by relation: `gh issue edit <child> --add-blocked-by <blocker>`, or `gh issue create --blocked-by <blocker> ...`. Do not record a dependency only as prose.
- Remove stale relations with `--remove-sub-issue` / `--remove-blocked-by`.

## Commits

All commits follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Use the imperative mood, lowercase, and no trailing period: `feat(timer): add cycle countdown`.
- Keep the subject at 72 characters or fewer.
- Mark breaking changes with `!` after the type/scope and explain them in a `BREAKING CHANGE:` footer.
- Commit messages and PR descriptions are English; user-facing UI strings stay German (see below).

## Pull requests

- PR titles use the same Conventional Commits format, since a squash merge turns the title into the commit message.
- In the PR body, link every issue the PR fully resolves with its own closing keyword: `Closes #12`, `Fixes #34`, `Resolves #56`. GitHub closes these issues automatically when the PR merges into the default branch.
- Use `Part of #12` when the PR only contributes to an issue; this does not auto-close it.
- In addition to the `/pr` skill template, end the body with a `## Related issues` section containing those links.

## UI language

- The entire visible interface is German.
- No hardcoded UI text: add new strings to `lib/l10n/app_de.arb` and run `flutter gen-l10n`.
- The generated `app_localizations*.dart` files are versioned.
- The app is currently pinned to `Locale('de')` in `lib/app.dart`.

## Code language

- Domain nouns from `GLOSSARY.md` keep their German term in code identifiers: `Reanimationsfall`, `Startzeit`, `Druckphase`, `Leitlinienprofil`.
- Technical scaffolding and framework concepts stay English: `Clock`, `Settings`, `Page`, `Snapshot`, `Chip`, `Timer`.
- Methods and tests use English verbs with the German domain nouns: `startReanimationsfall`, `enterAnalysephase`.
- L10n keys stay English identifiers; their values are German.
- See `docs/adr/0001-german-domain-terms-in-code.md`.

## Platforms

- Android and web are the active targets.
- iOS will only be added once macOS/Xcode is available. Do not create iOS platform files on Linux.
- The Nix dev shell includes Android SDK 36, Build-Tools 36.0.0, and NDK 28.2. After a Flutter upgrade, check the versions in `flake.nix` and run `flutter doctor -v`.

## Architecture

- Feature-first structure under `lib/features/<feature>/presentation/`.
- Cross-feature UI infrastructure lives under `lib/ui/`; feature-specific UI stays under `lib/features/<feature>/presentation/`.
- Do not invent CPR domain logic; the concrete HP-CPR workflow is still being agreed on.
- Implement new features only after the domain requirements have been agreed.

## MCP

The Dart/Flutter MCP server is configured in `opencode.json` and started directly via `dart mcp-server`. OpenCode must therefore run from the Nix dev shell so that `dart` is on the `PATH`. If a shared OpenCode background service is already running outside the dev shell, use `opencode --standalone` or stop the service before starting and restart it inside the dev shell. After code changes to a running app, use hot reload or hot restart.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in this repo, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles with their default names (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and one `docs/adr/` at the repo root. See `docs/agents/domain.md`.
