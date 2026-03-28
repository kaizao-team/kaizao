#!/bin/bash
# 在 SSH 目标机上查询 projects.category 分布（需已配置 ssh kaizao）
set -euo pipefail
REMOTE="${REMOTE_HOST:-kaizao}"
PW="${PROD_MYSQL_PASSWORD:-kaizao_prod_2026}"
ssh "${REMOTE}" "docker exec kaizao-mysql mysql -ukaizao -p${PW} -N kaizao -e 'SELECT category, COUNT(*) FROM projects GROUP BY category ORDER BY category'"
