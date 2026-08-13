#!/bin/sh
set -eu

DEVICE=${1:-root@10.11.99.1}

echo "Removing the Korean, Japanese, and Chinese keyboards from $DEVICE..."
ssh "$DEVICE" "sh /home/root/xovi/uninstall-east-asian-keyboard"
