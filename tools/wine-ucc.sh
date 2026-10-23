#!/usr/bin/env bash
#
# Run Raven Shield's UCC.exe under Wine from the SDK's system directory.
#
# UCC.exe is a 32-bit Windows program that loads Core.dll, Engine.dll,
# Editor.dll, and the R6*.dll modules from the current directory. It must be
# started with the SDK's "Code Environment/system" directory as its working
# directory because ravenshield.ini uses relative paths.
#
# Environment:
#   SDK_DIR       SDK2 directory (default: <repo>/sdk/SDK2)
#   WINE_PREFIX   Wine prefix (default: <repo>/.wine-rvs)
#   WINE          Wine executable (default: wine, then wine64)
#   WINEDEBUG     Passed through; defaults to "-all"
#
# Usage:
#   tools/wine-ucc.sh --check
#   tools/wine-ucc.sh make
#   tools/wine-ucc.sh editor.stripsourcecommandlet OpenRVS.u
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

log() { printf '==> %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
	cat <<'EOF'
Usage: tools/wine-ucc.sh [--check] [UCC arguments...]

Runs Raven Shield's UCC.exe under Wine from the SDK's system directory.
The first run creates a Wine prefix at .wine-rvs unless WINE_PREFIX is set.
On 64-bit hosts the prefix is 64-bit (WoW64), which can still run the
32-bit UCC.exe. On 32-bit hosts, or if WINEARCH is set explicitly, that
architecture is used instead.

Options:
  --check   Verify that Wine and UCC.exe are available, then exit.
  -h, --help
EOF
}

CHECK_ONLY=0
case "${1:-}" in
	--check)
		CHECK_ONLY=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
esac

SDK_DIR="${SDK_DIR:-$REPO_ROOT/sdk/SDK2}"
WINE_PREFIX="${WINE_PREFIX:-$REPO_ROOT/.wine-rvs}"

[[ -d "$SDK_DIR" ]] || die "SDK directory not found: $SDK_DIR (set SDK_DIR)"
SDK_DIR="$(cd -- "$SDK_DIR" && pwd)"
WINE_PREFIX="$(realpath -m -- "$WINE_PREFIX")"

SYS="$SDK_DIR/Code Environment/system"
UCC="$SYS/UCC.exe"

[[ -f "$UCC" ]] || die "UCC.exe not found at $UCC (set SDK_DIR to the SDK2 directory)"

if [[ -z "${WINE:-}" ]]; then
	if command -v wine >/dev/null 2>&1; then
		WINE=wine
	elif command -v wine64 >/dev/null 2>&1; then
		WINE=wine64
	else
		die "Wine is not installed. Install Wine (with 32-bit support) to run UCC.exe, or use a Windows build host."
	fi
fi
command -v "$WINE" >/dev/null 2>&1 || die "Wine executable not found: $WINE"

if [[ "$CHECK_ONLY" == 1 ]]; then
	printf 'wine: %s\n' "$("$WINE" --version 2>/dev/null || printf 'unknown')"
	printf 'UCC:  %s\n' "$UCC"
	printf 'prefix: %s\n' "$WINE_PREFIX"
	if [[ "${WINEARCH:-}" == win32 ]]; then
		printf 'note: WINEARCH=win32 only works with traditional Wine builds; WoW64 Wine needs a 64-bit prefix.\n' >&2
	fi
	exit 0
fi

export WINEPREFIX="$WINE_PREFIX"

# Wine builds using WoW64 (common on Ubuntu 24.04+/26.04 and other recent
# distributions) can run 32-bit PE programs from a 64-bit prefix, but reject
# WINEARCH=win32. Prefer a 64-bit prefix on 64-bit hosts. A 32-bit host, an
# existing 32-bit prefix, or an explicit WINEARCH setting still uses win32.
default_arch=win64
case "$(uname -m)" in
	i?86) default_arch=win32 ;;
esac
requested_arch="${WINEARCH:-}"

prefix_arch=""
if [[ -s "$WINEPREFIX/system.reg" ]]; then
	if grep -q '^#arch=win32' "$WINEPREFIX/system.reg"; then
		prefix_arch=win32
	elif grep -q '^#arch=win64' "$WINEPREFIX/system.reg"; then
		prefix_arch=win64
	fi
