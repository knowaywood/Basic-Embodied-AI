import os
import re
import sys


PUNCTUATION = str.maketrans("，。；：！？", ",.;:!?")
def fix_content(content):
    translated = content.translate(PUNCTUATION)
    # Only space punctuation converted from Chinese; leave existing English punctuation alone.
    pieces = []
    last = 0
    for match in re.finditer(r"[，。；：！？][ \t]*(?=\S)", content):
        pieces.append(translated[last : match.start()])
        pieces.append(translated[match.start()] + " ")
        last = match.end()
    pieces.append(translated[last:])
    return "".join(pieces)


def main():
    changed = False
    for file_path in sys.argv[1:]:
        file_path = os.path.normpath(file_path)
        if not os.path.isfile(file_path):
            continue
        with open(file_path, encoding="utf-8", newline="") as file:
            original = file.read()
        fixed = fix_content(original)
        if fixed != original:
            with open(file_path, "w", encoding="utf-8", newline="") as file:
                file.write(fixed)
            print(f"[FIXED] {file_path}")
            changed = True
    return int(changed)


if __name__ == "__main__":
    sys.exit(main())
