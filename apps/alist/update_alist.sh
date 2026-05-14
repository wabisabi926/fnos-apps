#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="alist"
APP_DISPLAY_NAME="Alist"
APP_VERSION_VAR="ALIST_VERSION"
APP_VERSION="${ALIST_VERSION:-latest}"
APP_DEPS=(curl tar unzip)
APP_FPK_PREFIX="alist"
APP_HELP_VERSION_EXAMPLE="3.40.0"

app_set_arch_vars() {
    case "$ARCH" in
        x86) ZIP_ARCH="amd64" ;;
        arm) ZIP_ARCH="arm64" ;;
    esac
    info "Zip arch: $ZIP_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 3.40.0      # 指定版本，x86 架构
  $0 3.40.0                 # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    local tag
    tag=$(curl -sL "https://api.github.com/repos/AlistGo/alist/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION="$tag"
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 3.40.0"

    info "目标版本: $APP_VERSION"
}

app_download() {
    local download_url="https://github.com/AlistGo/alist/releases/download/v${APP_VERSION}/alist-linux-${ZIP_ARCH}.tar.gz"

    info "下载 ($ARCH): $download_url"
    mkdir -p "$WORK_DIR"
    curl -fL --retry 5 --retry-delay 5 --retry-all-errors --connect-timeout 30 -o "$WORK_DIR/alist.tar.gz" "$download_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/alist.tar.gz" | cut -f1)"
}

app_build_app_tgz() {
    info "解压 alist..."
    cd "$WORK_DIR"
    tar -xzf alist.tar.gz

    info "构建 app.tgz..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui"

    local alist_bin
    alist_bin=$(find . -name "alist" -type f | head -1)
    [ -z "$alist_bin" ] && error "在 tar.gz 中找不到 alist 二进制文件"

    cp "$alist_bin" "$dst/alist"
    chmod +x "$dst/alist"

    cp "$PKG_DIR/bin/alist-server" "$dst/bin/alist-server"
    chmod +x "$dst/bin/alist-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
