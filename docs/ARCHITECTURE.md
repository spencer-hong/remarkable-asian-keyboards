# Architecture

## Runtime flow

1. The user starts tethered XOVI after boot.
2. `qt-resource-rebuilder` registers `east-asian-keyboard.rcc`, which adds the
   Korean, Japanese, and Chinese keyboard layouts plus `Hangul.js`.
3. Its QRR rule replaces the in-memory `KeyboardPanel.qml` resource with the
   version-matched generated panel.
4. XOVI's `xochitl.service` drop-in adds `/home/root/xovi/qml` to the QML import
   path.
5. The panel imports `io.codex.EastAsianIme`, a small aarch64 Qt plugin.

The stock `/usr/bin/xochitl` file is read for compatibility checking but is
never changed.

## Input engines

- Korean composition is implemented in QML-compatible JavaScript. It tracks
  initial consonants, vowels, compound vowels, finals, and split compound
  finals, then emits NFC Hangul syllables.
- Japanese input stores raw romaji in OpenWnn's composing layers. The UI shows
  the hiragana preedit immediately. Enter commits that preedit, while Space or
  a candidate tap selects a kanji/kana candidate. Katakana is added as a
  deterministic fallback candidate.
- Simplified Chinese input passes the current Latin preedit to PinyinIME. The
  engine returns up to 30 offline candidates and supports multi-step candidate
  selection.

## Safety boundary

The UI patch depends on private stock QML structure, so it is pinned to an exact
SHA-256. Installation stops before copying mod files if the hash differs. A
pre-start check disables the QRR and RCC after a system update. XOVI remains
tethered: a reboot starts stock `xochitl` unless the user explicitly invokes
`/home/root/xovi/start`.

Uninstall and legacy migration use timestamped moves rather than deletion so
the mod files remain recoverable.

## Repository boundary

The repository contains the project patch and Apache-licensed OpenWnn/PinyinIME
source needed for reproducible builds. It excludes:

- stock `xochitl` binaries and extracted reMarkable QML;
- the official reMarkable SDK;
- generated build and release artifacts;
- device credentials, identifiers, and user documents.

The release builder downloads checksum-pinned XOVI and Noto assets and combines
them with locally generated output under ignored directories.
