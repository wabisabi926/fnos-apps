#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
ZIP_ARCH="${ZIP_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building Syncthing ${VERSION} for ${ZIP_ARCH}"

DOWNLOAD_URL="https://github.com/syncthing/syncthing/releases/download/v${VERSION}/syncthing-linux-${ZIP_ARCH}-v${VERSION}.tar.gz"

# Download with integrity verification + retry. GitHub Actions runners
# intermittently receive a full-length-but-corrupt payload over HTTP/2 from
# the release-assets CDN, which silently produced a binary-less app.tgz
# ("app.tgz too small"). Force HTTP/1.1, verify the gzip CRC, and re-fetch on
# corruption so a bad transfer can never reach packaging.
for attempt in 1 2 3 4 5; do
  curl -fL --http1.1 --retry 3 --retry-delay 2 --retry-all-errors \
    -o syncthing.tar.gz "$DOWNLOAD_URL"
  if gzip -t syncthing.tar.gz 2>/dev/null; then
    break
  fi
  echo "  attempt ${attempt}: corrupt download ($(wc -c < syncthing.tar.gz) bytes), retrying..." >&2
  rm -f syncthing.tar.gz
  [ "$attempt" -eq 5 ] && { echo "ERROR: could not obtain a valid syncthing tarball after 5 attempts" >&2; exit 1; }
  sleep 3
done

tar -xzf syncthing.tar.gz

mkdir -p app_root/bin app_root/ui
# Require a real (>1MB) binary so a partial extraction can never yield a tiny app.tgz.
SYNCTHING_BIN=$(find . -path "*/syncthing-linux-*/syncthing" -type f -size +1M -print -quit)
[ -z "$SYNCTHING_BIN" ] && { echo "syncthing binary (>1MB) not found after extraction" >&2; exit 1; }

cp "$SYNCTHING_BIN" app_root/syncthing
chmod +x app_root/syncthing

cp apps/syncthing/fnos/bin/syncthing-server app_root/bin/syncthing-server
chmod +x app_root/bin/syncthing-server
cp -a apps/syncthing/fnos/ui/* app_root/ui/ 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
