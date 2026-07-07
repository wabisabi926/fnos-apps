#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/meta.env"

VERSION="${VERSION:-latest}"
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

mkdir -p "${WORK_DIR}/docker"
cp "${SCRIPT_DIR}/../../../apps/transmission/fnos/docker/docker-compose.yaml" "${WORK_DIR}/docker/"
# NOTE: docker-compose.yaml no longer contains ${VERSION} — the transmission image
# is pinned to :latest (rolling) because linuxserver prunes old per-version tags
# (issue #179). VERSION is still propagated for fpk metadata (filename, manifest).

cp -a "${SCRIPT_DIR}/../../../apps/transmission/fnos/ui" "${WORK_DIR}/ui"

cd "${WORK_DIR}"
tar czf "${SCRIPT_DIR}/../../../app.tgz" docker/ ui/

echo "Built app.tgz for transmission ${VERSION}"
