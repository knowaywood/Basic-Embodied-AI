#!/usr/bin/env bash
set -euo pipefail

PANDOC="${PANDOC:-pandoc}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/main.typ"
SITE_SOURCE="$ROOT/site-src"
TEMPORARY_MARKDOWN="$(mktemp)"

trap 'rm -f "$TEMPORARY_MARKDOWN"' EXIT

awk 'found || /^= / { found=1; print }' "$SOURCE" \
  | grep -v '^#pagebreak()$' \
  | "$PANDOC" --from=typst --to=gfm --wrap=none --output="$TEMPORARY_MARKDOWN"

rm -rf "$SITE_SOURCE"
mkdir -p "$SITE_SOURCE/public"
touch "$SITE_SOURCE/public/.nojekyll"

awk '
  /^# / {
    chapter += 1
    filenames[1] = "index.md"
    filenames[2] = "learning.md"
    filenames[3] = "systems.md"
    filenames[4] = "questions.md"
    output = site_source "/" filenames[chapter]
  }
  output != "" { print > output }
' site_source="$SITE_SOURCE" "$TEMPORARY_MARKDOWN"

echo "Markdown generated in $SITE_SOURCE ($(find "$SITE_SOURCE" -maxdepth 1 -name '*.md' | wc -l) pages)"
