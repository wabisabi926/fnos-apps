自动构建的 fnOS 安装包

- 基于 [Komari ${VERSION}](https://github.com/komari-monitor/komari/releases/tag/${VERSION})
- 平台: fnOS
- 默认端口: ${DEFAULT_PORT}${REVISION_NOTE}
- 默认数据目录: `${TRIM_PKGVAR}/data`

**首次使用**:
1. 访问 `http://your-nas-ip:${DEFAULT_PORT}` 即可使用
2. 默认管理员账号密码会在容器启动日志中打印，可通过 `docker logs komari` 查看
3. 被监控的服务器需要安装 Komari agent，详见 [官方文档](https://komari-document.pages.dev/)

**镜像源说明**: Komari 镜像托管在 ghcr.io，DaoCloud 公益镜像源未收录。建议使用 `docker.1ms.run` 或 `docker.1panel.live`。

${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
