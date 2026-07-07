#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

# Pinned to Cloudreve 3.8.3 — the final V3 release.
# Cloudreve V4 is a ground-up rewrite with an incompatible database/config that
# requires a MANUAL `cloudreve migrate` step; auto-updating V3 users to V4 wipes
# their data (issue #163). V3 is EOL, so 3.8.3 is a fixed, stable target. To move
# to V4 intentionally (with a migration plan), pass the version explicitly.
PINNED_VERSION="3.8.3"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="${INPUT_VERSION#v}"
else
  VERSION="$PINNED_VERSION"
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for cloudreve" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
