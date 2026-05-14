#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/gh-api.sh
source "$SCRIPT_DIR/../../lib/gh-api.sh"

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # LibreChat publishes RC tags under the same /releases endpoint, so we need
  # the full releases list to filter out -rc suffixes.
  RELEASES=$(gh_releases "danny-avila/LibreChat") || { echo "Failed to fetch releases for librechat" >&2; exit 1; }
  VERSION=$(echo "$RELEASES" \
    | jq -r '[.[] | select(.tag_name | test("^v[0-9]")) | select(.tag_name | test("-rc") | not)][0].tag_name // empty' \
    | sed 's/^v//')
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for librechat" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
