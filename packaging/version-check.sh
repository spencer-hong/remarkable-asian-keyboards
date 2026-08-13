#!/bin/sh

EXTENSION_HOME="/home/root/xovi/exthome/qt-resource-rebuilder"
CONFIG="$EXTENSION_HOME/east-asian-keyboard/supported-device.env"

if [ ! -f "$CONFIG" ]; then
    echo "Multilingual keyboard: compatibility metadata is missing; disabling UI patch." >&2
else
    # shellcheck source=/dev/null
    . "$CONFIG"
    actual_xochitl_sha256=$(sha256sum /usr/bin/xochitl | awk '{print $1}')
    if [ "$actual_xochitl_sha256" = "$EXPECTED_XOCHITL_SHA256" ]; then
        exit 0
    fi
    echo "Multilingual keyboard: xochitl changed; disabling the version-specific UI patch." >&2
    echo "Multilingual keyboard: expected $EXPECTED_XOCHITL_SHA256, found $actual_xochitl_sha256" >&2
fi

for path in \
    "$EXTENSION_HOME/east-asian-keyboard.qrr" \
    "$EXTENSION_HOME/east-asian-keyboard.rcc"
do
    if [ -f "$path" ]; then
        mv "$path" "$path.disabled"
    fi
done
