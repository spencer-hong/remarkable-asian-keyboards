#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

mkdir -p "$CACHE_DIR/downloads"
download "$XOVI_URL" "$CACHE_DIR/downloads/xovi-aarch64.tar.gz" "$XOVI_SHA256"
download "$NOTO_CJK_URL" "$CACHE_DIR/downloads/NotoSansCJK-Regular.ttc" "$NOTO_CJK_SHA256"

echo "Pinned release dependencies are ready in $CACHE_DIR/downloads"
