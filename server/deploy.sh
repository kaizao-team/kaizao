#!/bin/bash
set -e

# ============================================================
# Kaizao Server 部署脚本
#
# 本地部署（在 WSL 中执行，构建镜像并推送到远程服务器）:
#   bash deploy.sh push
#
# 远程管理（在远程服务器上执行）:
#   bash deploy.sh up       # 启动服务
#   bash deploy.sh down     # 停止服务
#   bash deploy.sh logs     # 查看日志
#   bash deploy.sh status   # 查看状态
#   bash deploy.sh restart  # 重启 server
# ============================================================

REMOTE_HOST="kaizao"
REMOTE_DIR="\$HOME/kaizao-server"
IMAGE_NAME="kaizao-server"
IMAGE_TAG="latest"
COMPOSE_FILE="docker-compose.prod.yml"

do_push() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd "$SCRIPT_DIR"

    echo "==> [1/4] 构建镜像..."
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

    echo "==> [2/4] 导出镜像..."
    docker save ${IMAGE_NAME}:${IMAGE_TAG} | gzip > /tmp/${IMAGE_NAME}.tar.gz
    echo "    大小: $(du -h /tmp/${IMAGE_NAME}.tar.gz | cut -f1)"

    echo "==> [3/4] 传输到远程服务器..."
    scp /tmp/${IMAGE_NAME}.tar.gz ${REMOTE_HOST}:~/${IMAGE_NAME}.tar.gz

    echo "==> [4/4] 远程加载镜像并启动..."
    ssh ${REMOTE_HOST} bash -s <<'REMOTE_SCRIPT'
        set -e
        echo "    加载镜像..."
        gunzip -c ~/${IMAGE_NAME}.tar.gz | docker load
        rm ~/${IMAGE_NAME}.tar.gz

        cd ~/kaizao-server
        echo "    启动服务..."
        docker compose -f docker-compose.prod.yml up -d
        echo "    等待健康检查..."
        for i in $(seq 1 30); do
            if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
                echo "    服务已启动!"
                docker compose -f docker-compose.prod.yml ps
                IP=$(hostname -I | awk '{print $1}')
                echo ""
                echo "    访问地址: http://${IP}:8080"
                exit 0
            fi
            sleep 5
            echo "    等待中... ($i/30)"
        done
        echo "    WARNING: 健康检查超时"
        docker compose -f docker-compose.prod.yml logs --tail 20 server
        exit 1
REMOTE_SCRIPT

    rm -f /tmp/${IMAGE_NAME}.tar.gz
    echo "==> 部署完成!"
}

do_sync() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd "$SCRIPT_DIR"
    echo "==> 同步配置文件到远程..."
    ssh ${REMOTE_HOST} "mkdir -p ~/kaizao-server/migrations ~/kaizao-server/configs"
    scp docker-compose.prod.yml ${REMOTE_HOST}:~/kaizao-server/docker-compose.prod.yml
    scp deploy.sh ${REMOTE_HOST}:~/kaizao-server/deploy.sh
    scp migrations/001_init_schema.up.sql ${REMOTE_HOST}:~/kaizao-server/migrations/001_init_schema.up.sql
    echo "==> 同步完成"
}

do_up() {
    cd ~/kaizao-server
    docker compose -f "$COMPOSE_FILE" up -d
    sleep 3
    docker compose -f "$COMPOSE_FILE" ps
}

do_down() {
    cd ~/kaizao-server
    docker compose -f "$COMPOSE_FILE" down
    echo "==> 服务已停止"
}

do_logs() {
    cd ~/kaizao-server
    docker compose -f "$COMPOSE_FILE" logs -f --tail 100 "${2:-server}"
}

do_status() {
    cd ~/kaizao-server
    docker compose -f "$COMPOSE_FILE" ps
}

case "${1:-up}" in
    push)   do_push ;;
    sync)   do_sync ;;
    up)     do_up ;;
    down)   do_down ;;
    logs)   do_logs "$@" ;;
    status) do_status ;;
    restart)
        cd ~/kaizao-server
        docker compose -f "$COMPOSE_FILE" restart server
        ;;
    *)
        echo "Usage: bash deploy.sh {push|sync|up|down|logs|status|restart}"
        exit 1
        ;;
esac
