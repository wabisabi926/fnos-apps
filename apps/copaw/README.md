# CoPaw for fnOS

基于 AgentScope 的个人 AI 助手工作站，支持多渠道聊天、本地大模型和定时任务。

- **官方网站**: https://copaw.bot/
- **GitHub**: https://github.com/agentscope-ai/CoPaw
- **Docker 镜像**: `agentscope/copaw`
- **默认端口**: 8088

## ⚠️ 关于版本号

fpk 文件名里的版本号（如 `copaw_1.1.7-r1`）跟踪的是 **GitHub Release 版本**
（用于 fpk 自身的可追溯性）。

但是 **docker 镜像本身使用 `agentscope/copaw:latest` 浮动 tag**，因为：

1. 上游 [agentscope/copaw](https://hub.docker.com/r/agentscope/copaw/tags) 在
   `v1.0.2` 之后**停止发布版本号 docker tag**，只维护 `:latest` 和 `:pre`
   两个滚动 tag
2. 上游官方 README [Option 3: Docker](https://github.com/agentscope-ai/CoPaw/blob/main/README.md)
   也推荐使用 `:latest`
3. 如果硬要 pin `:v1.1.7` 之类的 tag，`docker pull` 会失败（issue #140）

**影响：**

- 同一个 fpk，不同时间安装可能拉到的镜像版本不同
- fnOS 卸载-重装会强制重新 pull 一次镜像，可能拿到比卸载前更新的版本
- 想严格 pin 某个版本（例如最后的版本化 tag `v1.0.2`），可以装好后手动编辑
  `/var/apps/copaw/docker/docker-compose.yaml`，把 `:latest` 改成 `:v1.0.2`
  后重启应用

## Local Build

```bash
cd apps/copaw && ./update_copaw.sh
```
