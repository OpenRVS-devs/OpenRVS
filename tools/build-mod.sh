#!/usr/bin/env bash
#
# Build OpenRVS and OpenRenderFix with Twi's Raven Shield SDK2.
#
# This script drives the Windows UCC.exe toolchain under Wine but handles all
# staging, ini generation, stripping, and artifact copying with native Linux
# tools. It does not modify the tracked source tree.
#
# Usage:
#   tools/build-mod.sh                 # build both packages for SDK 1.60
#   tools/build-mod.sh --version 156   # use the 1.56 base packages
#   tools/build-mod.sh --no-strip      # skip editor.stripsourcecommandlet
#   tools/build-mod.sh --packages OpenRVS
#   tools/build-mod.sh --check
#   tools/build-mod.sh --clean
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DEFAULT_WINE_PREFIX="$REPO_ROOT/.wine-rvs"

SDK_DIR="${SDK_DIR:-$REPO_ROOT/sdk/SDK2}"
SDK_VERSION="${SDK_VERSION:-160}"
BUILD_DIR="${BUILD_DIR:-$REPO_ROOT/build}"
WINE_PREFIX="${WINE_PREFIX:-$DEFAULT_WINE_PREFIX}"
PACKAGES="${PACKAGES:-OpenRVS OpenRenderFix}"
STRIP="${STRIP:-1}"
ALLOW_OVERWRITE="${ALLOW_OVERWRITE:-0}"

ALL_PACKAGES="OpenRVS OpenRenderFix"
MODE=build
INI_GENERATED=0
INI_HAD_ORIGINAL=0
INI_BACKUP=""
ORIG_INI=""

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }

wine_hint_from_log() {
	local log=$1

	# wine-ucc.sh already printed a detailed setup error for these cases.
	if grep -qiE 'cannot (use|create).*32-bit prefix|Wine cannot run 32-bit programs' "$log" 2>/dev/null; then
		return 0
	fi

	if grep -qiE "WINEARCH.*win32.*not supported|not supported in wow64 mode" "$log" 2>/dev/null; then
		printf 'hint: this Wine build uses WoW64 and cannot use a 32-bit prefix.\n' >&2
		printf '      Remove the prefix and retry: rm -rf %q\n' "$WINE_PREFIX" >&2
		return 0
	fi

	if grep -qiE 'wine32.*(missing|install)|could not load kernel32|failed to load ntdll' "$log" 2>/dev/null; then
		printf 'hint: Wine cannot run 32-bit programs. Install 32-bit Wine support, e.g. on Ubuntu/Debian:\n' >&2
		printf '      sudo dpkg --add-architecture i386 && sudo apt update && sudo apt install wine32:i386\n' >&2
		return 0
	fi

	return 1
}

usage() {
	cat <<'EOF'
Usage: tools/build-mod.sh [options]

Builds Raven Shield UnrealScript packages using the SDK's UCC.exe under Wine.

Options:
  --sdk DIR          SDK2 directory (default: sdk/SDK2)
  --version VER      156, 160, or 16H (default: 160)
  --out DIR          artifact directory (default: build)
  --packages LIST    space-separated package list (default: "OpenRVS OpenRenderFix")
  --strip 0|1        run the strip commandlet (default: 1)
  --no-strip         same as --strip 0
  --check            check prerequisites and exit
  --clean            remove build artifacts and staged sources
  --distclean        clean and remove the default Wine prefix
  -h, --help

Environment:
  SDK_DIR, SDK_VERSION, BUILD_DIR, WINE_PREFIX, WINE, STRIP, ALLOW_OVERWRITE

Outputs:
  build/OpenRVS.u
  build/OpenRenderFix.u
  build/OpenRenderFix.utx   (same package, for installs that use .utx)
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--sdk)
			[[ $# -ge 2 ]] || die "--sdk requires a value"
			SDK_DIR="$2"
			shift 2
			;;
		--version)
			[[ $# -ge 2 ]] || die "--version requires a value"
			SDK_VERSION="$2"
			shift 2
			;;
		--out)
			[[ $# -ge 2 ]] || die "--out requires a value"
			BUILD_DIR="$2"
			shift 2
			;;
		--prefix)
			[[ $# -ge 2 ]] || die "--prefix requires a value"
			WINE_PREFIX="$2"
			shift 2
			;;
		--packages)
			[[ $# -ge 2 ]] || die "--packages requires a value"
			PACKAGES="$2"
			shift 2
			;;
		--strip)
			[[ $# -ge 2 ]] || die "--strip requires a value"
			STRIP="$2"
			shift 2
			;;
		--no-strip)
			STRIP=0
			shift
			;;
		--check)
			MODE=check
			shift
			;;
		--clean)
			MODE=clean
			shift
			;;
		--distclean)
			MODE=distclean
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			die "unknown option: $1 (try --help)"
			;;
	esac
done

case "$SDK_VERSION" in
	156 | 160)
		;;
	16h | 16H)
		SDK_VERSION=16H
		;;
	*)
		die "unsupported SDK version: $SDK_VERSION (use 156, 160, or 16H)"
		;;
