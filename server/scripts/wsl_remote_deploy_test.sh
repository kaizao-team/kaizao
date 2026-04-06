#!/bin/bash
# WSL：构建镜像、deploy.sh push 到 SSH 主机，并在远端执行 API 集成测试。
# 测试在远端跑以便 docker exec 命中 kaizao-mysql / kaizao-redis（与 prod compose 一致）。
#
# 用法（在仓库 kaizao/server 下）:
#   bash scripts/wsl_remote_deploy_test.sh
#
# 环境变量:
#   REMOTE_HOST            SSH 别名或 user@host，默认 kaizao
#   PROD_HTTP_PORT         与 docker-compose.prod.yml 中映射一致，默认 39527
#   USE_DOCKERFILE_BUILDKIT=1  传给 deploy.sh push：用 Dockerfile.buildkit 加快本地 docker build（需 buildx）
#   RUN_FULL_SUITE=1       同时开启 --full-onboarding 与 --test-new-apis（全量）
#   RUN_FULL_ONBOARDING=1  完整入驻链路（兑换邀请码等）
#   RUN_TEST_NEW_APIS=1    材料审核 + MinIO 上传（prod compose 已含 MinIO 时可开）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
API_ROOT="$(cd "$ROOT/../.." && pwd)/api"
TEST_SRC="${API_ROOT}/test_api_v2.py"
if [ ! -f "$TEST_SRC" ]; then
  echo "FATAL: 找不到测试脚本: $TEST_SRC"
  exit 1
fi

REMOTE_HOST="${REMOTE_HOST:-kaizao}"
PROD_HTTP_PORT="${PROD_HTTP_PORT:-39527}"
export REMOTE_HOST PROD_HTTP_PORT PROD_MYSQL_PASSWORD

echo "=== deploy.sh push -> ${REMOTE_HOST} (port ${PROD_HTTP_PORT}) ==="
bash deploy.sh push

echo "=== 上传 test_api_v2.py ==="
scp "$TEST_SRC" "${REMOTE_HOST}:~/kaizao-server/test_api_v2.py"

if [ "${RUN_FULL_SUITE:-0}" = "1" ]; then
  RUN_FULL_ONBOARDING=1
  RUN_TEST_NEW_APIS=1
fi
EXTRA_PY_ARGS=""
[ "${RUN_FULL_ONBOARDING:-0}" = "1" ] && EXTRA_PY_ARGS+=" --full-onboarding"
[ "${RUN_TEST_NEW_APIS:-0}" = "1" ] && EXTRA_PY_ARGS+=" --test-new-apis"

echo "=== 远程 API 测试 http://127.0.0.1:${PROD_HTTP_PORT} ==="
# shellcheck disable=SC2029
# EXTRA_PY_ARGS 前须有空格，避免与 mysql-password 粘连
ssh "${REMOTE_HOST}" "cd ~/kaizao-server && python3 test_api_v2.py --base http://127.0.0.1:${PROD_HTTP_PORT} --redis-password redis_prod_2026 --mysql-password kaizao_prod_2026${EXTRA_PY_ARGS:+ }${EXTRA_PY_ARGS}"

echo "=== 远程部署与测试完成 ==="
