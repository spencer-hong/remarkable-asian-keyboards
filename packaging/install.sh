#!/bin/sh
set -eu

DEVICE=${1:-root@10.11.99.1}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PAYLOAD="$SCRIPT_DIR/remarkable-east-asian-keyboard-payload.tar.gz"
REMOTE_ARCHIVE="/tmp/remarkable-east-asian-keyboard-payload.tar.gz"
REMOTE_DIR="/tmp/remarkable-east-asian-keyboard-installer"

if [ ! -f "$PAYLOAD" ]; then
    echo "Missing payload: $PAYLOAD" >&2
    exit 1
fi

echo "Copying the Korean, Japanese, and Chinese keyboard package to $DEVICE..."
echo "Use the current SSH password shown on your reMarkable. It is not saved."
scp "$PAYLOAD" "${DEVICE}:${REMOTE_ARCHIVE}"

echo
echo "Installing and restarting the reMarkable interface..."
echo "You may be asked for the same SSH password again."
# These fixed paths intentionally expand on the client before being sent.
# shellcheck disable=SC2029
ssh "$DEVICE" \
    "mkdir -p '$REMOTE_DIR' && tar -xzf '$REMOTE_ARCHIVE' -C '$REMOTE_DIR' && sh '$REMOTE_DIR/device-install.sh'"
