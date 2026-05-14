#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
ZIP_ARCH="${ZIP_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building Alist ${VERSION} for ${ZIP_ARCH}"

DOWNLOAD_URL="https://github.com/AlistGo/alist/releases/download/v${VERSION}/alist-linux-${ZIP_ARCH}.tar.gz"
curl -fL --retry 5 --retry-delay 5 --retry-all-errors --connect-timeout 30 -o alist.tar.gz "$DOWNLOAD_URL"

tar -xzf alist.tar.gz

mkdir -p app_root/bin app_root/ui
ALIST_BIN=$(find . -name "alist" -type f | head -1)
[ -z "$ALIST_BIN" ] && { echo "alist binary not found in tarball" >&2; exit 1; }

cp "$ALIST_BIN" app_root/alist
chmod +x app_root/alist

cp apps/alist/fnos/bin/alist-server app_root/bin/alist-server
chmod +x app_root/bin/alist-server
cp -a apps/alist/fnos/ui/* app_root/ui/ 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
