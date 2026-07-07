## 2026-07-07

- 【修复】照片备份上传失败问题 (issue #164)
  - 根因:museum 未配置 S3/对象存储,fallback 到不可达的 localhost endpoint;MinIO 监听 :9000 且未发布、存储桶未创建
  - docker-compose 补全 S3 配置(are_local_buckets + b2-eu-cen 桶),MinIO 改为监听 :3200 并发布端口
  - 新增 ente-minio-init 初始化容器,首次启动自动创建 b2-eu-cen 存储桶
  - museum endpoint 由安装向导「NAS 局域网 IP」字段直接注入 compose（fnOS 在创建容器前替换 `${wizard_s3_endpoint}`，规避 issue #146 的时序陷阱）
  - 安装向导新增「NAS 局域网 IP」必填项与上传说明

## 2026-05-21

- 【修复】Docker 镜像拉取失败问题 (issue #139)
  - 上游 ghcr.io/ente-io/server 不发布 semver 标签，改为 `:latest` 滚动跟踪
  - 更新 get-latest-version.sh：版本号改为日期戳格式，准确反映滚动更新特性
  - 更新安装向导提示：明确镜像加速器仅对 docker.io 生效，ghcr.io 需直接连接
  - 修复 release-notes.tpl 中指向 GitHub Release 的链接格式

## 2026-03-03

- 首次发布
- 内置 PostgreSQL 和 MinIO 依赖容器
