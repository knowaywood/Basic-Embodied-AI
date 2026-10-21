import os
import re
import sys


def fix_typst_content(content):
    math_blocks = []

    def save_math(match):
        math_blocks.append(match.group(0))
        return f"__MATH_BLOCK_{len(math_blocks) - 1}__"

    protected_content = re.sub(r"(?<!\\)\$.+?\$", save_math, content, flags=re.DOTALL)

    protected_content = re.sub(r",(?=\S)", ", ", protected_content)

    punc = r".,!?;: )\]\}，。！？；：）】》"

    protected_content = re.sub(
        r"([^\s])(__MATH_BLOCK_\d+__)", r"\1 \2", protected_content
    )
    protected_content = re.sub(
        rf"(__MATH_BLOCK_\d+__)([^\s{punc}])", r"\1 \2", protected_content
    )

    def restore_math(match):
        idx = int(re.search(r"\d+", match.group(0)).group())
        return math_blocks[idx]

    return re.sub(r"__MATH_BLOCK_\d+__", restore_math, protected_content)


def main():
    files = sys.argv[1:]
    if not files:
        print("No files provided to the script.")
        return

    changed_files = 0
    for file_path in files:
        file_path = os.path.normpath(file_path)
        if not os.path.exists(file_path):
            continue

        with open(file_path, "r", encoding="utf-8") as f:
            original = f.read()

        fixed = fix_typst_content(original)

        if original != fixed:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(fixed)
            print(f"[FIXED] {file_path}")
            changed_files += 1
        else:
            print(f"[SKIPPED] {file_path} (No changes needed)")

    if changed_files > 0:
        print(
            f"\nSuccessfully formatted {changed_files} file(s). Please 'git add' them and commit again."
        )
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
