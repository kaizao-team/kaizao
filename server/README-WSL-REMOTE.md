# WSL 部署到远程 kaizao

在 **WSL2**（Ubuntu 等）中操作，依赖：**本机 Docker**、**SSH 能登录远端**。

## 1. SSH

在 WSL `~/.ssh/config` 中配置主机别名（名称需与脚本默认一致，或见下文环境变量）：

```sshconfig
Host kaizao
    HostName 你的服务器IP或域名
    User 你的用户名
    IdentityFile ~/.ssh/id_ed25519
```

测试：`ssh kaizao 'echo ok && docker version'`

远端需已安装 **Docker** 与 **Docker Compose v2**（`docker compose`）。

## 2. 仅部署（推送镜像并启动）

在仓库 **`kaizao/server`** 目录：

```bash
cd /path/to/kaizao/kaizao/server
bash deploy.sh push
```

流程概要：本地 `docker build` → 打包 `kaizao-server.tar.gz` → `scp` 到 `~/` → 远端 `docker load` → `~/kaizao-server` 下 `docker compose -f docker-compose.prod.yml up -d` → 执行增量迁移 → 本机 `39527` 健康检查。

### 环境变量（可选）

| 变量 | 说明 | 默认 |
|------|------|------|
| `REMOTE_HOST` | `ssh` 目标（别名或 `user@host`） | `kaizao` |
| `PROD_HTTP_PORT` | 与 `docker-compose.prod.yml` 中 server 端口映射一致 | `39527` |
| `PROD_MYSQL_PASSWORD` | 与 prod compose 中 MySQL 密码一致 | `kaizao_prod_2026` |
| `SCP_OPTS` | 大文件传输保活等 | 见 `deploy.sh` |

示例（主机别名不是 `kaizao` 时）：

```bash
REMOTE_HOST=my-cloud bash deploy.sh push
```

## 3. 部署 + 在远端跑 API 集成测试

需本机仓库中存在 **`../../api/test_api_v2.py`**（相对 `server` 的上级再上级为仓库根，其下 `api/`）。

```bash
cd /path/to/kaizao/kaizao/server
bash scripts/wsl_remote_deploy_test.sh
```

会先执行 `deploy.sh push`，再把 `test_api_v2.py` 传到远端 `~/kaizao-server/`，并在**服务器上**执行：

`python3 test_api_v2.py --base http://127.0.0.1:39527 ...`

（便于 `docker exec` 命中 `kaizao-mysql` / `kaizao-redis`，与线上 compose 一致。）

可选：

- `RUN_FULL_SUITE=1`：同时 `--full-onboarding` 与 `--test-new-apis`
- `RUN_FULL_ONBOARDING=1` / `RUN_TEST_NEW_APIS=1`：见脚本注释

## 4. 传输中断

若 `scp` 镜像包断连，可重跑同一条 `bash deploy.sh push`；若 `~/kaizao-server.tar.gz` 已在远端，可 SSH 登录后按 `deploy.sh` 文件头注释手动 `docker load` 与 `compose up`。

## 5. 仅在远端管理（SSH 登录后）

在服务器 `~/kaizao-server` 若已同步过 `deploy.sh`：

```bash
bash deploy.sh status
bash deploy.sh logs
bash deploy.sh restart
```

仅同步 compose/迁移/脚本、不重建镜像：`bash deploy.sh sync`（在**本机 WSL** `server` 目录执行）。
