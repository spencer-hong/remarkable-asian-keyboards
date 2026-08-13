#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

version=$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")
archive=${1:-$DIST_DIR/remarkable-east-asian-keyboard-$version.zip}
release_name="remarkable-east-asian-keyboard-$version"
XOCHITL_PATH=${XOCHITL_PATH:-$BUILD_DIR/device/xochitl}
simulation_dir=$(mktemp -d "$BUILD_DIR/simulation.XXXXXX")
payload="$simulation_dir/payload.tar.gz"

if [ ! -f "$XOCHITL_PATH" ]; then
    echo "A supported xochitl is required via XOCHITL_PATH or build/device/xochitl." >&2
    exit 1
fi
verify_sha256 "$XOCHITL_PATH" "$EXPECTED_XOCHITL_SHA256"

unzip -p "$archive" \
    "$release_name/remarkable-east-asian-keyboard-payload.tar.gz" > "$payload"

docker run --rm \
    -e PATH=/mock-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    -v "$payload:/payload.tar.gz:ro" \
    -v "$XOCHITL_PATH:/supported-xochitl:ro" \
    -v "$REPO_ROOT/tests/mock-bin:/mock-bin:ro" \
    debian:bookworm-slim \
    sh -eu -c '
        mkdir -p /home/root /tmp/installer
        cp /supported-xochitl /usr/bin/xochitl
        tar -xzf /payload.tar.gz -C /tmp/installer

        sh /tmp/installer/device-install.sh
        test -s /home/root/xovi/qml/io/codex/EastAsianIme/libeastasianime.so
        test -s /home/root/xovi/exthome/qt-resource-rebuilder/east-asian-keyboard.rcc
        test -s /home/root/.local/share/fonts/NotoSansCJK-Regular.ttc

        sh /tmp/installer/device-install.sh
        test -s /home/root/xovi/exthome/qt-resource-rebuilder/east-asian-keyboard.qrr

        sh /home/root/xovi/uninstall-east-asian-keyboard
        test ! -e /home/root/xovi/exthome/qt-resource-rebuilder/east-asian-keyboard.qrr
        find /home/root/xovi/exthome/qt-resource-rebuilder \
            -maxdepth 1 -type d -name "east-asian-keyboard-uninstalled-*" | grep -q .
    '

echo "Clean install, repeated upgrade, and recoverable uninstall simulation passed."
