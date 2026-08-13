#!/bin/sh
set -eu

XOVI_HOME="/home/root/xovi"
EXTENSION_HOME="$XOVI_HOME/exthome/qt-resource-rebuilder"
BACKUP_HOME="$EXTENSION_HOME/east-asian-keyboard-uninstalled-$(date +%Y%m%d%H%M%S)"

if [ -x "$XOVI_HOME/stock" ]; then
    "$XOVI_HOME/stock" || true
fi

mkdir -p "$BACKUP_HOME"
chmod 0755 "$BACKUP_HOME"
for path in \
    "$EXTENSION_HOME/east-asian-keyboard.qrr" \
    "$EXTENSION_HOME/east-asian-keyboard.rcc" \
    "$EXTENSION_HOME/east-asian-keyboard.qrr.disabled" \
    "$EXTENSION_HOME/east-asian-keyboard.rcc.disabled" \
    "$XOVI_HOME/scripts/pre-start/20-east-asian-keyboard-version-check.sh" \
    "$XOVI_HOME/services/xochitl.service/east-asian-ime.conf" \
    "$XOVI_HOME/uninstall-east-asian-keyboard" \
    "/home/root/.local/share/fonts/NotoSansCJK-Regular.ttc"
do
    if [ -e "$path" ]; then
        mv "$path" "$BACKUP_HOME/"
    fi
done
for directory in \
    "$EXTENSION_HOME/east-asian-keyboard" \
    "$EXTENSION_HOME/east-asian" \
    "$XOVI_HOME/qml/io/codex/EastAsianIme" \
    "/home/root/.config/remarkable-east-asian-ime"
do
    if [ -d "$directory" ]; then
        mv "$directory" "$BACKUP_HOME/"
    fi
done

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f /home/root/.local/share/fonts || true
fi

if [ -x "$XOVI_HOME/start" ]; then
    "$XOVI_HOME/start"
fi

echo "Multilingual keyboard removed. Its files are recoverable from:"
echo "$BACKUP_HOME"
