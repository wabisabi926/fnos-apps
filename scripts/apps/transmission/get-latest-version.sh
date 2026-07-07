#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # linuxserver/transmission per-version tags (e.g. 4.1.2-r0-ls350) are pruned by
  # upstream over time, breaking installs that hard-pin them (issue #179).
  # docker-compose now pins the rolling :latest tag directly, so VERSION here is
  # purely for fpk metadata. Use a date-stamped sentinel for a unique CI release
  # tag per build day.
  VERSION="latest-$(date +%Y.%m.%d)"
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for transmission" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
