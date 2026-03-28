#!/bin/bash
# WSL 下一键：构建并启动栈，健康检查后跑 API 集成测试
# 用法：在仓库 server 目录执行  bash scripts/wsl_deploy_test.sh
# 若本机 8080 已被占用：SERVER_HOST_PORT=18080 bash scripts/wsl_deploy_test.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export SERVER_HOST_PORT="${SERVER_HOST_PORT:-8080}"
BASE="http://127.0.0.1:${SERVER_HOST_PORT}"

echo "=== compose build & up (API -> ${BASE}) ==="
docker compose build server
docker compose up -d

# 旧数据卷若早于 002/003/004 迁移，需补跑 DDL（重复执行可能报 Duplicate column，可忽略）
if [ "${APPLY_SQL_MIGRATIONS:-1}" = "1" ]; then
  echo "=== wait mysql ==="
  for i in $(seq 1 45); do
    docker exec kaizao-mysql mysqladmin ping -h localhost -ukaizao -pkaizao123 --silent 2>/dev/null && break
    sleep 2
  done
  echo "=== apply migrations 002–004 (best-effort) ==="
  for f in "$ROOT/migrations/002_invite_onboarding.up.sql" "$ROOT/migrations/003_team_invite_onboarding.up.sql" "$ROOT/migrations/004_team_static_assets.up.sql"; do
    [ -f "$f" ] || continue
    docker exec -i kaizao-mysql mysql -ukaizao -pkaizao123 kaizao <"$f" 2>/dev/null || true
  done
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
