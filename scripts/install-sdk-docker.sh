#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/reMarkable-tatsu-sdk-installer.sh" >&2
    exit 2
fi

SDK_INSTALLER=$(CDPATH='' cd -- "$(dirname -- "$1")" && pwd)/$(basename -- "$1")
SDK_VOLUME=${SDK_VOLUME:-remarkable-tatsu-sdk}
SDK_PLATFORM=${SDK_PLATFORM:-linux/amd64}

if [ ! -f "$SDK_INSTALLER" ]; then
    echo "SDK installer not found: $SDK_INSTALLER" >&2
    exit 1
fi

docker volume create "$SDK_VOLUME" >/dev/null
docker run --rm --platform "$SDK_PLATFORM" \
    -v "$SDK_INSTALLER:/tmp/remarkable-sdk.sh:ro" \
    -v "$SDK_VOLUME:/sdk" \
    debian:bookworm-slim \
    sh -lc 'apt-get update && apt-get install -y --no-install-recommends gcc locales python3 xz-utils && sh /tmp/remarkable-sdk.sh -y -d /sdk'

echo "Installed the SDK in Docker volume $SDK_VOLUME"
