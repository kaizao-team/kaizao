#!/bin/bash
# WSL + Docker 下一键：Go 单测（可选，WSL 本机 go）→ 构建并启动栈 → 健康检查 → API 集成测试（test_api_v2.py）
# 用法：在仓库 kaizao/server 目录执行  bash scripts/wsl_deploy_test.sh
#
# 编排：**默认优先使用 WSL 专用** docker-compose.wsl.yml（独立 project name、完整 migrations 001–013）；
# 若需沿用旧栈：USE_WSL_COMPOSE=0 bash scripts/wsl_deploy_test.sh
#
# 可选：在 server 目录放置 .env.wsl（可由 .env.wsl.example 复制），脚本会自动附加 --env-file .env.wsl
#
# 宿主机 API 端口与 compose 中 server 映射一致（默认 39527:8080）：
#   SERVER_HOST_PORT=39527 bash scripts/wsl_deploy_test.sh
# 跳过 Go 单测：RUN_GO_TEST=0 bash scripts/wsl_deploy_test.sh
#
# Go 单测：在 WSL 内使用 PATH 中的 `go`（与 docker_go_test.sh 无关；模块/构建缓存为 Go 默认目录）。
# 镜像构建：默认 Dockerfile；若已安装 docker buildx，可设 USE_DOCKERFILE_BUILDKIT=1 使用
#   Dockerfile.buildkit（BuildKit 缓存卷，改 go.mod 后多为增量下载）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export SERVER_HOST_PORT="${SERVER_HOST_PORT:-39527}"
BASE="http://127.0.0.1:${SERVER_HOST_PORT}"

# 优先 WSL 专用编排；USE_WSL_COMPOSE=0 时回退 docker-compose.yml（容器名 kaizao-mysql 等）
USE_WSL_COMPOSE="${USE_WSL_COMPOSE:-1}"

COMPOSE_ARGS=()
if [ "${USE_WSL_COMPOSE}" = "1" ]; then
  if [ -f "$ROOT/.env.wsl" ]; then
    COMPOSE_ARGS+=(--env-file "$ROOT/.env.wsl")
    echo "INFO: using docker-compose.wsl.yml + .env.wsl"
  else
    echo "INFO: using docker-compose.wsl.yml (no .env.wsl; cp .env.wsl.example .env.wsl to customize)"
  fi
  COMPOSE_ARGS+=(-f docker-compose.wsl.yml)
  export MYSQL_CONTAINER="${MYSQL_CONTAINER:-kaizao-wsl-mysql}"
  export REDIS_CONTAINER="${REDIS_CONTAINER:-kaizao-wsl-redis}"
  export SERVER_CONTAINER="${SERVER_CONTAINER:-kaizao-wsl-server}"
else
  COMPOSE_ARGS+=(-f docker-compose.yml)
  export MYSQL_CONTAINER="${MYSQL_CONTAINER:-kaizao-mysql}"
  export REDIS_CONTAINER="${REDIS_CONTAINER:-kaizao-redis}"
  export SERVER_CONTAINER="${SERVER_CONTAINER:-kaizao-server}"
  echo "INFO: using docker-compose.yml (legacy; set USE_WSL_COMPOSE=1 for WSL stack)"
fi

if [ "${USE_DOCKERFILE_BUILDKIT:-0}" = "1" ]; then
  export DOCKER_BUILDKIT=1
  export COMPOSE_DOCKER_CLI_BUILD=1
  COMPOSE_ARGS+=(-f docker-compose.buildkit.yml)
  echo "INFO: using Dockerfile.buildkit (BuildKit go mod/build cache)"
fi

compose() {
  docker compose "${COMPOSE_ARGS[@]}" "$@"
}

if [ "${RUN_GO_TEST:-1}" = "1" ]; then
  echo "=== go test (WSL local) ==="
  if ! command -v go >/dev/null 2>&1; then
    echo "FATAL: go not found in PATH. Install Go in WSL or set RUN_GO_TEST=0 to skip."
    exit 1
  fi
  go version
  go test -count=1 ./...
fi

echo "=== compose build & up (API -> ${BASE}) ==="
compose build server
compose up -d

# 首次空卷时 MySQL 会跑 entrypoint 初始化 + initdb.d（数分钟）；compose 的 healthcheck 可能在「临时实例」阶段即通过，
# 导致 server 早于「正式 mysqld 监听 3306」启动。此处等待宿主机 3306 真正可连后再迁移/依赖 DB 的容器才能稳定。
echo "=== wait MySQL TCP on host :3306 (first init can take several minutes) ==="
MYSQL_TCP_DEADLINE=$((SECONDS + 420))
while [ "$SECONDS" -lt "$MYSQL_TCP_DEADLINE" ]; do
  if (echo >/dev/tcp/127.0.0.1/3306) 2>/dev/null; then
    echo "OK MySQL accepting connections on 127.0.0.1:3306"
    break
  fi
  sleep 3
done
if [ "$SECONDS" -ge "$MYSQL_TCP_DEADLINE" ]; then
  echo "FATAL: MySQL not listening on 127.0.0.1:3306 after 420s" >&2
  docker logs "${MYSQL_CONTAINER}" --tail=80
  exit 1
fi
sleep 2

# 旧数据卷若早于 002/003/004 迁移，需补跑 DDL（重复执行可能报 Duplicate column，可忽略）；005 为分类数据清洗可重复执行
if [ "${APPLY_SQL_MIGRATIONS:-1}" = "1" ]; then
  # 须与 compose 中 MYSQL_PASSWORD / VB_DATABASE_PASSWORD 一致（默认 kaizao_prod_2026；若用 .env.wsl 以其中为准）
  MYSQL_USER=kaizao MYSQL_PASSWORD="${MYSQL_PASSWORD:-kaizao_prod_2026}" MYSQL_DATABASE=kaizao \
    MIGRATIONS_DIR="$ROOT/migrations" WAIT_MYSQL_SEC=90 \
    bash "$ROOT/scripts/apply_migrations.sh"
fi

echo "=== (re)start server now that MySQL is ready ==="
compose up -d server

echo "=== wait health ==="
for i in $(seq 1 60); do
  if curl -sf "${BASE}/health" >/dev/null; then
    echo "OK health"
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "FATAL: server not healthy on ${BASE}"
    compose logs --tail=80 server
    exit 1
  fi
  sleep 2
done

echo "=== API tests (含 §1.4b api-registry 密码链路、§8.3d 里程碑交付 deliver；可选: RUN_FULL_ONBOARDING=1 / RUN_TEST_NEW_APIS=1) ==="
python3 -m pip install -q cryptography 2>/dev/null || true
PY_ARGS=(
  --base "${BASE}"
  --mysql-container "${MYSQL_CONTAINER}"
  --mysql-password "${MYSQL_PASSWORD:-kaizao_prod_2026}"
  --redis-container "${REDIS_CONTAINER}"
  --server-container "${SERVER_CONTAINER}"
)
[ "${RUN_FULL_ONBOARDING:-0}" = "1" ] && PY_ARGS+=(--full-onboarding)
[ "${RUN_TEST_NEW_APIS:-0}" = "1" ] && PY_ARGS+=(--test-new-apis)
# 优先使用拆分后的模块化入口；回退到原始单文件
API_DIR="$(cd "$ROOT/.." && pwd)/api"
if [ -f "$API_DIR/tests/runner.py" ]; then
  (cd "$API_DIR" && python3 -m tests "${PY_ARGS[@]}")
else
  python3 "$API_DIR/test_api_v2.py" "${PY_ARGS[@]}"
fi

echo "=== done ==="
