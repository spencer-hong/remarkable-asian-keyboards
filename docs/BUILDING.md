# Building a release

The build is intentionally split between public source, checksum-pinned public
dependencies, the official reMarkable SDK, and the maintainer's own stock
`xochitl`. The repository does not redistribute the SDK or the tablet
executable.

## Prerequisites

- Docker
- Go 1.22+ or Docker
- Node.js 18+, ripgrep, `curl`, `patch`, `unzip`, `zip`, `ssh`, and `scp`
- A USB-connected Paper Pure running the exact supported `xochitl`
- The matching Tatsu SDK from the official
  [reMarkable SDK page](https://developer.remarkable.com/documentation/sdk)

The official documentation currently publishes Linux-hosted SDKs. On macOS or
Windows, run the SDK through Docker emulation as described below.

## 1. Install the SDK in a Docker volume

Download the matching Tatsu SDK installer yourself. Do not add it to this
repository. The official SDK is normally an x86_64 Linux toolchain:

```sh
./scripts/install-sdk-docker.sh /path/to/meta-toolchain-remarkable-tatsu-sdk.sh
```

That creates a Docker volume named `remarkable-tatsu-sdk`. Override either
setting when necessary:

```sh
SDK_VOLUME=my-sdk SDK_PLATFORM=linux/amd64 \
  ./scripts/install-sdk-docker.sh /path/to/sdk-installer.sh
```

An ARM64-host SDK can be used with `SDK_PLATFORM=linux/arm64`.

## 2. Check the source tree

```sh
make check
```

This validates shell syntax and JSON, runs the Hangul composition cases, checks
that the UI patch contains no local paths, and scans project-owned text for
common secret formats.

## 3. Fetch pinned redistribution dependencies

```sh
make deps
```

This downloads the XOVI aarch64 release and Noto Sans CJK into `.cache/` and
verifies the SHA-256 values in `config/dependencies.env`.

## 4. Generate the patched panel from your tablet

```sh
make panel DEVICE=root@10.11.99.1
```

The command copies `/usr/bin/xochitl` to ignored `build/device/`, verifies its
hash, extracts only the relevant stock QML resource with pinned `qrc2zip`, and
applies `patches/KeyboardPanel.qml.patch`. The copied executable and extracted
stock source must not be committed.

For an already copied executable:

```sh
XOCHITL_PATH=/private/path/to/xochitl ./scripts/prepare-panel.sh
```

## 5. Cross-compile and package

```sh
make ime
make resources
make package
make simulate
```

When using a non-default SDK container:

```sh
SDK_VOLUME=my-sdk SDK_PLATFORM=linux/arm64 make ime resources
```

The IME build runs target-architecture conversion and QML import tests through
the target dynamic loader. The packaging step creates:

```text
dist/remarkable-east-asian-keyboard-<version>.zip
```

Upload that ignored ZIP as a GitHub Release asset. Do not commit it to the Git
history.

The complete sequence is:

```sh
make release DEVICE=root@10.11.99.1
```

## Supporting a new software version

Do not merely replace the expected hash. A new `xochitl` requires a fresh audit:

1. Locate and extract its `KeyboardPanel.qml` resource.
2. Review the stock QML changes against the currently supported version.
3. Rebase the minimal patch and update its anchors.
4. Update all fields in `config/supported-device.env`.
5. Run the target IME tests and an archive-level installer simulation.
6. Test stock fallback, install, upgrade, reboot, and uninstall on the matching
   device before publishing a release.

Keep each supported stock version explicit. Silent best-effort patching is too
risky for a root-level tablet mod.
