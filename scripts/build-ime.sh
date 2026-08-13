#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

SDK_VOLUME=${SDK_VOLUME:-remarkable-tatsu-sdk}
SDK_PLATFORM=${SDK_PLATFORM:-linux/amd64}

mkdir -p "$BUILD_DIR/ime" "$BUILD_DIR/artifacts"

docker run --rm --platform "$SDK_PLATFORM" \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$SDK_VOLUME:/sdk:ro" \
    -v "$REPO_ROOT:/work" \
    -w /work \
    debian:bookworm-slim \
    bash -eu -c '
        sdk_environment=$(find /sdk -maxdepth 1 -name "environment-setup-*" -type f | head -n 1)
        if [ -z "$sdk_environment" ]; then
            echo "No SDK environment file found in /sdk" >&2
            exit 1
        fi
        source "$sdk_environment"
        "$OECORE_NATIVE_SYSROOT/usr/bin/qt-cmake" \
            -S /work/src/ime \
            -B /work/build/ime \
            -DCMAKE_BUILD_TYPE=Release
        "$OECORE_NATIVE_SYSROOT/usr/bin/cmake" --build /work/build/ime --parallel

        loader="$OECORE_TARGET_SYSROOT/usr/lib/ld-linux-aarch64.so.1"
        libraries="/work/build/ime:$OECORE_TARGET_SYSROOT/usr/lib:$OECORE_TARGET_SYSROOT/lib"
        export RM_EASTASIAN_PINYIN_DICTIONARY=/work/third_party/pinyin/data/dict_pinyin.dat
        export RM_EASTASIAN_PINYIN_USER_DICTIONARY=/tmp/pinyin-user.dat
        export QT_TARGET_QML_PATH="$OECORE_TARGET_SYSROOT/usr/lib/qml"
        export EASTASIAN_IME_QML_IMPORT_PATH=/work/build/ime/qml-root
        "$loader" --library-path "$libraries" /work/build/ime/eastasianime_test
        "$loader" --library-path "$libraries" /work/build/ime/eastasianime_qml_test

        cp /work/build/ime/libeastasianime.so /work/build/artifacts/libeastasianime.so
        "$OECORE_NATIVE_SYSROOT/usr/bin/aarch64-remarkable-linux/aarch64-remarkable-linux-strip" \
            /work/build/artifacts/libeastasianime.so
    '

echo "Built and tested $BUILD_DIR/artifacts/libeastasianime.so"
