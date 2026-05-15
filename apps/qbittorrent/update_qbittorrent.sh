#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="qbittorrent"
APP_DISPLAY_NAME="qBittorrent"
APP_VERSION_VAR="QB_VERSION"
APP_VERSION="${QB_VERSION:-latest}"
APP_DEPS=(curl tar sed)
APP_FPK_PREFIX="qBittorrent"
APP_HELP_VERSION_EXAMPLE="5.1.4"

RELEASE_TAG=""

app_set_arch_vars() {
    case "$ARCH" in
        x86) BINARY_PREFIX="x86_64" ;;
        arm) BINARY_PREFIX="aarch64" ;;
    esac
    info "Binary prefix: $BINARY_PREFIX"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 5.1.4       # 指定版本，x86 架构
  $0 5.1.4                  # 指定版本，自动检测架构
EOF
}

app_show_help_extra() {
    cat << EOF

说明:
  默认用户名: admin
  默认密码: adminadmin
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    RELEASE_TAG=$(curl -sL "https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(echo "$RELEASE_TAG" | sed -E 's/release-([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/')
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 5.1.4"

    info "目标版本: $APP_VERSION"
    info "Release Tag: $RELEASE_TAG"
}

app_download() {
    local download_url="https://github.com/userdocs/qbittorrent-nox-static/releases/download/${RELEASE_TAG}/${BINARY_PREFIX}-qbittorrent-nox"

    info "下载 qbittorrent-nox ($ARCH)..."
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/qbittorrent-nox" "$download_url" || error "下载 qbittorrent-nox 失败"
    chmod +x "$WORK_DIR/qbittorrent-nox"
    info "下载完成: $(du -h "$WORK_DIR/qbittorrent-nox" | cut -f1)"

    local year_month
    year_month=$(date +%Y-%m)
    local geodb_url="https://download.db-ip.com/free/dbip-country-lite-${year_month}.mmdb.gz"

    info "下载 GeoDB (${year_month})..."
    mkdir -p "$WORK_DIR/GeoDB"

    if curl -L -f -o "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz" "$geodb_url" 2>/dev/null; then
        gunzip -f "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz"
        info "GeoDB 下载完成: $(du -h "$WORK_DIR/GeoDB/dbip-country-lite.mmdb" | cut -f1)"
    else
        warn "GeoDB 下载失败，尝试上月版本..."
        year_month=$(date -v-1m +%Y-%m 2>/dev/null || date -d "1 month ago" +%Y-%m)
        geodb_url="https://download.db-ip.com/free/dbip-country-lite-${year_month}.mmdb.gz"
        curl -L -f -o "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz" "$geodb_url" || warn "GeoDB 下载失败，跳过"
        [ -f "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz" ] && gunzip -f "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz"
    fi
}

app_build_app_tgz() {
    info "构建 app.tgz..."

    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui/images" "$dst/var/qBittorrent/config" "$dst/var/qBittorrent/data/GeoDB"

    cp "$WORK_DIR/qbittorrent-nox" "$dst/bin/"
    chmod +x "$dst/bin/qbittorrent-nox"

    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true
    cp -a "$WORK_DIR/GeoDB"/* "$dst/var/qBittorrent/data/GeoDB/" 2>/dev/null || true
    cp "$PKG_DIR/defaults/qBittorrent.conf" "$dst/var/qBittorrent/config/qBittorrent.conf"

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
