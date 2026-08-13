.PHONY: help deps panel ime resources package release check secret-scan verify-release simulate

DEVICE ?= root@10.11.99.1

help:
	@echo "make deps       Download checksum-pinned XOVI and Noto CJK files"
	@echo "make panel      Copy stock xochitl from DEVICE and apply the UI patch"
	@echo "make ime        Cross-compile and test the Qt input engine"
	@echo "make resources  Build the keyboard RCC bundle"
	@echo "make package    Create the release ZIP under dist/"
	@echo "make release    Run the complete release build"
	@echo "make check      Run source, Hangul, and secret checks"
	@echo "make simulate   Test install, repeated upgrade, and uninstall in Docker"

deps:
	./scripts/fetch-dependencies.sh

panel:
	DEVICE="$(DEVICE)" ./scripts/prepare-panel.sh

ime:
	./scripts/build-ime.sh

resources:
	./scripts/build-resources.sh

package:
	./scripts/package-release.sh

release: deps panel ime resources package
	./scripts/check.sh

check:
	./scripts/check.sh

secret-scan:
	./scripts/secret-scan.sh

verify-release:
	./scripts/verify-release.sh

simulate:
	./scripts/simulate-installer.sh
