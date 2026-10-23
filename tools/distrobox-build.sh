#!/usr/bin/env bash
# Run the build in the configured Distrobox, preserving arguments and overrides.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
box="${DISTROBOX_NAME-openrvs}"

if [[ -z "$box" || "${CONTAINER_ID:-}" == "$box" ]]; then
	exec "$SCRIPT_DIR/build-mod.sh" "$@"
fi

if ! command -v distrobox >/dev/null 2>&1; then
	printf 'error: distrobox is required to build in %s; use DISTROBOX_NAME= to build locally.\n' "$box" >&2
	exit 1
fi

# Distrobox does not automatically forward arbitrary host environment values.
overrides=()
for name in WINE WINE_PREFIX WINEARCH STRIP ALLOW_OVERWRITE WINEDEBUG; do
	if [[ -v "$name" ]]; then
		overrides+=("$name=${!name}")
	fi
done

exec distrobox enter --name "$box" -- env "${overrides[@]}" "$SCRIPT_DIR/build-mod.sh" "$@"