esac

case "$STRIP" in
	1 | true | yes)
		STRIP=1
		;;
	0 | false | no)
		STRIP=0
		;;
	*)
		die "invalid STRIP value: $STRIP (use 0 or 1)"
		;;
esac

SDK_DIR="$(realpath -m -- "$SDK_DIR")"
BUILD_DIR="$(realpath -m -- "$BUILD_DIR")"
WINE_PREFIX="$(realpath -m -- "$WINE_PREFIX")"

CE="$SDK_DIR/Code Environment"
SYS="$CE/system"
UCC="$SYS/UCC.exe"
VERSION_DIR="$CE/SDK$SDK_VERSION"

# Keep these exported for tools/wine-ucc.sh.
export SDK_DIR WINE_PREFIX
if [[ -n "${WINE:-}" ]]; then
	export WINE
fi

validate_packages() {
	local p
	for p in $PACKAGES; do
		case " $ALL_PACKAGES " in
			*" $p "*)
				;;
			*)
				die "unknown package: $p (known: $ALL_PACKAGES)"
				;;
		esac
	done
	if [[ -z "${PACKAGES// /}" ]]; then
		die "no packages requested"
	fi
}

check_prereqs() {
	local fail=0 p

	if [[ ! -f "$UCC" ]]; then
		printf 'error: UCC.exe not found at %s\n' "$UCC" >&2
		printf '       Set SDK_DIR to the SDK2 directory (default: %s).\n' "$REPO_ROOT/sdk/SDK2" >&2
		fail=1
	fi

	if [[ ! -d "$VERSION_DIR" ]]; then
		printf 'error: SDK %s base packages not found at %s\n' "$SDK_VERSION" "$VERSION_DIR" >&2
		fail=1
	fi

	if [[ ! -f "$SYS/ravenshield.config" ]]; then
		printf 'error: %s is missing\n' "$SYS/ravenshield.config" >&2
		fail=1
	fi

	for p in $PACKAGES; do
		if [[ ! -d "$REPO_ROOT/$p/classes" ]]; then
			printf 'error: source directory not found: %s\n' "$REPO_ROOT/$p/classes" >&2
			fail=1
		fi
	done

	if ! "$SCRIPT_DIR/wine-ucc.sh" --check; then
		fail=1
	fi

	if [[ $fail -ne 0 ]]; then
		printf '\nBuild prerequisites are incomplete. See docs/building-linux.md.\n' >&2
		exit 1
	fi

	log "SDK:      $SDK_DIR"
	log "version:  $SDK_VERSION ($VERSION_DIR)"
	log "packages: $PACKAGES"
	log "output:   $BUILD_DIR"
}

stage_sources() {
	local p src dst

	for p in $PACKAGES; do
		src="$REPO_ROOT/$p/classes"
		dst="$CE/$p"

		[[ -d "$src" ]] || die "source directory not found: $src"

		if [[ -e "$dst" || -L "$dst" ]]; then
			if [[ -f "$dst/.openrvs-staged" ]]; then
				rm -rf -- "$dst"
			elif [[ "$ALLOW_OVERWRITE" == 1 ]]; then
				warn "overwriting $dst because ALLOW_OVERWRITE=1"
				rm -rf -- "$dst"
			else
				die "refusing to overwrite '$dst': it was not created by this build. Remove it or set ALLOW_OVERWRITE=1."
			fi
		fi

		mkdir -p -- "$dst"
		# The SDK expects a "Classes" directory. The repository uses
		# lowercase "classes" (fine on Windows, but stage the SDK spelling).
		cp -a -- "$src" "$dst/Classes"
		{
			printf 'Staged from %s by tools/build-mod.sh.\n' "$src"
			printf 'This directory is generated and safe to delete.\n'
		} >"$dst/.openrvs-staged"

		log "staged $p -> $dst/Classes"
	done
}

