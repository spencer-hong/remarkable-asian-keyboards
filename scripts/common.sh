#!/bin/sh

set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
# shellcheck disable=SC2034
CACHE_DIR="$REPO_ROOT/.cache"
# shellcheck disable=SC2034
BUILD_DIR="$REPO_ROOT/build"
# shellcheck disable=SC2034
DIST_DIR="$REPO_ROOT/dist"

# shellcheck source=../config/dependencies.env
. "$REPO_ROOT/config/dependencies.env"
# shellcheck source=../config/supported-device.env
. "$REPO_ROOT/config/supported-device.env"

sha256_file()
{
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

verify_sha256()
{
    file=$1
    expected=$2
    actual=$(sha256_file "$file")
    if [ "$actual" != "$expected" ]; then
        echo "Checksum mismatch for $file" >&2
        echo "Expected: $expected" >&2
        echo "Found:    $actual" >&2
        exit 1
    fi
}

download()
{
    url=$1
    destination=$2
    expected=$3

    if [ -f "$destination" ]; then
        verify_sha256 "$destination" "$expected"
        return
    fi

    mkdir -p "$(dirname -- "$destination")"
    partial="$destination.partial.$$"
    curl --fail --location --proto '=https' --tlsv1.2 \
        --output "$partial" "$url"
    verify_sha256 "$partial" "$expected"
    mv "$partial" "$destination"
}
