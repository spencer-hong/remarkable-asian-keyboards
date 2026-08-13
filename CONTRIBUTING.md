# Contributing

Please open an issue before undertaking a new device or `xochitl` version port.
Compatibility changes require the exact stock hash, reviewed QRC offsets, a
rebased minimal QML patch, target-architecture tests, and on-device fallback
testing.

Before submitting a change:

```sh
make check
```

Do not commit SDKs, tablet executables, extracted stock QML, generated archives,
logs containing device information, or credentials. Keep third-party source
updates separate from project-owned changes and update `THIRD_PARTY.md`, pinned
commits, checksums, and notices together.

For behavior changes, add focused tests. For visible keyboard changes, include
screenshots in the pull request but inspect them for notebook content and device
identifiers first.
