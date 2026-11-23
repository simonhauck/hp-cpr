#!/usr/bin/env bash
# Generates the public Datenschutz pages in web/ from the Markdown sources in
# assets/legal/. Needs Nix; pandoc is fetched ad hoc.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

build() {
  local source="$1" target="$2" title="$3"
  nix shell nixpkgs#pandoc --command pandoc \
    --from markdown --to html5 --standalone \
    --template "$root/tool/legal/template.html" \
    --metadata lang=de \
    --metadata "pagetitle=$title" \
    --output "$root/web/$target" \
    "$root/assets/legal/$source"
}

build datenschutz_web.md datenschutz.html "Datenschutzerklärung – HP-CPR (Web-App)"
build datenschutz_app.md datenschutz-app.html "Datenschutzerklärung – HP-CPR (App)"
