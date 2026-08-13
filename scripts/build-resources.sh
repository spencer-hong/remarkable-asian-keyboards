#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

SDK_VOLUME=${SDK_VOLUME:-remarkable-tatsu-sdk}
SDK_PLATFORM=${SDK_PLATFORM:-linux/amd64}

mkdir -p "$BUILD_DIR/artifacts"

docker run --rm --platform "$SDK_PLATFORM" \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$SDK_VOLUME:/sdk:ro" \
    -v "$REPO_ROOT:/work" \
    -w /work \
    debian:bookworm-slim \
    bash -eu -c '
        sdk_environment=$(find /sdk -maxdepth 1 -name "environment-setup-*" -type f | head -n 1)
        source "$sdk_environment"
        "$OECORE_NATIVE_SYSROOT/usr/libexec/rcc" --binary \
            --output /work/build/artifacts/east-asian-keyboard.rcc \
            /work/src/keyboard/keyboard.qrc
    '

echo "Built $BUILD_DIR/artifacts/east-asian-keyboard.rcc"
