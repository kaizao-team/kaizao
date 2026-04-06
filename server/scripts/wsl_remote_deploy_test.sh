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
#   SKIP_DEPLOY=1          跳过 deploy.sh push，仅上传 tests/ 并在远端跑集成测试（部署已成功时重试）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
API_ROOT="$(cd "$ROOT/.." && pwd)/api"
TESTS_DIR="${API_ROOT}/tests"
if [ ! -f "$TESTS_DIR/runner.py" ]; then
  echo "FATAL: 找不到模块化测试入口: $TESTS_DIR/runner.py"
  exit 1
fi

REMOTE_HOST="${REMOTE_HOST:-kaizao}"
PROD_HTTP_PORT="${PROD_HTTP_PORT:-39527}"
export REMOTE_HOST PROD_HTTP_PORT PROD_MYSQL_PASSWORD
# 保活 + 单次 tar 管道上传，避免 scp 多文件时远端主动断连
SSH_OPTS="${SSH_OPTS:--o ServerAliveInterval=30 -o ServerAliveCountMax=5}"

if [ "${SKIP_DEPLOY:-0}" != "1" ]; then
  echo "=== deploy.sh push -> ${REMOTE_HOST} (port ${PROD_HTTP_PORT}) ==="
  bash deploy.sh push
else
  echo "=== SKIP_DEPLOY=1：跳过镜像部署 ==="
fi

echo "=== 上传 tests/ 模块（单条 tar|ssh，避免连续两次 SSH 被断开）==="
# shellcheck disable=SC2086
tar czf - -C "$TESTS_DIR" --exclude='__pycache__' --exclude='*.pyc' . \
  | ssh $SSH_OPTS "${REMOTE_HOST}" "mkdir -p ~/kaizao-server/tests && tar xzf - -C ~/kaizao-server/tests"

if [ "${RUN_FULL_SUITE:-0}" = "1" ]; then
  RUN_FULL_ONBOARDING=1
  RUN_TEST_NEW_APIS=1
fi
EXTRA_PY_ARGS=""
[ "${RUN_FULL_ONBOARDING:-0}" = "1" ] && EXTRA_PY_ARGS+=" --full-onboarding"
[ "${RUN_TEST_NEW_APIS:-0}" = "1" ] && EXTRA_PY_ARGS+=" --test-new-apis"

echo "=== 远程 API 测试 http://127.0.0.1:${PROD_HTTP_PORT} ==="
# shellcheck disable=SC2029,SC2086
ssh $SSH_OPTS "${REMOTE_HOST}" "cd ~/kaizao-server && python3 -m tests --base http://127.0.0.1:${PROD_HTTP_PORT} --redis-password redis_prod_2026 --mysql-password kaizao_prod_2026${EXTRA_PY_ARGS:+ }${EXTRA_PY_ARGS}"

echo "=== 远程部署与测试完成 ==="
