# FPK 测试分层

新应用合入前必须跑过的三层测试。本页是单页速查 —— 完整流程请看 [`docs/adding-new-apps.md` § 8](../adding-new-apps.md#8-测试)。

## 总览

| 层 | 脚本 | 模拟到哪一步 | 覆盖范围 | 依赖 |
|----|------|--------------|----------|------|
| **L1 静态** | `scripts/test/static-check.sh` | — | 脚手架完整性、manifest 合规、bash 语法、`pkill -f` 等坑 | `jq` |
| **L2 契约** | `scripts/test/verify-fpk.sh` | 不安装，仅校验 `.fpk` 产物 | tar 结构、必含项、`md5(app.tgz)` 等于 `manifest.checksum`、ELF 架构、Docker image 可拉取 | `jq` `tar` `file` |
| **L3 安装/运行** | `scripts/test/run-fpk-tests.sh` | `install_init` → `cmd/main start` → 探活 → `stop` → `uninstall` | 安装测试 + 运行测试 + 卸载残留检查 | Docker |
| **L3 升级** | `scripts/test/run-fpk-tests.sh --upgrade-from <old.fpk>` | 在 L3 基础上多走一遍 `upgrade_init` / `upgrade_callback` | 升级测试 + `service_*upgrade` 钩子 + 用户数据持久性 | Docker |

## L1：静态检查

```bash
bash scripts/test/static-check.sh <slug>           # 单个应用
bash scripts/test/static-check.sh                  # 全部应用
```

通过条件：脚本退出码 0，无 `[ERROR]` 行。

典型失败：
- manifest 字段缺失或与 `meta.env` 不一致（`appname` ↔ `FILE_PREFIX`、`service_port` ↔ `DEFAULT_PORT`）
- 图标 < 256 B（伪空文件）
- `cmd/service-setup` 含 `pkill -f`（issue #112 footgun，必须用 `pkill -x` 或行尾加 `# pkill-f-ok`）
- `get-latest-version.sh` 没有 `echo VERSION=...`
- 脚手架 TODO 标记未清理

## L2：verify-fpk 契约

```bash
bash scripts/test/verify-fpk.sh dist/<slug>_<ver>_x86.fpk
bash scripts/test/verify-fpk.sh dist/<slug>_<ver>_arm.fpk
```

通过条件：每条 check 都 `✓`，summary 行为 PASS。

校验项：
- `.fpk` 是合法 gzip tar
- 必含 `manifest`、`app.tgz`、`cmd/main`、`cmd/common`、`cmd/installer`、`cmd/install_init`、`cmd/install_callback`、`cmd/uninstall_init`、`cmd/uninstall_callback`、`cmd/upgrade_init`、`cmd/upgrade_callback`、`ICON.PNG`、`ICON_256.PNG`
- `manifest.checksum` 等于 `md5(app.tgz)`
- `manifest.platform` 与文件名后缀（`_x86` / `_arm`）一致
- 原生应用：所有 ELF 文件架构匹配（x86 → `x86-64`，arm → `aarch64`）
- Docker 应用：`docker-compose.yaml` 里的 `image:` 在 Registry 可拉取

## L3：fpk-runner 安装 + 运行

```bash
bash scripts/test/run-fpk-tests.sh dist/<slug>_<ver>_x86.fpk
```

通过条件：所有子步骤退出码 0，最终 summary 为 PASS。

容器内执行序列：

```
1. install     → 解包 .fpk + 跑 install_init + install_callback
2. start       → 以 package 用户身份跑 cmd/main start，等待 PID file 出现
3. probe       → 按 health.json 做 HTTP / TCP 探活
4. logs        → cat $LOG_FILE（诊断用，不影响通过/失败）
5. stop        → 跑 cmd/main stop，等待 PID file 消失
6. uninstall   → 跑 uninstall_init + uninstall_callback（wizard_delete_data=true）
7. assert-clean→ 断言无 PID、`service_port` 端口无监听、TRIM_PKGVAR/PKGHOME/INST_ETC 全空
```

健康探活由 `apps/<slug>/fnos/health.json` 控制：

```json
{
    "type": "http",
    "path": "/",
    "expect_status": [200, 301, 302, 401, 403],
    "startup_timeout_seconds": 60,
    "post_install_warmup_seconds": 0,
    "skip_arch": [],
    "note": ""
}
```

- `type=http`：跑 HTTP 探活
- `type=tcp`：只测端口可连
- `type=skip`：跳过 start/probe/stop（驱动 / 数据型包）

完整 schema 见 [`HEALTH_SCHEMA.md`](HEALTH_SCHEMA.md)。

## L3 升级

```bash
bash scripts/test/run-fpk-tests.sh \
    --upgrade-from dist/<slug>_<old-ver>_x86.fpk \
    dist/<slug>_<new-ver>_x86.fpk
```

容器内执行序列：

```
1. install OLD.fpk
2. start                # 旧版本能正常启动
3. probe                # 旧版本能正常对外服务
4. stop
5. upgrade NEW.fpk:
     a) 在 TRIM_PKGVAR 写入 marker 文件
     b) 跑 upgrade_init  → stop_daemon + service_preupgrade + service_save
     c) overlay 新 .fpk 内容（manifest / cmd / app.tgz）
     d) 跑 upgrade_callback → fix_data_ownership + service_restore + service_postupgrade
     e) 断言 marker 仍在 + manifest.version 已切到新版本
6. start                # 新版本能正常启动
7. probe                # 新版本能正常对外服务
8. stop
9. uninstall
10. assert-clean
```

通过条件：每一步退出码 0。如果第 5e 的 marker 丢失，runner 直接 die —— 这通常表示 `service_save` 没保住数据，或 `service_postupgrade` 把数据目录当成临时文件清掉了。

### 升级测试要捕获的坑

- 升级时数据丢失：`upgrade_callback` 里误清 `TRIM_PKGVAR`
- 配置回写错版本：`service_save` / `service_restore` 用了硬编码 schema
- 升级后 daemon 起不来：新二进制依赖了新配置字段，但 `service_postupgrade` 没迁移
- 升级后端口冲突：旧 daemon 没真正退出（`service_preupgrade` 不彻底）
- `app.tgz` overlay 残留旧文件：因为是 tar overlay 而不是清空后解包，旧文件可能污染新版本（这是 fnOS 真实行为，发现就要在 `service_postupgrade` 里手动清理）

## CI 测试覆盖

- `test-static.yml` — 所有 PR 自动跑 L1
- `test-fpk.yml` — 只对 `WHITELIST` 中的应用跑 L2 + L3（**不含升级**）

升级测试目前**只在本地手动跑**。新应用合入后，等版本第二次升级时，先本地跑一遍 L3 升级再发布。

## 排查

| 现象 | 看这里 |
|------|--------|
| `start` 超时 | runner 输出里 `probe diagnostic` 段（listener 列表、PID 状态、最近 15 行 daemon 日志） |
| `probe` 失败但 `start` 成功 | `health.json` 里 `path` / `expect_status` / `startup_timeout_seconds` 配错；如果是 SPA，可能要等更久（调大 `startup_timeout_seconds`） |
| `assert-clean` 失败 | `cmd/service-setup` 的 `service_preuninst` / `service_poststop` 没清干净；`PID_FILE` 残留；或者 daemon fork 出了 runner 不感知的子进程 |
| `upgrade` 报 marker 丢失 | `service_save` / `service_restore` 没正确处理；`upgrade_callback` 误清了 `TRIM_PKGVAR` |
| `upgrade` 报 version 不一致 | 新 `.fpk` 的 `manifest.version` 没更新，build.sh 没正确写入 |

## 引用

- runner 源码：[`scripts/test/fpk-runner/entrypoint.sh`](../../scripts/test/fpk-runner/entrypoint.sh)
- 共享生命周期框架：[`shared/cmd/common`](../../shared/cmd/common)
- 健康探活 schema：[`HEALTH_SCHEMA.md`](HEALTH_SCHEMA.md)
- 完整应用流程：[`docs/adding-new-apps.md`](../adding-new-apps.md)
