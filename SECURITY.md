# Security policy

This project installs root-level code on a tablet in Developer Mode. Report
vulnerabilities privately through the repository host's security-advisory
feature rather than a public issue.

Never attach SSH passwords, private keys, tablet serial numbers, cloud tokens,
notebooks, or an unredacted system log. The project will never ask you to commit
or upload `/usr/bin/xochitl`; maintainers only need its SHA-256 and, when doing a
port locally, a copy obtained from their own device.

The supported-version hash check, tethered startup, and stock fallback are
security boundaries. Changes that weaken or bypass them will not be accepted.
