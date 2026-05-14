#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="ezbookkeeping"
APP_DISPLAY_NAME="EZBookkeeping"
APP_VERSION_VAR="EZBOOKKEEPING_VERSION"
APP_VERSION="${EZBOOKKEEPING_VERSION:-latest}"
APP_DEPS=(curl tar)
APP_FPK_PREFIX="ezbookkeeping"
APP_HELP_VERSION_EXAMPLE="1.3.2"

app_set_arch_vars() {
    case "$ARCH" in
        x86) TARBALL_ARCH="amd64" ;;
        arm) TARBALL_ARCH="arm64" ;;
    esac
    info "Tarball arch: $TARBALL_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 1.3.2       # Specific version, x86
  $0 1.3.2                  # Specific version, auto-detect arch
EOF
}

app_get_latest_version() {
    info "Getting latest version..."
    local tag
    tag=$(curl -sL "https://api.github.com/repos/mayswind/ezbookkeeping/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION="$tag"
    fi

    [ -z "$APP_VERSION" ] && error "Unable to get version, specify manually: $0 1.3.2"

    info "Target version: $APP_VERSION"
}

app_download() {
    local download_url="https://github.com/mayswind/ezbookkeeping/releases/download/v${APP_VERSION}/ezbookkeeping-v${APP_VERSION}-linux-${TARBALL_ARCH}.tar.gz"

    info "Downloading ($ARCH): $download_url"
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/ezbookkeeping.tar.gz" "$download_url" || error "Download failed"
    info "Downloaded: $(du -h "$WORK_DIR/ezbookkeeping.tar.gz" | cut -f1)"
}

app_build_app_tgz() {
    info "Extracting..."
    cd "$WORK_DIR"
    mkdir -p extracted
    tar -xzf ezbookkeeping.tar.gz -C extracted

    info "Building app.tgz..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui"
    mkdir -p "$dst/var"

    cp extracted/ezbookkeeping "$dst/ezbookkeeping"
    chmod +x "$dst/ezbookkeeping"

    cp "$PKG_DIR/bin/ezbookkeeping-server" "$dst/bin/ezbookkeeping-server"
    chmod +x "$dst/bin/ezbookkeeping-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true
    cp "$SCRIPT_DIR/var/ezbookkeeping.ini" "$dst/var/ezbookkeeping.ini"
    cp -a extracted/public "$dst/public"
    cp -a extracted/templates "$dst/templates"

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
