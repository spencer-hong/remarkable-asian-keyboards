#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

version=$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")
archive=${1:-$DIST_DIR/remarkable-east-asian-keyboard-$version.zip}
release_name="remarkable-east-asian-keyboard-$version"
verify_dir=$(mktemp -d "$BUILD_DIR/verify.XXXXXX")

if [ ! -f "$archive" ]; then
    echo "Release archive not found: $archive" >&2
    exit 1
fi

if unzip -Z1 "$archive" | rg '(^/|(^|/)\.\.(/|$))'; then
    echo "Unsafe path found in release ZIP." >&2
    exit 1
fi

unzip -q "$archive" -d "$verify_dir"
release_dir="$verify_dir/$release_name"
payload="$release_dir/remarkable-east-asian-keyboard-payload.tar.gz"

for required in \
    "$release_dir/README.md" \
    "$release_dir/install.sh" \
    "$release_dir/uninstall.sh" \
    "$payload"
do
    test -s "$required"
done

if tar -tzf "$payload" | rg '(^/|(^|/)\.\.(/|$))'; then
    echo "Unsafe path found in payload archive." >&2
    exit 1
fi

for entry in \
    ./device-install.sh \
    ./device-uninstall.sh \
    ./version-check.sh \
    ./supported-device.env \
    ./east-asian-keyboard.qrr \
    ./east-asian-keyboard.rcc \
    ./ui/KeyboardPanel.qml \
    ./east-asian/libeastasianime.so \
    ./east-asian/qmldir \
    ./east-asian/dict_pinyin.dat \
    ./east-asian/NotoSansCJK-Regular.ttc \
    ./east-asian/east-asian-ime.conf
do
    tar -tzf "$payload" | grep -Fqx "$entry"
done

sh -n "$release_dir/install.sh" "$release_dir/uninstall.sh"
tar -xOzf "$payload" ./device-install.sh | sh -n
tar -xOzf "$payload" ./device-uninstall.sh | sh -n
tar -xOzf "$payload" ./version-check.sh | sh -n

source_plugin_hash=$(sha256_file "$BUILD_DIR/artifacts/libeastasianime.so")
payload_plugin_hash=$(tar -xOzf "$payload" ./east-asian/libeastasianime.so | \
    { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; } | \
    awk '{print $1}')
test "$source_plugin_hash" = "$payload_plugin_hash"

tar -xOzf "$payload" ./east-asian/libeastasianime.so | file - | grep -q 'ARM aarch64'
if tar -xOzf "$payload" ./device-install.sh | \
    rg -n '(^|[;&|[:space:]])install[[:space:]]'; then
    echo "The payload uses the unsupported device-side install command." >&2
    exit 1
fi

release_secret_pattern='/Users/|Documents/Codex|work/paper-pure-korean|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY'
if rg -n \
    --glob '*.md' \
    --glob '*.sh' \
    --glob '*.env' \
    --glob '*.conf' \
    --glob '*.qml' \
    --glob '*.qrr' \
    "$release_secret_pattern" "$release_dir"; then
    echo "A release text file contains a personal path or private key." >&2
    exit 1
fi
if tar -xOzf "$payload" ./ui/KeyboardPanel.qml | rg -n "$release_secret_pattern"; then
    echo "The generated keyboard panel contains a personal path or private key." >&2
    exit 1
fi

echo "Release verification passed: $archive"
