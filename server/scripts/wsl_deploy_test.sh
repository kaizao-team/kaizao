#!/bin/bash
# WSL + Docker 下一键：Go 单测（可选）→ 构建并启动栈 → 健康检查 → API 集成测试（test_api_v2.py）
# 用法：在仓库 kaizao/server 目录执行  bash scripts/wsl_deploy_test.sh
# 若本机 8080 已被占用：SERVER_HOST_PORT=18080 bash scripts/wsl_deploy_test.sh
# 跳过 Go 单测：RUN_GO_TEST=0 bash scripts/wsl_deploy_test.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export SERVER_HOST_PORT="${SERVER_HOST_PORT:-8080}"
BASE="http://127.0.0.1:${SERVER_HOST_PORT}"

# 在 Docker 内 golang 镜像跑 go test（脚本内单引号包裹，避免从 Windows 直接传参时 ./... 被拆坏）
if [ "${RUN_GO_TEST:-1}" = "1" ]; then
  echo "=== go test (docker: golang:1.22-bookworm, see scripts/docker_go_test.sh) ==="
  bash "$ROOT/scripts/docker_go_test.sh"
fi

echo "=== compose build & up (API -> ${BASE}) ==="
docker compose build server
docker compose up -d

# 旧数据卷若早于 002/003/004 迁移，需补跑 DDL（重复执行可能报 Duplicate column，可忽略）；005 为分类数据清洗可重复执行
if [ "${APPLY_SQL_MIGRATIONS:-1}" = "1" ]; then
  MYSQL_CONTAINER=kaizao-mysql MYSQL_USER=kaizao MYSQL_PASSWORD=kaizao123 MYSQL_DATABASE=kaizao \
    MIGRATIONS_DIR="$ROOT/migrations" WAIT_MYSQL_SEC=90 \
    bash "$ROOT/scripts/apply_migrations.sh"
fi

echo "=== wait health ==="
for i in $(seq 1 60); do
  if curl -sf "${BASE}/health" >/dev/null; then
    echo "OK health"
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "FATAL: server not healthy on ${BASE}"
    docker compose logs --tail=80 server
    exit 1
  fi
  sleep 2
done

echo "=== API tests (可选: RUN_FULL_ONBOARDING=1 / RUN_TEST_NEW_APIS=1) ==="
PY_ARGS=(--base "${BASE}")
[ "${RUN_FULL_ONBOARDING:-0}" = "1" ] && PY_ARGS+=(--full-onboarding)
[ "${RUN_TEST_NEW_APIS:-0}" = "1" ] && PY_ARGS+=(--test-new-apis)
python3 ../../api/test_api_v2.py "${PY_ARGS[@]}"

echo "=== done ==="
