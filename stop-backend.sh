#!/bin/bash

# 开造 VCC - 后端一键关闭脚本

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/deploy/docker-compose.dev.yml"
PID_FILE="$ROOT_DIR/.server.pid"

echo "========================================="
echo "  开造 VCC - 停止后端服务"
echo "========================================="

# 1. 停止 Go 后端
echo ""
echo "[1/2] 停止 Go 后端服务..."
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    echo "      ✓ Go 服务已停止 (PID: $PID)"
  else
    echo "      Go 服务未在运行"
  fi
  rm -f "$PID_FILE"
else
  # 兜底：按进程名查找
  PIDS=$(pgrep -f "go run ./cmd/server" 2>/dev/null || true)
  if [ -n "$PIDS" ]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
    echo "      ✓ Go 服务已停止"
  else
    echo "      Go 服务未在运行"
  fi
fi

# 2. 停止 Docker 基础设施
echo ""
echo "[2/2] 停止数据库和缓存..."
docker compose -f "$COMPOSE_FILE" down
echo "      ✓ PostgreSQL 和 Redis 已停止"

echo ""
echo "========================================="
echo "  所有服务已停止"
echo "========================================="
