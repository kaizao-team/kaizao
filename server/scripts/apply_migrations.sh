#!/usr/bin/env bash
# ============================================================
# 统一执行 MySQL 迁移（强制客户端 utf8mb4，避免中文 COMMENT/数据乱码）
#
# 用法（在 server 目录或任意目录指定 MIGRATIONS_DIR）:
#   bash scripts/apply_migrations.sh
#   MYSQL_PASSWORD=kaizao_prod_2026 bash scripts/apply_migrations.sh
#
# 选项:
#   --full     先执行 001_init_schema（仅空库/初始化；已有表会失败）
#   --strict   任一条 SQL 失败则退出（默认 002–010 为 best-effort，单行失败忽略）
#
# 环境变量:
#   MYSQL_CONTAINER   默认 kaizao-mysql
#   MYSQL_USER          默认 kaizao
#   MYSQL_PASSWORD      默认 kaizao123（生产务必覆盖）
#   MYSQL_DATABASE      默认 kaizao
#   MIGRATIONS_DIR      默认 <本脚本>/../migrations
#   WAIT_MYSQL_SEC      默认 90，等待 mysqld 就绪的最大秒数；设为 0 不等待
#   APPLY_STRICT=1      等同 --strict
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-$SERVER_ROOT/migrations}"

MYSQL_CONTAINER="${MYSQL_CONTAINER:-kaizao-mysql}"
MYSQL_USER="${MYSQL_USER:-kaizao}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-kaizao123}"
MYSQL_DATABASE="${MYSQL_DATABASE:-kaizao}"
WAIT_MYSQL_SEC="${WAIT_MYSQL_SEC:-90}"

FULL=0
STRICT="${APPLY_STRICT:-0}"
for arg in "$@"; do
  case "$arg" in
    --full)   FULL=1 ;;
    --strict) STRICT=1 ;;
    --help|-h)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    *)
      echo "未知参数: $arg（使用 --help）" >&2
      exit 1
      ;;
  esac
done

INCREMENTAL_FILES=(
  002_invite_onboarding.up.sql
  003_team_invite_onboarding.up.sql
  004_team_static_assets.up.sql
  005_project_category_normalize.up.sql
  006_user_contact_phone.up.sql
  007_table_column_comments.up.sql
  008_users_username.up.sql
  009_favorites.up.sql
  010_project_files.up.sql
  011_teams_ai_fields.up.sql
)

mysql_exec() {
  docker exec -i "$MYSQL_CONTAINER" \
    mysql --default-character-set=utf8mb4 \
    -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
}

wait_mysql() {
  local max="${WAIT_MYSQL_SEC:-0}"
  [ "$max" -gt 0 ] || return 0
  local deadline=$((SECONDS + max))
  echo "=== 等待 MySQL 就绪（最多 ${max}s）: ${MYSQL_CONTAINER} ==="
  while [ "$SECONDS" -lt "$deadline" ]; do
    if docker exec "$MYSQL_CONTAINER" mysqladmin ping -h localhost -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
      echo "=== MySQL 已就绪 ==="
      return 0
    fi
    sleep 2
  done
  echo "FATAL: MySQL 在 ${max}s 内未就绪" >&2
  return 1
}

apply_file() {
  local path="$1"
  local best_effort="$2"
  local name
  name="$(basename "$path")"
  if [ ! -f "$path" ]; then
    echo "SKIP 缺失文件: $path" >&2
    return 0
  fi
  echo "==> $name"
  if [ "$best_effort" = 1 ] && [ "$STRICT" != 1 ]; then
    mysql_exec <"$path" 2>/dev/null || true
  else
    mysql_exec <"$path"
  fi
}

wait_mysql

if [ "$FULL" = 1 ]; then
  echo "=== --full: 执行 001（需空库，否则可能报错）==="
  apply_file "$MIGRATIONS_DIR/001_init_schema.up.sql" 0
fi

echo "=== 执行增量迁移 002–011（utf8mb4 客户端）==="
for f in "${INCREMENTAL_FILES[@]}"; do
  apply_file "$MIGRATIONS_DIR/$f" 1
done

echo "=== 迁移脚本执行结束 ==="
