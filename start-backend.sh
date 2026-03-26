#!/bin/bash

# 开造 VCC - 后端一键启动脚本

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$ROOT_DIR/server"
COMPOSE_FILE="$ROOT_DIR/deploy/docker-compose.dev.yml"
LOG_FILE="$ROOT_DIR/server.log"
PID_FILE="$ROOT_DIR/.server.pid"

echo "========================================="
echo "  开造 VCC - 启动后端服务"
echo "========================================="

# 1. 启动基础设施 (PostgreSQL + Redis)
echo ""
echo "[1/2] 启动数据库和缓存..."
docker compose -f "$COMPOSE_FILE" up -d

# 等待 PostgreSQL 健康
echo "      等待 PostgreSQL 就绪..."
for i in $(seq 1 20); do
  if docker exec vcc-postgres pg_isready -U vibebuild -q 2>/dev/null; then
    echo "      ✓ PostgreSQL 已就绪"
    break
  fi
  if [ "$i" -eq 20 ]; then
    echo "      ✗ PostgreSQL 启动超时，请检查 Docker"
    exit 1
  fi
  sleep 1
done

# 等待 Redis 健康
echo "      等待 Redis 就绪..."
for i in $(seq 1 10); do
  if docker exec vcc-redis redis-cli -a redis123 ping 2>/dev/null | grep -q PONG; then
    echo "      ✓ Redis 已就绪"
    break
  fi
  if [ "$i" -eq 10 ]; then
    echo "      ✗ Redis 启动超时，请检查 Docker"
    exit 1
  fi
  sleep 1
done

# 2. 启动 Go 后端
echo ""
echo "[2/2] 启动 Go 后端服务..."

# 检查是否已经在运行
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "      后端服务已在运行 (PID: $OLD_PID)"
    echo "      如需重启请先运行 ./stop-backend.sh"
    exit 0
  fi
fi

cd "$SERVER_DIR"
nohup go run ./cmd/server/main.go > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > "$PID_FILE"

# 等待服务启动
echo "      等待 Go 服务就绪..."
for i in $(seq 1 30); do
  if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "      ✓ Go 后端已就绪 (PID: $SERVER_PID)"
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "      ✗ Go 服务启动失败，查看日志: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
  fi
  if [ "$i" -eq 30 ]; then
    echo "      ✗ Go 服务启动超时，查看日志: $LOG_FILE"
    exit 1
  fi
  sleep 1
done

echo ""
echo "========================================="
echo "  所有服务已启动！"
echo ""
echo "  API 地址:  http://localhost:8080"
echo "  健康检查:  http://localhost:8080/health"
echo "  后端日志:  tail -f $LOG_FILE"
echo "  停止服务:  ./stop-backend.sh"
echo "========================================="
