#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

DEVICE=${DEVICE:-root@10.11.99.1}
DEVICE_DIR="$BUILD_DIR/device"
GENERATED_DIR="$BUILD_DIR/generated"
XOCHITL_PATH=${XOCHITL_PATH:-$DEVICE_DIR/xochitl}
QRC2ZIP="$BUILD_DIR/tools/qrc2zip"

mkdir -p "$DEVICE_DIR" "$GENERATED_DIR" "$BUILD_DIR/tools"

if [ ! -f "$XOCHITL_PATH" ]; then
    echo "Copying /usr/bin/xochitl from $DEVICE for local patch generation..."
    echo "Use the SSH password shown on the tablet. It is not saved."
    scp "${DEVICE}:/usr/bin/xochitl" "$XOCHITL_PATH"
fi
verify_sha256 "$XOCHITL_PATH" "$EXPECTED_XOCHITL_SHA256"

if [ ! -x "$QRC2ZIP" ] || ! "$QRC2ZIP" --help >/dev/null 2>&1; then
    if command -v go >/dev/null 2>&1; then
        GOBIN="$BUILD_DIR/tools" go install "${QRC2ZIP_MODULE}@${QRC2ZIP_VERSION}"
    elif command -v docker >/dev/null 2>&1; then
        case $(uname -s) in
            Darwin) host_goos=darwin ;;
            Linux) host_goos=linux ;;
            *) echo "Unsupported host operating system for qrc2zip: $(uname -s)" >&2; exit 1 ;;
        esac
        case $(uname -m) in
            arm64 | aarch64) host_goarch=arm64 ;;
            x86_64 | amd64) host_goarch=amd64 ;;
            *) echo "Unsupported host architecture for qrc2zip: $(uname -m)" >&2; exit 1 ;;
        esac
        mkdir -p "$BUILD_DIR/go-cache" "$BUILD_DIR/go-mod-cache" "$BUILD_DIR/go-path"
        docker run --rm \
            --user "$(id -u):$(id -g)" \
            -e CGO_ENABLED=0 \
            -e GOCACHE=/work/build/go-cache \
            -e GOMODCACHE=/work/build/go-mod-cache \
            -e GOPATH=/work/build/go-path \
            -e GOARCH="$host_goarch" \
            -e GOOS="$host_goos" \
            -e QRC2ZIP_PACKAGE="${QRC2ZIP_MODULE}@${QRC2ZIP_VERSION}" \
            -v "$REPO_ROOT:/work" \
            -w /work \
            golang:1.24-bookworm \
            sh -eu -c 'go install "$QRC2ZIP_PACKAGE"; cp "$GOPATH/bin/${GOOS}_${GOARCH}/qrc2zip" /work/build/tools/qrc2zip'
    else
        echo "Go or Docker is required to build the pinned qrc2zip tool." >&2
        exit 1
    fi
fi

resource_zip="$DEVICE_DIR/keyboard-resources.zip"
(CDPATH='' cd -- "$DEVICE_DIR" && \
    "$QRC2ZIP" -o keyboard-resources.zip "$XOCHITL_PATH" \
        "$KEYBOARD_QRC_FORMAT" \
        "$KEYBOARD_QRC_TREE_OFFSET" \
        "$KEYBOARD_QRC_DATA_OFFSET" \
        "$KEYBOARD_QRC_NAMES_OFFSET")

stock_panel="$DEVICE_DIR/KeyboardPanel.stock.qml"
unzip -p "$resource_zip" "$KEYBOARD_PANEL_RESOURCE" > "$stock_panel"
verify_sha256 "$stock_panel" "$EXPECTED_KEYBOARD_PANEL_SHA256"

patch --batch --forward \
    --output "$GENERATED_DIR/KeyboardPanel.qml" \
    "$stock_panel" \
    "$REPO_ROOT/patches/KeyboardPanel.qml.patch"

echo "Generated $GENERATED_DIR/KeyboardPanel.qml"
echo "The copied tablet executable remains only under ignored build/device/."
