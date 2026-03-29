#!/usr/bin/env bash
set -euo pipefail
# WSL / Linux：在 server 目录用 Docker 跑测试；可选拉起完整依赖栈做联调
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mode="${1:-test}"

case "$mode" in
  test)
    echo "== go test（golang 容器，挂载当前 server 源码）=="
    docker compose -f docker-compose.test.yml run --rm go-test
    ;;
  up)
    echo "== 构建并启动 mysql + redis + minio + server（端口见 docker-compose.yml）=="
    docker compose up -d --build
    echo "健康检查: curl -sS http://127.0.0.1:8080/health"
    ;;
  down)
    docker compose down
    ;;
  logs)
    docker compose logs -f server
    ;;
  *)
    echo "用法: $0 [test|up|down|logs]"
    echo "  test  默认：仅容器内 go test"
    echo "  up    全栈后台启动"
    echo "  down  停止全栈"
    echo "  logs  跟随 server 日志"
    exit 1
    ;;
esac
