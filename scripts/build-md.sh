#!/usr/bin/env bash
set -euo pipefail

PANDOC="${PANDOC:-pandoc}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/main.typ"
SITE_SOURCE="$ROOT/site-src"
TEMPORARY_MARKDOWN="$(mktemp)"
TEMPORARY_TYPST="$(mktemp)"
TEMPORARY_ADAPTED_TYPST="$(mktemp)"

SITE_BASE="/"
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  repository="${GITHUB_REPOSITORY#*/}"
  if [[ -n "$repository" && "$repository" != *.github.io ]]; then
    SITE_BASE="/$repository/"
  fi
fi
IMAGE_BASE="${SITE_BASE%/}/images/"

trap 'rm -f "$TEMPORARY_MARKDOWN" "$TEMPORARY_TYPST" "$TEMPORARY_ADAPTED_TYPST"' EXIT

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

# Site-specific counterparts of _symbols.typ keep bodies while omitting PDF
# layout, theorem numbering, and other Typst-only presentation.
awk '!/^#import "_symbols\.typ"/ && !/^#import "\.\.\/_symbols\.typ"/' "$TEMPORARY_TYPST" > "$TEMPORARY_ADAPTED_TYPST"
mv "$TEMPORARY_ADAPTED_TYPST" "$TEMPORARY_TYPST"

# Pandoc's Typst reader does not yet support table.header. Keep the source
# syntax intact and turn its cells into a regular first row for conversion.
sed -E -i 's/table\.header\((.*)\),/\1,/' "$TEMPORARY_TYPST"

# Normalize constructs the Typst reader does not translate into usable links.
sed -E -i \
  -e 's|@img:([[:alnum:]_-]+)|@\1|g' \
  -e 's|\)<img:([[:alnum:]_-]+)>|)<\1>|g' \
  "$TEMPORARY_TYPST"

cat "$ROOT/scripts/pandoc-symbols.typ" > "$TEMPORARY_ADAPTED_TYPST"
awk 'found || /^= / { found=1; print }' "$TEMPORARY_TYPST" >> "$TEMPORARY_ADAPTED_TYPST"
cat "$TEMPORARY_ADAPTED_TYPST" \
  | grep -v '^#pagebreak()$' \
  | "$PANDOC" --from=typst --to="$MARKDOWN_FORMAT" --wrap=none --output="$TEMPORARY_MARKDOWN"

# Repair small Pandoc Typst-reader gaps in its Markdown output.
perl -pi -e 's/\\\*([^*]+)\*\*/**$1**/g; s/\*\* +/**/g; s/ +\*\*/**/g; s/^\\<img:[^>]+\\>\n//; s{src="/images/}{src="'"$IMAGE_BASE"'}g;' "$TEMPORARY_MARKDOWN"
perl -pi -e '1 while s{(<img src="/images/[^" ]*) ([^"]*")}{$1%20$2};' "$TEMPORARY_MARKDOWN"

rm -rf "$SITE_SOURCE"
mkdir -p "$SITE_SOURCE/public"
touch "$SITE_SOURCE/public/.nojekyll"
if [[ -d "$ROOT/images" ]]; then
  cp -R "$ROOT/images" "$SITE_SOURCE/public/images"
fi

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
