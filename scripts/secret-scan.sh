#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)

cd "$REPO_ROOT"

patterns='(/Users/[[:alnum:]_.-]+|/home/(?!root(?:/|\b))[[:alnum:]_.-]+|C:\\Users\\[[:alnum:]_.-]+|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|ghp_[[:alnum:]]{20,}|github_pat_[[:alnum:]_]{20,}|AKIA[[:alnum:]]{16}|sk-[[:alnum:]]{20,})'

if rg --hidden --pcre2 -n -I \
    --glob '!.git/**' \
    --glob '!build/**' \
    --glob '!.cache/**' \
    --glob '!dist/**' \
    --glob '!third_party/**' \
    --glob '!scripts/secret-scan.sh' \
    "$patterns" .; then
    echo "Potential secret or personal absolute path found." >&2
    exit 1
fi

echo "No common secrets or personal absolute paths found in project-owned files."