fi

if [[ -n "$prefix_arch" ]]; then
	if [[ -n "$requested_arch" && "$requested_arch" != "$prefix_arch" ]]; then
		die "WINEARCH=$requested_arch does not match the existing $prefix_arch prefix at '$WINEPREFIX'. Remove it or unset WINEARCH."
	fi
	WINEARCH="$prefix_arch"
else
	WINEARCH="${requested_arch:-$default_arch}"
fi
export WINEARCH

# Keep Wine from prompting for Mono/Gecko; UCC.exe needs neither.
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree,mshtml=}"

# An existing 32-bit prefix is not usable with a WoW64-only Wine build. Probe
# it once with wineboot; older Wine builds accept this and keep working.
if [[ "$prefix_arch" == win32 && "$default_arch" == win64 ]]; then
	set +e
	probe_output="$(WINEDEBUG= "$WINE" wineboot -u 2>&1)"
	probe_status=$?
	set -e
	if [[ $probe_status -ne 0 ]] && grep -qiE "WINEARCH.*win32.*not supported|not supported in wow64 mode" <<<"$probe_output"; then
		[[ -z "$probe_output" ]] || printf '%s\n' "$probe_output" >&2
		die "This Wine build is in WoW64 mode and cannot use the existing 32-bit prefix at '$WINEPREFIX'.
Remove it and retry; the build will create a 64-bit prefix, which can still run the 32-bit UCC.exe:
  rm -rf '$WINEPREFIX'"
	fi
fi

if [[ ! -s "$WINEPREFIX/system.reg" ]]; then
	log "creating $WINEARCH Wine prefix: $WINEPREFIX"
	mkdir -p -- "$WINEPREFIX"

	# Do not hide wineboot's diagnostics. In particular, the "wine32 is
	# missing" message is the only useful clue when the host has 64-bit Wine
	# but no 32-bit runtime. WINEDEBUG is intentionally cleared for this step.
	set +e
	wineboot_output="$(WINEDEBUG= "$WINE" wineboot -u 2>&1)"
	wineboot_status=$?
	set -e

	if [[ $wineboot_status -ne 0 || ! -s "$WINEPREFIX/system.reg" ]]; then
		[[ -z "$wineboot_output" ]] || printf '%s\n' "$wineboot_output" >&2

		if grep -qiE "WINEARCH.*win32.*not supported|not supported in wow64 mode" <<<"$wineboot_output"; then
			die "This Wine build is in WoW64 mode and cannot create a 32-bit prefix.
Remove '$WINEPREFIX' and retry without WINEARCH=win32. The build will create
a 64-bit prefix, which can still run the 32-bit UCC.exe:
  rm -rf '$WINEPREFIX'"
		fi

		if grep -qiE 'wine32.*(missing|install)|32-bit.*(missing|support)|could not load kernel32|failed to load ntdll' <<<"$wineboot_output"; then
			die "Wine cannot run 32-bit programs because 32-bit Wine support is missing.
If your Wine build is a traditional (non-WoW64) build, install the 32-bit runtime:
  sudo dpkg --add-architecture i386
  sudo apt update
  sudo apt install wine32:i386
Then remove the incomplete prefix and retry:
  rm -rf '$WINEPREFIX'"
		fi

		if grep -qi '64-bit prefix' <<<"$wineboot_output"; then
			die "Wine selected a 64-bit prefix. Remove '$WINEPREFIX' or set WINE_PREFIX to a new path."
		fi

		die "failed to initialize the Wine prefix at '$WINEPREFIX' (wineboot exit $wineboot_status). If the prefix is incomplete, remove it and retry: rm -rf '$WINEPREFIX'"
	fi
fi

[[ -s "$WINEPREFIX/system.reg" ]] || die "Wine prefix was not initialized: $WINEPREFIX"

# UCC.exe is noisy under Wine's fixme channels; keep the build output clean.
export WINEDEBUG="${WINEDEBUG:--all}"

cd -- "$SYS"
exec "$WINE" UCC.exe "$@"
