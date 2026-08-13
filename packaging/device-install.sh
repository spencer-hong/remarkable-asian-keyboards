#!/bin/sh
set -eu

XOVI_HOME="/home/root/xovi"
EXTENSION_HOME="$XOVI_HOME/exthome/qt-resource-rebuilder"
UI_HOME="$EXTENSION_HOME/east-asian-keyboard"
IME_HOME="$EXTENSION_HOME/east-asian"
QML_MODULE_HOME="$XOVI_HOME/qml/io/codex/EastAsianIme"
FONT_HOME="/home/root/.local/share/fonts"
SERVICE_HOME="$XOVI_HOME/services/xochitl.service"
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# shellcheck source=/dev/null
. "$SCRIPT_DIR/supported-device.env"

actual_xochitl_sha256=$(sha256sum /usr/bin/xochitl | awk '{print $1}')
if [ "$actual_xochitl_sha256" != "$EXPECTED_XOCHITL_SHA256" ]; then
    echo "Refusing to install: this release was built for a different xochitl binary." >&2
    echo "Expected: $EXPECTED_XOCHITL_SHA256" >&2
    echo "Found:    $actual_xochitl_sha256" >&2
    exit 2
fi

if [ -x "$XOVI_HOME/stock" ]; then
    "$XOVI_HOME/stock" || true
fi

if [ ! -x "$XOVI_HOME/start" ]; then
    echo "Installing the tethered XOVI framework..."
    cp -a "$SCRIPT_DIR/framework/xovi" /home/root/
elif [ ! -f "$XOVI_HOME/extensions.d/qt-resource-rebuilder.so" ]; then
    echo "Adding qt-resource-rebuilder to the existing XOVI installation..."
    cp "$SCRIPT_DIR/framework/xovi/extensions.d/qt-resource-rebuilder.so" \
        "$XOVI_HOME/extensions.d/qt-resource-rebuilder.so"
    chmod 0755 "$XOVI_HOME/extensions.d/qt-resource-rebuilder.so"
fi

mkdir -p \
    "$UI_HOME" \
    "$IME_HOME" \
    "$QML_MODULE_HOME" \
    "$FONT_HOME" \
    "$SERVICE_HOME" \
    "$XOVI_HOME/scripts/pre-start"

# Preserve files from the earlier Korean-only package if this is an upgrade.
legacy_backup="$EXTENSION_HOME/east-asian-keyboard-legacy-$(date +%Y%m%d%H%M%S)"
legacy_backup_created=false
for legacy_path in \
    "$EXTENSION_HOME/korean-keyboard.qrr" \
    "$EXTENSION_HOME/korean-keyboard.rcc" \
    "$EXTENSION_HOME/korean-keyboard.qrr.disabled" \
    "$EXTENSION_HOME/korean-keyboard.rcc.disabled" \
    "$EXTENSION_HOME/korean" \
    "$XOVI_HOME/scripts/pre-start/20-korean-keyboard-version-check.sh" \
    "$XOVI_HOME/uninstall-korean-keyboard"
do
    if [ -e "$legacy_path" ]; then
        if [ "$legacy_backup_created" = false ]; then
            mkdir -p "$legacy_backup"
            chmod 0755 "$legacy_backup"
            legacy_backup_created=true
        fi
        mv "$legacy_path" "$legacy_backup/"
    fi
done

cp "$SCRIPT_DIR/east-asian-keyboard.qrr" "$EXTENSION_HOME/east-asian-keyboard.qrr"
cp "$SCRIPT_DIR/east-asian-keyboard.rcc" "$EXTENSION_HOME/east-asian-keyboard.rcc"
cp "$SCRIPT_DIR/ui/KeyboardPanel.qml" "$UI_HOME/KeyboardPanel.qml"
cp "$SCRIPT_DIR/supported-device.env" "$UI_HOME/supported-device.env"
cp "$SCRIPT_DIR/version-check.sh" \
    "$XOVI_HOME/scripts/pre-start/20-east-asian-keyboard-version-check.sh"
cp "$SCRIPT_DIR/device-uninstall.sh" "$XOVI_HOME/uninstall-east-asian-keyboard"
cp "$SCRIPT_DIR/east-asian/libeastasianime.so" "$QML_MODULE_HOME/"
cp "$SCRIPT_DIR/east-asian/qmldir" "$QML_MODULE_HOME/"
cp "$SCRIPT_DIR/east-asian/dict_pinyin.dat" "$IME_HOME/"
cp "$SCRIPT_DIR/east-asian/NotoSansCJK-Regular.ttc" "$FONT_HOME/"
cp "$SCRIPT_DIR/east-asian/east-asian-ime.conf" "$SERVICE_HOME/"

chmod 0644 \
    "$EXTENSION_HOME/east-asian-keyboard.qrr" \
    "$EXTENSION_HOME/east-asian-keyboard.rcc" \
    "$UI_HOME/KeyboardPanel.qml" \
    "$UI_HOME/supported-device.env" \
    "$QML_MODULE_HOME/libeastasianime.so" \
    "$QML_MODULE_HOME/qmldir" \
    "$IME_HOME/dict_pinyin.dat" \
    "$FONT_HOME/NotoSansCJK-Regular.ttc" \
    "$SERVICE_HOME/east-asian-ime.conf"
chmod 0755 \
    "$XOVI_HOME/scripts/pre-start/20-east-asian-keyboard-version-check.sh" \
    "$XOVI_HOME/uninstall-east-asian-keyboard"

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_HOME" || true
fi

for disabled_path in \
    "$EXTENSION_HOME/east-asian-keyboard.qrr.disabled" \
    "$EXTENSION_HOME/east-asian-keyboard.rcc.disabled"
do
    if [ -f "$disabled_path" ]; then
        mv "$disabled_path" "${disabled_path%.disabled}"
    fi
done

echo "Starting XOVI and restarting xochitl..."
"$XOVI_HOME/start"
sleep 8

if systemctl is-active --quiet xochitl; then
    echo
    echo "Multilingual keyboard installed. Open a text field, tap the globe key,"
    echo "and select 한국어, 日本語, or 中文."
    echo "After a full reboot, run: /home/root/xovi/start"
    exit 0
fi

echo "xochitl did not remain active; reverting to stock for safety." >&2
journalctl -u xochitl -n 30 --no-pager >&2 || true
"$XOVI_HOME/stock" || true
exit 1
