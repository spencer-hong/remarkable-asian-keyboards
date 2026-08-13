# Third-party software

Project-owned source is Apache-2.0. Releases are an aggregate containing
components under the licenses below.

## OpenWnn

- Purpose: Japanese romaji/kana conversion and dictionary candidates
- Source: Qt Virtual Keyboard `v6.8.2`, commit
  `2e8581c7a54d9b6c16a002d7af27e1beeacea9fb`
- Upstream: <https://github.com/qt/qtvirtualkeyboard/tree/v6.8.2/src/plugins/openwnn/3rdparty/openwnn>
- License: Apache-2.0
- Copyright: Copyright (C) 2008–2012 OMRON SOFTWARE Co., Ltd.
- Notice: `third_party/openwnn/NOTICE`

Only the upstream `3rdparty/openwnn` implementation is used; this project does
not copy Qt's GPL/commercial OpenWnn adapter.

## PinyinIME

- Purpose: offline Simplified Chinese Pinyin conversion
- Source: Qt Virtual Keyboard `v6.8.2`, commit
  `2e8581c7a54d9b6c16a002d7af27e1beeacea9fb`
- Upstream: <https://github.com/qt/qtvirtualkeyboard/tree/v6.8.2/src/plugins/pinyin/3rdparty/pinyin>
- License: Apache-2.0
- Copyright: Copyright (c) 2009, The Android Open Source Project
- Notice: `third_party/pinyin/NOTICE`

Only the upstream `3rdparty/pinyin` implementation and dictionary are used; this
project does not copy Qt's GPL/commercial Pinyin adapter.

## Noto Sans CJK

- Purpose: Korean, Japanese, and Simplified Chinese glyph coverage
- Source commit: `165c01b46ea533872e002e0785ff17e44f6d97d8`
- Upstream: <https://github.com/notofonts/noto-cjk>
- License: SIL Open Font License 1.1
- License copy: `third_party/licenses/Noto-CJK-OFL.txt`

The font is downloaded during release builds and is not committed to this
repository.

## XOVI and rm-xovi-extensions

- Purpose: tethered in-memory extension loading and Qt resource replacement
- XOVI upstream: <https://github.com/asivery/xovi>
- XOVI license: LGPL-3.0; copy in
  `third_party/licenses/XOVI-LGPL-3.0.txt`
- rm-xovi-extensions version: `v19-23052026`, commit
  `7874154dba6793cc68a15fae0fb9dd272c4ed20a`
- rm-xovi-extensions upstream: <https://github.com/asivery/rm-xovi-extensions/tree/v19-23052026>
- rm-xovi-extensions license: GPL-3.0; copy in
  `third_party/licenses/rm-xovi-extensions-GPL-3.0.txt`

The official aarch64 release archive is downloaded during release builds. The
corresponding upstream source and exact release tag are linked above.

## qrc

- Purpose: maintainer-only extraction of the stock keyboard QML resource
- Upstream: <https://github.com/pgaskin/qrc>
- Pinned commit: `aa2fe41e9e6ce60f98b8eb7e137abc754cb65431`
- License: MIT

The tool is fetched into ignored build storage and is not shipped to tablets.

## Qt

The plugin dynamically links to the Qt 6 libraries already installed on the
tablet. Qt is not included in this repository or release. See
<https://www.qt.io/licensing/open-source-lgpl-obligations> for Qt licensing
information.
