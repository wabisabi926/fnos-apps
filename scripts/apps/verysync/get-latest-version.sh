#!/bin/bash
set -uo pipefail

INPUT_VERSION="${1:-}"
# Verysync is closed-source; its download.php redirect is unreliable from non-CN
# CI networks, so fall back to a known-good version when resolution fails (#117).
PINNED_FALLBACK="2.21.3"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="${INPUT_VERSION#v}"
else
  EFFECTIVE_URL=$(curl -Ls --max-time 20 -o /dev/null -w '%{url_effective}' "https://www.verysync.com/download.php?platform=linux-amd64" 2>/dev/null || true)
  VERSION=$(printf '%s\n' "$EFFECTIVE_URL" | sed -nE 's|.*/verysync-linux-amd64-v([0-9][^/]*)\.tar\.gz$|\1|p')
  [ -z "$VERSION" ] && VERSION="$PINNED_FALLBACK"
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for verysync" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
