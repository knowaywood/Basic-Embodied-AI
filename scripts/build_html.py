"""Build the chaptered HTML book with Typst and Manifesto."""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "dist"


def build() -> None:
    with tempfile.TemporaryDirectory(prefix="typst-html-", dir=ROOT) as temporary:
        destination = Path(temporary) / "site"
        subprocess.run([
            os.environ.get("TYPST", "typst"), "compile", "--features", "html,bundle",
            "--format", "bundle", "--root", str(ROOT),
            str(ROOT / "main_html.typ"), str(destination),
        ], check=True)
        shutil.copytree(ROOT / "images", destination / "images", dirs_exist_ok=True)
        (destination / ".nojekyll").touch()
        if OUTPUT.is_symlink():
            raise ValueError(f"Refusing to replace symlink: {OUTPUT}")
        if OUTPUT.exists():
            shutil.rmtree(OUTPUT)
        shutil.move(destination, OUTPUT)
    print(f"HTML chapters generated in {OUTPUT}")


if __name__ == "__main__":
    try:
        build()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"HTML build failed: {error}", file=sys.stderr)
        sys.exit(1)
