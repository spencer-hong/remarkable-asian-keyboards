#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)

for script in "$REPO_ROOT"/packaging/*.sh "$REPO_ROOT"/scripts/*.sh; do
    sh -n "$script"
done

python3 - <<'PY' "$REPO_ROOT"
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for path in sorted((root / "src" / "keyboard").glob("*_keyboard_layout.json")):
    with path.open(encoding="utf-8") as source:
        json.load(source)
print("Keyboard JSON: valid")
PY

node "$REPO_ROOT/tests/test_hangul.js"
"$SCRIPT_DIR/secret-scan.sh"

if rg -n '/Users/|Documents/Codex|work/paper-pure-korean' \
    "$REPO_ROOT/patches/KeyboardPanel.qml.patch"; then
    echo "The UI patch contains a local build path." >&2
    exit 1
fi

echo "Source checks passed."
