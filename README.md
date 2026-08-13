# East Asian keyboard for reMarkable Paper Pure

A community keyboard mod adding Korean, Japanese, and Simplified Chinese input
to the stock reMarkable Paper Pure keyboard.

> [!CAUTION]
> This is an unofficial mod. Developer Mode weakens the tablet's security, and
> reMarkable does not support modifications made with it. Back up or sync your
> documents before proceeding. The installer refuses to patch an unknown
> `xochitl` version and falls back to the stock interface if startup fails.

## Features

| Language | Input |
| --- | --- |
| Korean (`한국어`) | Dubeolsik keyboard with complete Hangul syllable composition |
| Japanese (`日本語`) | QWERTY romaji → live hiragana, OpenWnn kanji candidates, and katakana candidate |
| Simplified Chinese (`中文`) | QWERTY Pinyin with offline PinyinIME Hanzi candidates |

Japanese examples:

- `hiragana` displays `ひらがな`; press **Enter** to keep the hiragana.
- `nihongo` displays `にほんご`; press **Space** or tap `日本語` to convert it.
- Katakana is included in the horizontally scrolling candidate bar.

Chinese examples include `nihao` → `你好` and `zhongguo` → `中国`.

## Compatibility

The current release is for **reMarkable Paper Pure** (`tatsu`) with this exact
stock executable:

```text
xochitl SHA-256: 12ccd2e95a1e8115a959322fc50de3da3243a208652ad40aba62a0cc34b7344d
```

The installer checks that hash before changing anything. A software update will
usually change it; the installed pre-start check then disables the UI patch.
Do not bypass that check. Open an issue with the new hash so a compatible patch
can be reviewed and released.

## Install a release

### Requirements

- A Paper Pure with
  [Developer Mode](https://developer.remarkable.com/documentation/developer-mode)
  already enabled.
- The tablet connected to your computer over USB.
- `ssh`, `scp`, and `tar` on the computer. macOS and Linux are supported; WSL
  should work but is not currently tested.
- The current SSH password displayed by the tablet under **Settings → General →
  Help → About → Copyrights and Licenses**.

Enabling Developer Mode can factory-reset the tablet. Read reMarkable's warning
and sync your documents before enabling it.

### Steps

1. Download `remarkable-east-asian-keyboard-<version>.zip` from the repository's
   **Releases** page and extract it.
2. Open Terminal in the extracted directory.
3. Run:

   ```sh
   ./install.sh
   ```

4. Enter the current tablet SSH password when OpenSSH asks. It may ask twice:
   once for `scp` and once for `ssh`. The installer never saves the password.
5. The tablet interface restarts. Open a text field, tap the globe/language key,
   and choose `한국어`, `日本語`, or `中文`.

To use a different SSH destination:

```sh
./install.sh root@tablet-address
```

Running the same installer again performs an idempotent upgrade. It also moves
files from the earlier Korean-only package into a timestamped backup.

## After a full reboot

XOVI is intentionally tethered and is not enabled permanently at boot. Connect
the tablet over USB and run:

```sh
ssh root@10.11.99.1 /home/root/xovi/start
```

This restarts the interface with the keyboard mod. A normal reboot always
returns to the stock interface until that command is run.

## Uninstall

From the extracted release directory, run:

```sh
./uninstall.sh
```

The uninstaller switches to stock first and moves mod files into a timestamped,
recoverable directory under:

```text
/home/root/xovi/exthome/qt-resource-rebuilder/
```

It does not delete notebooks or documents.
It also moves the Pinyin user dictionary, which may contain locally learned
selections, into that backup. XOVI itself is left installed because other mods
may use it.

## Recovery

If the interface does not load, reboot the tablet. Because XOVI is tethered,
the next boot uses stock `xochitl`. You can also switch back without rebooting:

```sh
ssh root@10.11.99.1 /home/root/xovi/stock
```

Please include `journalctl -u xochitl -n 50 --no-pager` and the result of
`sha256sum /usr/bin/xochitl` in a bug report. Review the output for personal
information before posting it.

## Privacy and secrets

- Release installation communicates only with the SSH destination you provide.
- Password entry is handled interactively by your system's OpenSSH client.
- No password, private key, tablet executable, serial number, or notebook data
  is included in this repository or written by the installer.
- Maintainer builds copy `/usr/bin/xochitl` to the ignored `build/device/`
  directory only to extract the stock QML resource. Never commit that directory.
- `make check` includes a common token and personal-path scan. It is a guardrail,
  not a substitute for reviewing `git diff` before publishing.

## Build from source

Most users should install a release. Maintainers need Docker, Go (or Docker for
Go), `patch`, `unzip`, `zip`, and the matching official Tatsu SDK. See
[Building](docs/BUILDING.md) for the complete reproducible process.

```sh
make check
make release DEVICE=root@10.11.99.1
```

Generated SDK files, the copied tablet executable, downloaded dependencies, and
release archives live in ignored directories. Only source, patches, pinned
checksums, and redistribution notices belong in Git.

## How it works

The mod uses tethered [XOVI](https://github.com/asivery/xovi) and
[qt-resource-rebuilder](https://github.com/asivery/rm-xovi-extensions/tree/master/qt-resource-rebuilder)
to replace one QML resource in memory and register keyboard layouts. A small Qt
QML plugin provides offline Japanese [OpenWnn](https://doc.qt.io/qt-6/qtvirtualkeyboard-attribution-openwnn.html)
and Chinese [PinyinIME](https://doc.qt.io/qt-6.8/qtvirtualkeyboard-attribution-pinyin.html)
conversion. Noto Sans CJK supplies the required glyphs. The stock executable on
disk is not modified.

See [Architecture](docs/ARCHITECTURE.md) and [third-party notices](THIRD_PARTY.md)
for details.

## License

Project-owned source is licensed under Apache-2.0. Bundled or downloaded
components retain their own licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).
reMarkable and its product names are trademarks of their respective owner. This
project is not affiliated with or endorsed by reMarkable AS.
