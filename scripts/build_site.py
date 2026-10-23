"""Generate VitePress pages from the Typst chapters."""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
SITE_SOURCE = ROOT / "site-src"
INCLUDE = re.compile(r'^\s*#include "src/([^"/]+\.typ)"\s*$', re.MULTILINE)
SYMBOL_IMPORT = re.compile(r'^#import "(?:\.\./)?_symbols\.typ".*$', re.MULTILINE)
FOOTNOTE = re.compile(r"^\[\^([^]]+)\]:")
FOOTNOTE_REF = re.compile(r"\[\^([^]]+)\]")


def chapter_paths() -> list[Path]:
    names = INCLUDE.findall((ROOT / "main.typ").read_text(encoding="utf-8"))
    if not names or len(names) != len(set(names)):
        raise ValueError("main.typ must include each chapter exactly once")
    paths = [ROOT / "src" / name for name in names]
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(path)
    return paths


def prepare_typst(paths: list[Path]) -> str:
    chapters = []
    for path in paths:
        chapter = path.read_text(encoding="utf-8")
        chapter = SYMBOL_IMPORT.sub("", chapter)
        chapter = re.sub(r"(?m)^#pagebreak\(\)\s*$", "", chapter)
        chapter = re.sub(r"table\.header\((.*)\),", r"\1,", chapter)
        chapter = re.sub(r"@img:([\w-]+)", r"@\1", chapter)
        chapter = re.sub(r"\)<img:([\w-]+)>", r")<\1>", chapter)
        chapter = re.sub(r"@tit:([\w-]+)", r"@tit-\1", chapter)
        chapter = re.sub(r"<tit:([\w-]+)>", r"<tit-\1>", chapter)
        chapters.append(chapter)
    symbols = (SCRIPTS / "pandoc-symbols.typ").read_text(encoding="utf-8")
    return symbols + "\n" + "\n".join(chapters)


def pandoc_format(pandoc: str) -> str:
    result = subprocess.run(
        [pandoc, "--list-extensions=gfm"], check=True, capture_output=True, text=True
    )
    suffix = "-tex_math_gfm" if re.search(r"(?m)^[+-]tex_math_gfm$", result.stdout) else ""
    return "gfm+tex_math_dollars" + suffix


def convert_typst(source: str, pandoc: str) -> str:
    result = subprocess.run(
        [
            pandoc,
            "--from=typst",
            f"--to={pandoc_format(pandoc)}",
            f"--lua-filter={SCRIPTS / 'pandoc-site.lua'}",
            "--wrap=none",
        ],
        input=source,
        text=True,
        capture_output=True,
        check=True,
    )
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    markdown = result.stdout
    markdown = re.sub(r"\\\*([^*]+)\*\*", r"**\1**", markdown)
    markdown = re.sub(r"\*\* +| +\*\*", "**", markdown)
    markdown = re.sub(r"(?m)^\\<img:[^>]+\\>\n", "", markdown)
    return markdown


def split_pages(markdown: str, paths: list[Path]) -> dict[str, str]:
    pages: list[list[str]] = []
    current: list[str] | None = None
    for line in markdown.splitlines(keepends=True):
        if line.startswith("# "):
            if current is not None:
                pages.append(current)
            current = []
        if current is not None:
            current.append(line)
    if current is not None:
        pages.append(current)
    if len(pages) != len(paths):
        raise ValueError(f"Expected {len(paths)} chapters, found {len(pages)}")

    definitions: dict[str, str] = {}
    for page in pages:
        kept: list[str] = []
        index = 0
        while index < len(page):
            match = FOOTNOTE.match(page[index])
            if not match:
                kept.append(page[index])
                index += 1
                continue
            end = index + 1
            while end < len(page) and (
                page[end].startswith((" ", "\t")) or not page[end].strip()
            ):
                end += 1
            definitions[match.group(1)] = "".join(page[index:end]).rstrip()
            index = end
        page[:] = kept

    output = {}
    for path, page in zip(paths, pages):
        body = "".join(page).rstrip() + "\n"
        needed = list(dict.fromkeys(FOOTNOTE_REF.findall(body)))
        missing = [key for key in needed if key not in definitions]
        if missing:
            raise ValueError(f"{path.name}: missing footnotes {', '.join(missing)}")
        if needed:
            body += "\n" + "\n\n".join(definitions[key] for key in needed) + "\n"
        output[path.with_suffix(".md").name] = body
    return output


def build() -> None:
    paths = chapter_paths()
    source = prepare_typst(paths)
    pandoc = os.environ.get("PANDOC", "pandoc")
    markdown = convert_typst(source, pandoc)
    pages = split_pages(markdown, paths)

    with tempfile.TemporaryDirectory(prefix="site-build-", dir=ROOT) as temporary:
        destination = Path(temporary) / "site-src"
        destination.mkdir()
        (destination / "public").mkdir()
        (destination / "public" / ".nojekyll").touch()
        if (ROOT / "images").is_dir():
            shutil.copytree(ROOT / "images", destination / "images")
        for name, content in pages.items():
            (destination / name).write_text(content, encoding="utf-8")
        if SITE_SOURCE.exists():
            shutil.rmtree(SITE_SOURCE)
        shutil.move(destination, SITE_SOURCE)
    print(f"Markdown generated in {SITE_SOURCE} ({len(pages)} pages)")


if __name__ == "__main__":
    try:
        build()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        if isinstance(error, subprocess.CalledProcessError) and error.stderr:
            print(error.stderr, file=sys.stderr, end="")
        else:
            print(f"Site build failed: {error}", file=sys.stderr)
        sys.exit(1)
