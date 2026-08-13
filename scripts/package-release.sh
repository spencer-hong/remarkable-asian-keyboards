#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

version=$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")
release_name="remarkable-east-asian-keyboard-$version"
stage=$(mktemp -d "$BUILD_DIR/release.XXXXXX")
release_dir="$stage/$release_name"
payload_dir="$stage/payload"

required_files="
$BUILD_DIR/generated/KeyboardPanel.qml
$BUILD_DIR/artifacts/libeastasianime.so
$BUILD_DIR/artifacts/east-asian-keyboard.rcc
$CACHE_DIR/downloads/xovi-aarch64.tar.gz
$CACHE_DIR/downloads/NotoSansCJK-Regular.ttc
"
for required in $required_files; do
    if [ ! -f "$required" ]; then
        echo "Missing build input: $required" >&2
        exit 1
    fi
done

mkdir -p \
    "$DIST_DIR" \
    "$release_dir/licenses" \
    "$payload_dir/framework" \
    "$payload_dir/ui" \
    "$payload_dir/east-asian" \
    "$payload_dir/licenses"

tar -xzf "$CACHE_DIR/downloads/xovi-aarch64.tar.gz" -C "$payload_dir/framework"
cp "$BUILD_DIR/generated/KeyboardPanel.qml" "$payload_dir/ui/KeyboardPanel.qml"
cp "$BUILD_DIR/artifacts/libeastasianime.so" "$payload_dir/east-asian/"
cp "$REPO_ROOT/src/ime/qmldir" "$payload_dir/east-asian/"
cp "$REPO_ROOT/third_party/pinyin/data/dict_pinyin.dat" "$payload_dir/east-asian/"
cp "$CACHE_DIR/downloads/NotoSansCJK-Regular.ttc" "$payload_dir/east-asian/"
cp "$REPO_ROOT/packaging/east-asian-ime.conf" "$payload_dir/east-asian/"
cp "$REPO_ROOT/src/keyboard/keyboard.qrr" "$payload_dir/east-asian-keyboard.qrr"
cp "$BUILD_DIR/artifacts/east-asian-keyboard.rcc" "$payload_dir/"
cp \
    "$REPO_ROOT/packaging/device-install.sh" \
    "$REPO_ROOT/packaging/device-uninstall.sh" \
    "$REPO_ROOT/packaging/version-check.sh" \
    "$REPO_ROOT/config/supported-device.env" \
    "$payload_dir/"

cp "$REPO_ROOT/LICENSE" "$payload_dir/licenses/project-Apache-2.0.txt"
cp "$REPO_ROOT/third_party/openwnn/NOTICE" "$payload_dir/licenses/OpenWnn-NOTICE"
cp "$REPO_ROOT/third_party/pinyin/NOTICE" "$payload_dir/licenses/PinyinIME-NOTICE"
cp "$REPO_ROOT/third_party/licenses/"* "$payload_dir/licenses/"

chmod 0755 \
    "$payload_dir/device-install.sh" \
    "$payload_dir/device-uninstall.sh" \
    "$payload_dir/version-check.sh"

docker run --rm \
    -v "$payload_dir:/payload:ro" \
    -v "$release_dir:/release" \
    debian:bookworm-slim \
    tar --no-xattrs -czf /release/remarkable-east-asian-keyboard-payload.tar.gz -C /payload .

cp "$REPO_ROOT/README.md" "$release_dir/README.md"
cp "$REPO_ROOT/packaging/install.sh" "$release_dir/install.sh"
cp "$REPO_ROOT/packaging/uninstall.sh" "$release_dir/uninstall.sh"
cp "$REPO_ROOT/LICENSE" "$release_dir/licenses/project-Apache-2.0.txt"
cp "$REPO_ROOT/third_party/openwnn/NOTICE" "$release_dir/licenses/OpenWnn-NOTICE"
cp "$REPO_ROOT/third_party/pinyin/NOTICE" "$release_dir/licenses/PinyinIME-NOTICE"
cp "$REPO_ROOT/third_party/licenses/"* "$release_dir/licenses/"
chmod 0755 "$release_dir/install.sh" "$release_dir/uninstall.sh"

archive="$stage/$release_name.zip"
(CDPATH='' cd -- "$stage" && COPYFILE_DISABLE=1 zip -qr "$archive" "$release_name")
mv "$archive" "$DIST_DIR/$release_name.zip"

echo "Created $DIST_DIR/$release_name.zip"
echo "Upload this ZIP as a GitHub Release asset; do not commit it to source control."
"$SCRIPT_DIR/verify-release.sh" "$DIST_DIR/$release_name.zip"
