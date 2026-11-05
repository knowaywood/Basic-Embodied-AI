import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

FONT_DIAG_RE = re.compile(r"warning: (?:unknown font family|variable font is not supported)")

_HOME = os.path.expanduser("~")

VSCODE_EXT_GLOBS = [
    # WSL / Unix 侧
    os.path.join(_HOME, ".vscode-server", "extensions", "myriad-dreamin.tinymist-*", "out", "tinymist"),
    os.path.join(_HOME, ".vscode", "extensions", "myriad-dreamin.tinymist-*", "out", "tinymist"),
    # Windows 原生侧（.exe）
    os.path.join(_HOME, ".vscode", "extensions", "myriad-dreamin.tinymist-*", "out", "tinymist.exe"),
    os.path.join(_HOME, ".vscode-server", "extensions", "myriad-dreamin.tinymist-*", "out", "tinymist.exe"),
    # 从 WSL 访问 Windows 插件（/mnt/c 视角）
    "/mnt/c/Users/*/.vscode/extensions/myriad-dreamin.tinymist-*/out/tinymist.exe",
    "/mnt/c/Users/*/.vscode-server/extensions/myriad-dreamin.tinymist-*/out/tinymist.exe",
]


def find_tinymist():
    env = os.environ.get("TINYMIST_BIN")
    if env and os.path.exists(env):
        return env

    found = shutil.which("tinymist")
    if found:
        return found

    for pattern in VSCODE_EXT_GLOBS:
        for path in sorted(glob.glob(pattern), reverse=True):
            if os.path.exists(path):
                return path

    return None


def has_real_diagnostics(output):
    for line in output.splitlines():
        if "error:" in line:
            return True
        if "warning:" in line and not FONT_DIAG_RE.search(line):
            return True
    return False


def main():
    files = sys.argv[1:]
    if not files:
        print("No files provided to the script.")
        return

    tinymist = find_tinymist()
    if not tinymist:
        print(
            "tinymist not found. Install the VS Code tinymist extension or run: "
            "cargo install tinymist --locked",
            file=sys.stderr,
        )
        sys.exit(1)

    # Chapters inherit heading numbering and other settings from their entrypoints.
    # Checking them in isolation reports errors that do not exist in either build.
    failed = 0
    if Path("main.typ").is_file():
        result = subprocess.run(
            [tinymist, "lint", "--root", ".", "--diagnostic-format", "short", "main.typ"],
            text=True,
            capture_output=True,
        )
        combined = (result.stdout or "") + (result.stderr or "")
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        if result.returncode != 0 or has_real_diagnostics(combined):
            print("[LINT FAILED] main.typ")
            failed += 1

    if Path("main_html.typ").is_file():
        with tempfile.TemporaryDirectory(prefix="typst-lint-") as temporary:
            try:
                result = subprocess.run(
                    [os.environ.get("TYPST", "typst"), "compile", "--features", "html,bundle",
                     "--format", "bundle", "--root", ".", "main_html.typ",
                     str(Path(temporary) / "site")],
                    text=True,
                    capture_output=True,
                )
            except OSError as error:
                print(f"Typst HTML check could not run: {error}", file=sys.stderr)
                failed += 1
            else:
                if result.returncode != 0:
                    print((result.stdout or "") + (result.stderr or ""), file=sys.stderr)
                    print("[LINT FAILED] main_html.typ")
                    failed += 1
                else:
                    print("[LINT PASSED] main_html.typ (HTML bundle)")

    if failed > 0:
        print(f"\nLinting failed on {failed} file(s). Please fix them and commit again.")
        sys.exit(1)


if __name__ == "__main__":
    main()
