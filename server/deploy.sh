#!/bin/bash
set -e

# ============================================================
# Kaizao Server 部署脚本
#
# 本地部署（在 WSL 中执行，构建镜像并推送到远程服务器）:
#   bash deploy.sh push
# 可选环境变量: REMOTE_HOST（默认 kaizao）、PROD_HTTP_PORT（默认 39527，须与 docker-compose.prod.yml 一致）
#
# 远程管理（在远程服务器上执行）:
#   bash deploy.sh up       # 启动服务
#   bash deploy.sh down     # 停止服务
#   bash deploy.sh logs     # 查看日志
#   bash deploy.sh status   # 查看状态
#   bash deploy.sh restart  # 重启 server
# ============================================================

REMOTE_HOST="${REMOTE_HOST:-kaizao}"
REMOTE_DIR="\$HOME/kaizao-server"
IMAGE_NAME="kaizao-server"
IMAGE_TAG="latest"
COMPOSE_FILE="docker-compose.prod.yml"
# 宿主机映射端口（见 docker-compose.prod.yml server ports）
PROD_HTTP_PORT="${PROD_HTTP_PORT:-39527}"
PROD_MYSQL_PASSWORD="${PROD_MYSQL_PASSWORD:-kaizao_prod_2026}"

do_push() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd "$SCRIPT_DIR"

    echo "==> [1/5] 构建镜像..."
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

    echo "==> [2/5] 导出镜像..."
    docker save ${IMAGE_NAME}:${IMAGE_TAG} | gzip > /tmp/${IMAGE_NAME}.tar.gz
    echo "    大小: $(du -h /tmp/${IMAGE_NAME}.tar.gz | cut -f1)"

    echo "==> [3/5] 同步 compose / migrations 到远程..."
    ssh "${REMOTE_HOST}" "mkdir -p ~/kaizao-server/migrations"
    scp docker-compose.prod.yml "${REMOTE_HOST}:~/kaizao-server/docker-compose.prod.yml"
    for f in migrations/*.up.sql; do
        [ -f "$f" ] || continue
        scp "$f" "${REMOTE_HOST}:~/kaizao-server/migrations/$(basename "$f")"
    done

    echo "==> [4/5] 传输镜像包到远程..."
    scp /tmp/${IMAGE_NAME}.tar.gz "${REMOTE_HOST}:~/${IMAGE_NAME}.tar.gz"

    echo "==> [5/5] 远程加载镜像、启动、补迁移、健康检查..."
    # 通过 ssh 传入变量；heredoc 单引号避免本地展开，远程用已 export 的变量
    ssh "${REMOTE_HOST}" \
        "export IMAGE_NAME=${IMAGE_NAME} PROD_HTTP_PORT=${PROD_HTTP_PORT} MYSQL_PWD=${PROD_MYSQL_PASSWORD}; bash -s" <<'REMOTE_SCRIPT'
        set -e
        echo "    加载镜像..."
        gunzip -c ~/"${IMAGE_NAME}".tar.gz | docker load
        rm -f ~/"${IMAGE_NAME}".tar.gz

        cd ~/kaizao-server
        echo "    启动服务..."
        docker compose -f docker-compose.prod.yml up -d

        echo "    等待 MySQL 就绪后补跑 002–006（旧卷可忽略 Duplicate）..."
        for i in $(seq 1 45); do
            if docker exec kaizao-mysql mysqladmin ping -h localhost -ukaizao -p"${MYSQL_PWD}" --silent 2>/dev/null; then
                break
            fi
            sleep 2
        done
        for f in 002_invite_onboarding.up.sql 003_team_invite_onboarding.up.sql 004_team_static_assets.up.sql 005_project_category_normalize.up.sql 006_user_contact_phone.up.sql; do
            mf="$HOME/kaizao-server/migrations/$f"
            if [ -f "$mf" ]; then
                docker exec -i kaizao-mysql mysql -ukaizao -p"${MYSQL_PWD}" kaizao <"$mf" 2>/dev/null || true
            fi
        done

        echo "    等待健康检查 (宿主机端口 ${PROD_HTTP_PORT})..."
        for i in $(seq 1 30); do
            if curl -sf "http://127.0.0.1:${PROD_HTTP_PORT}/health" >/dev/null 2>&1; then
                echo "    服务已启动!"
                docker compose -f docker-compose.prod.yml ps
                IP=$(hostname -I | awk '{print $1}')
                echo ""
                echo "    访问地址: http://${IP}:${PROD_HTTP_PORT}"
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
    ssh "${REMOTE_HOST}" "mkdir -p ~/kaizao-server/migrations ~/kaizao-server/configs"
    scp docker-compose.prod.yml "${REMOTE_HOST}:~/kaizao-server/docker-compose.prod.yml"
    scp deploy.sh "${REMOTE_HOST}:~/kaizao-server/deploy.sh"
    for f in migrations/*.up.sql; do
        [ -f "$f" ] || continue
        scp "$f" "${REMOTE_HOST}:~/kaizao-server/migrations/$(basename "$f")"
    done
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
