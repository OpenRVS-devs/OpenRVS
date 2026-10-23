SHELL := /bin/bash
.DEFAULT_GOAL := build

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SDK_DIR ?= $(REPO_ROOT)/sdk/SDK2
SDK_VERSION ?= 160
BUILD_DIR ?= $(REPO_ROOT)/build
WINE_PREFIX ?= $(REPO_ROOT)/.wine-rvs
PACKAGES ?= OpenRVS OpenRenderFix
STRIP ?= 1
DISTROBOX_NAME ?= openrvs

SCRIPT := $(REPO_ROOT)/tools/build-mod.sh
BUILD_SCRIPT := $(REPO_ROOT)/tools/distrobox-build.sh
COMMON_ARGS = --sdk "$(SDK_DIR)" --version "$(SDK_VERSION)" --out "$(BUILD_DIR)" --prefix "$(WINE_PREFIX)" --strip "$(STRIP)"
BUILD_ARGS = $(COMMON_ARGS) --packages "$(PACKAGES)"

# Pass through values that are not Make-specific.
export WINE WINE_PREFIX WINEARCH STRIP ALLOW_OVERWRITE WINEDEBUG DISTROBOX_NAME

.PHONY: all build check clean distclean openrvs openrenderfix help release

all: build

build:
	@"$(BUILD_SCRIPT)" $(BUILD_ARGS)

openrvs:
	@"$(BUILD_SCRIPT)" $(COMMON_ARGS) --packages OpenRVS

openrenderfix:
	@"$(BUILD_SCRIPT)" $(COMMON_ARGS) --packages OpenRenderFix

check:
	@"$(BUILD_SCRIPT)" --check --sdk "$(SDK_DIR)" --version "$(SDK_VERSION)" --out "$(BUILD_DIR)" --prefix "$(WINE_PREFIX)" --packages "$(PACKAGES)"

clean:
	@"$(SCRIPT)" --clean --sdk "$(SDK_DIR)" --out "$(BUILD_DIR)" --packages "$(PACKAGES)"

distclean:
	@"$(SCRIPT)" --distclean --sdk "$(SDK_DIR)" --out "$(BUILD_DIR)" --prefix "$(WINE_PREFIX)" --packages "$(PACKAGES)"

help:
	@"$(SCRIPT)" --help
	@printf '\nMake targets:\n'
	@printf '  make / make build   Build all requested packages\n'
	@printf '  make openrvs        Build OpenRVS only\n'
	@printf '  make openrenderfix  Copy pinned v1.6 OpenRenderFix\n'
	@printf '  make release        Package release ZIP using the latest tag name\n'
	@printf '  make check          Verify SDK, Wine, and source prerequisites\n'
	@printf '  make clean          Remove build/ and generated SDK staging dirs\n'
	@printf '  make distclean      clean, and remove the default Wine prefix\n'
	@printf '\nExamples:\n'
	@printf '  make SDK_VERSION=156\n'
	@printf '  make STRIP=0\n'
	@printf '  make WINE_PREFIX=$$HOME/.wine-rvs\n'
	@printf '  make PACKAGES="OpenRVS"\n'
	@printf '  make DISTROBOX_NAME=  # Build locally instead of in openrvs\n'

release:
	@set -eu; \
	(cd "$(REPO_ROOT)/vendor/OpenRenderFix-v1.6" && sha256sum --check SHA256SUMS); \
	cmp "$(BUILD_DIR)/OpenRenderFix.u" "$(REPO_ROOT)/vendor/OpenRenderFix-v1.6/OpenRenderFix.u"; \
	tag=$$(git -C "$(REPO_ROOT)" tag --sort=-version:refname | head -n 1); \
	test -n "$$tag" || { echo 'No Git tags found' >&2; exit 1; }; \
	archive="$(REPO_ROOT)/OpenRVS-$$tag.zip"; \
	for file in "$(BUILD_DIR)/OpenRenderFix.u" "$(REPO_ROOT)/openrvs.ini" "$(BUILD_DIR)/OpenRVS.u" "$(REPO_ROOT)/R6ClassDefines.ini" "$(REPO_ROOT)/Servers.list"; do \
		test -f "$$file" || { echo "Missing release file: $$file" >&2; exit 1; }; \
	done; \
	python3 -c 'import pathlib, sys, zipfile; archive = zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED); [archive.write(path, pathlib.Path(path).name) for path in sys.argv[2:]]; archive.close()' "$$archive" "$(BUILD_DIR)/OpenRenderFix.u" "$(REPO_ROOT)/openrvs.ini" "$(BUILD_DIR)/OpenRVS.u" "$(REPO_ROOT)/R6ClassDefines.ini" "$(REPO_ROOT)/Servers.list"; \
	echo "Created $$archive"
