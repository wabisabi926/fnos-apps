#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # next-ai-draw-io publishes only a rolling ghcr `:latest` tag (no semver); the
  # compose pins :latest directly. Emit a date-stamped sentinel so the fpk release
  # tag is unique + meaningful per build (cf. ente #139).
  VERSION="latest-$(date +%Y.%m.%d)"
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for next-ai-draw-io" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
