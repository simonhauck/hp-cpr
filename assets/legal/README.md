# Datenschutzerklärung

The privacy policy is written in German Markdown and is the single source for
the in-app page and the public pages.

| Source | Used for |
| --- | --- |
| `datenschutz_web.md` | Web app (in-app page when `kIsWeb`) and the public page `web/datenschutz.html` |
| `datenschutz_app.md` | Android app (in-app page) and the public page `web/datenschutz-app.html` |
| `impressum.md` | Impressum (§ 5 DDG), same for app and web: in-app page and the public page `web/impressum.html`. Contact data must match section 2 of the Datenschutzerklärung |

The text is based on the WBS privacy policy generator. The app variant omits the
website-only sections (server logfiles, GitHub, Google Fonts). Both variants
contain the section "Speicherung von Daten auf Ihrem Gerät", which must stay in
line with the code (local storage, backup behaviour in
`android/app/src/main/AndroidManifest.xml`).

The in-app renderer supports only the Markdown subset used here: `#`/`##`
headings, paragraphs, `**bold**`, and `[text](url)` links. Keep to that subset
when editing.

## Regenerating the public pages

After every change to a Markdown file, regenerate and commit the HTML:

```bash
tool/legal/build_pages.sh
```

The script needs Nix (it runs pandoc via `nix shell nixpkgs#pandoc`) and uses
`tool/legal/template.html` (inline CSS, no external resources).

## Public URLs

- Web variant: <https://simonhauck.github.io/hp-cpr/datenschutz.html>
- App variant (for the Google Play listing): <https://simonhauck.github.io/hp-cpr/datenschutz-app.html>
- Impressum: <https://simonhauck.github.io/hp-cpr/impressum.html>

GitHub Pages serves the latest GitHub Release, so the pages are live after the
next release.
