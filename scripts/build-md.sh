#!/usr/bin/env bash
set -euo pipefail

PANDOC="${PANDOC:-pandoc}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/main.typ"
SITE_SOURCE="$ROOT/site-src"
TEMPORARY_MARKDOWN="$(mktemp)"
TEMPORARY_TYPST="$(mktemp)"

trap 'rm -f "$TEMPORARY_MARKDOWN" "$TEMPORARY_TYPST"' EXIT

# Pandoc 3.10 enables GitHub's $`...`$ syntax by default. VitePress expects
# ordinary $...$ / $$...$$ delimiters; otherwise backticks become math symbols
# and fenced display formulas are treated as code. Older Pandoc lacks this flag.
MARKDOWN_FORMAT="gfm+tex_math_dollars"
if "$PANDOC" --list-extensions=gfm | grep -q '^[+-]tex_math_gfm$'; then
  MARKDOWN_FORMAT+="-tex_math_gfm"
fi

# Pandoc converts one self-contained Typst document. main.typ provides the
# shared document settings while the chapter sources live in src/.
awk '!/^#include "src\// { print }' "$SOURCE" > "$TEMPORARY_TYPST"
for chapter in index learning systems questions; do
  printf '\n' >> "$TEMPORARY_TYPST"
  cat "$ROOT/src/$chapter.typ" >> "$TEMPORARY_TYPST"
done

# Pandoc's Typst reader does not yet support table.header. Keep the source
# syntax intact and turn its cells into a regular first row for conversion.
sed -E -i 's/table\.header\((\[[^]]*\], \[[^]]*\], \[[^]]*\])\),/\1,/' "$TEMPORARY_TYPST"

awk 'found || /^= / { found=1; print }' "$TEMPORARY_TYPST" \
  | grep -v '^#pagebreak()$' \
  | "$PANDOC" --from=typst --to="$MARKDOWN_FORMAT" --wrap=none --output="$TEMPORARY_MARKDOWN"

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