select_sdk_version() {
	local packages

	[[ -d "$VERSION_DIR" ]] || die "SDK version directory not found: $VERSION_DIR"
	shopt -s nullglob
	packages=("$VERSION_DIR"/*.u)
	shopt -u nullglob
	[[ ${#packages[@]} -gt 0 ]] || die "no .u packages in $VERSION_DIR"

	log "installing $SDK_VERSION base packages into $SYS"
	cp -a -- "${packages[@]}" "$SYS/"
	if [[ -f "$VERSION_DIR/version.bat" ]]; then
		cp -a -- "$VERSION_DIR/version.bat" "$SYS/"
	fi
}

cleanup_ini() {
	if [[ "$INI_GENERATED" != 1 ]]; then
		return
	fi
	if [[ "$INI_HAD_ORIGINAL" == 1 && -n "$INI_BACKUP" && -f "$INI_BACKUP" ]]; then
		mv -f -- "$INI_BACKUP" "$ORIG_INI"
	elif [[ -n "$ORIG_INI" && -f "$ORIG_INI" ]]; then
		rm -f -- "$ORIG_INI"
	fi
	INI_GENERATED=0
}

generate_ini() {
	ORIG_INI="$SYS/ravenshield.ini"
	mkdir -p -- "$BUILD_DIR"

	if [[ -f "$ORIG_INI" ]]; then
		INI_BACKUP="$(mktemp "$BUILD_DIR/.ravenshield.ini.XXXXXX")"
		cp -a -- "$ORIG_INI" "$INI_BACKUP"
		INI_HAD_ORIGINAL=1
	else
		INI_HAD_ORIGINAL=0
	fi
	INI_GENERATED=1
	trap cleanup_ini EXIT

	# Use the SDK's pristine template, drop the placeholder package, and add
	# the requested packages. Keep CRLF line endings for the UE2 ini parser.
	awk -v pkgs="$PACKAGES" '
		BEGIN { ORS = "\r\n" }
		{
			sub(/\r$/, "", $0)
			if ($0 ~ /^EditPackages=(RSTSDKSAMPLEPACKAGE|OpenRVS|OpenRenderFix)$/) next
			print
		}
		END {
			n = split(pkgs, a, " ")
			for (i = 1; i <= n; i++) print "EditPackages=" a[i]
		}
	' "$SYS/ravenshield.config" >"$ORIG_INI"

	log "generated ravenshield.ini (EditPackages: $PACKAGES)"
}

compile_packages() {
	local p errors status

	mkdir -p -- "$BUILD_DIR"
	UCC_LOG="$BUILD_DIR/ucc.log"
	: >"$UCC_LOG"

	# UCC only rebuilds a package when its .u is missing or older than its
	# sources. Remove the requested outputs so every build starts clean.
	for p in $PACKAGES; do
		rm -f -- "$SYS/$p.u" "$SYS/$p.utx"
	done

	log "running: ucc make"
	rm -f -- "$SYS/UCC.log"
	set +e
	"$SCRIPT_DIR/wine-ucc.sh" make 2>&1 | tee -a "$UCC_LOG"
	status=${PIPESTATUS[0]}
	set -e

	# UCC also writes a more detailed log in system/UCC.log. Prefer it when
	# available so build/ucc.log and the error scan see the full output.
	if [[ -s "$SYS/UCC.log" ]]; then
		cp -f -- "$SYS/UCC.log" "$UCC_LOG"
	fi

	# A Wine/prefix setup failure is not a compiler error. wine-ucc.sh prints
	# the details; stop here instead of also claiming UCC produced no output.
	if [[ $status -ne 0 ]] && wine_hint_from_log "$UCC_LOG"; then
		die "Wine could not start UCC.exe; see $UCC_LOG"
	fi

	# The known appPreExit shutdown fault emits a whole Critical stack, not
	# just an appPreExit line. Ignore that stack only after a successful make
	# has entered shutdown. Errors before shutdown (and all Error lines) stay
	# fatal; output files are checked below as well.
	errors="$(awk '
		{ sub(/\r$/, "") }
		/^Log: Success - 0 error\(s\)/ { success = 1 }
		success && /^Exit: Preparing to exit\./ { shutdown = 1 }
		/^(Error|Critical)[:,]/ {
			if (shutdown && /^Critical[:,]/) {
				stack = stack $0 "\n"
				if ($0 == "Critical: UObject::StaticExit") static_exit = 1
				if ($0 == "Critical: appPreExit") app_pre_exit = 1
			} else print
		}
		END {
			if (!(static_exit && app_pre_exit)) printf "%s", stack
		}
	' "$UCC_LOG")"
	if [[ -n "$errors" ]]; then
		printf '%s\n' "$errors" >&2
		wine_hint_from_log "$UCC_LOG"
		die "ucc reported errors; see $UCC_LOG"
	fi

	for p in $PACKAGES; do
		if [[ ! -s "$SYS/$p.u" ]]; then
			wine_hint_from_log "$UCC_LOG"
			die "ucc did not produce $SYS/$p.u; see $UCC_LOG"
		fi
	done

	if [[ $status -ne 0 ]]; then
		if ! grep -aq 'Success - 0 error(s)' "$UCC_LOG"; then
			wine_hint_from_log "$UCC_LOG"
			die "ucc make failed (exit $status); see $UCC_LOG"
		fi
		warn "ucc make exited $status but reported success (possibly appPreExit); continuing"
	fi

	log "compiled: $PACKAGES"
}

strip_packages() {
	local p before after

	if [[ "$STRIP" != 1 ]]; then
		log "skipping strip (STRIP=0)"
		return
	fi

	for p in $PACKAGES; do
		[[ -f "$SYS/$p.u" ]] || die "cannot strip missing package: $SYS/$p.u"
		before="$(stat -c%s -- "$SYS/$p.u")"

		log "stripping $p.u"
		if ! "$SCRIPT_DIR/wine-ucc.sh" editor.stripsourcecommandlet "$p.u" 2>&1 | tee -a "$UCC_LOG"; then
			wine_hint_from_log "$UCC_LOG"
			die "strip failed for $p.u; set STRIP=0 to build unstripped packages"
		fi

		[[ -f "$SYS/$p.u" ]] || die "strip removed $p.u"
		after="$(stat -c%s -- "$SYS/$p.u")"
		log "  $p.u: $before -> $after bytes"
	done
}

copy_artifacts() {
	local p artifacts=()

	mkdir -p -- "$BUILD_DIR"
	rm -f -- "$BUILD_DIR/OpenRVS.u" "$BUILD_DIR/OpenRVS.utx"
	rm -f -- "$BUILD_DIR/OpenRenderFix.u" "$BUILD_DIR/OpenRenderFix.utx"

	for p in $PACKAGES; do
		cp -f -- "$SYS/$p.u" "$BUILD_DIR/$p.u"
		artifacts+=("$BUILD_DIR/$p.u")

		# Raven Shield installs OpenRenderFix as a .utx package. Emit both
		# extensions so the artifact works with either instruction set.
		if [[ "$p" == "OpenRenderFix" ]]; then
			cp -f -- "$SYS/$p.u" "$BUILD_DIR/$p.utx"
			artifacts+=("$BUILD_DIR/$p.utx")
		fi
	done

	log "artifacts:"
	ls -l -- "${artifacts[@]}"
}

clean_build() {
	local p

	rm -rf -- "$BUILD_DIR"
	for p in $ALL_PACKAGES; do
		rm -f -- "$SYS/$p.u" "$SYS/$p.utx"
	done
	log "removed build outputs"
}

clean_staged() {
	local p dst

	for p in $ALL_PACKAGES; do
		dst="$CE/$p"
		if [[ -f "$dst/.openrvs-staged" ]]; then
			rm -rf -- "$dst"
			log "removed staged $p"
		fi
	done
}

validate_packages

case "$MODE" in
	check)
		check_prereqs
		log "ready to build"
		;;
	clean)
		clean_build
		clean_staged
		;;
	distclean)
		clean_build
		clean_staged
		if [[ "$WINE_PREFIX" == "$DEFAULT_WINE_PREFIX" ]]; then
			rm -rf -- "$WINE_PREFIX"
			log "removed Wine prefix $WINE_PREFIX"
		else
			log "not removing custom WINE_PREFIX: $WINE_PREFIX"
		fi
		;;
	build)
		check_prereqs
		stage_sources
		select_sdk_version
		generate_ini
		compile_packages
		strip_packages
		copy_artifacts
		;;
esac
