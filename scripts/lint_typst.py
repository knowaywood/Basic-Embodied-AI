import glob
import os
import re
import shutil
import subprocess
import sys

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

    failed = 0
    for file_path in files:
        file_path = os.path.normpath(file_path)
        if not os.path.exists(file_path):
            continue

        result = subprocess.run(
            [tinymist, "lint", "--root", ".", "--diagnostic-format", "short", file_path],
            text=True,
            capture_output=True,
        )
        combined = (result.stdout or "") + (result.stderr or "")
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)

        if has_real_diagnostics(combined):
            print(f"[LINT FAILED] {file_path}")
            failed += 1

    if failed > 0:
        print(f"\nLinting failed on {failed} file(s). Please fix them and commit again.")
        sys.exit(1)


if __name__ == "__main__":
    main()
