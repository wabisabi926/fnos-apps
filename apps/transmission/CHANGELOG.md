## 2026-07-07

- 【修复】安装时镜像拉取失败问题 (issue #179)
  - 上游 linuxserver 会清理旧的按版本标签（如 `4.1.2-r0-ls350`），导致硬编码该标签的安装包拉取失败
  - docker-compose 改为固定跟踪滚动 `:latest` 标签，避免标签被清理后再次失效
  - get-latest-version.sh 版本号改为日期戳格式，准确反映滚动更新特性

## YYYY-MM-DD

- 首次发布
