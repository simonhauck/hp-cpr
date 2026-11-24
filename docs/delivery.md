# Delivery

How changes get from a pull request to the published app. The reasoning behind the release-gated site is recorded in [ADR 0002](adr/0002-release-gated-github-pages.md).

The public web app is available at <https://simonhauck.github.io/hp-cpr/>. It serves the latest GitHub Release, not `main`.

## Pull requests

Every pull request runs the same checks in CI:

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `flutter test --platform chrome`
- `flutter gen-l10n` plus a diff check on `lib/l10n`
- `flutter build web --release`
- `flutter build apk --release`
- Conventional PR title and exactly one type label

The type label follows the PR title:

| Title type | Label |
| --- | --- |
| `fix` | `bug` |
| `feat` | `feature` |
| `docs` | `documentation` |
| everything else | `maintenance` |

release-please PRs are exempt from the label check.

## Direct pushes and dependency updates

Direct pushes to `main` are allowed, but they are not checked before they land. Force pushes and deletions are blocked. The local pre-push hook (see [`development.md`](development.md#dev-shell)) catches most problems early.

Renovate merges minor, patch, pin, and digest updates directly into `main` once CI passes on its `renovate/**` branch. Major updates and failed automerges arrive as PRs labeled `dependencies` and `maintenance`.

## Releases

release-please keeps one release PR open. Merge it when you want to cut a release. Merging it bumps `pubspec.yaml` (including the `+build` number) and `CHANGELOG.md`; the CI/CD workflow then checks the merged commit, creates the `vX.Y.Z` tag and GitHub Release, deploys the release build to Pages, and attaches:

- `hp-cpr-<version>-debug-signed.apk`: release-mode, debug-signed, for testing only
- `hp-cpr-web-<version>.zip`

The release PR itself does not run CI because release-please uses `GITHUB_TOKEN`. The merged release commit is checked before anything is tagged or deployed.

Google Play publishing is out of scope until a developer account exists.

## Rollback

Revert the bad commit on `main` and merge a new release PR. The live page stays on the previous release until the new release is published. For the APK, use the previous GitHub Release asset. Play Store rollback will be documented with the Play workflow.
