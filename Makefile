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

.PHONY: all build check clean distclean openrvs openrenderfix help

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
	@printf '  make openrenderfix  Build OpenRenderFix only\n'
	@printf '  make check          Verify SDK, Wine, and source prerequisites\n'
	@printf '  make clean          Remove build/ and generated SDK staging dirs\n'
	@printf '  make distclean      clean, and remove the default Wine prefix\n'
	@printf '\nExamples:\n'
	@printf '  make SDK_VERSION=156\n'
	@printf '  make STRIP=0\n'
	@printf '  make WINE_PREFIX=$$HOME/.wine-rvs\n'
	@printf '  make PACKAGES="OpenRVS"\n'
	@printf '  make DISTROBOX_NAME=  # Build locally instead of in openrvs\n'
