#!/bin/bash
set -e

# ============================================================
# Kaizao Server 部署脚本
#
# 本地部署（在 WSL 中执行，构建镜像并推送到远程服务器）:
#   bash deploy.sh push
# 可选环境变量: REMOTE_HOST（默认 kaizao）、PROD_HTTP_PORT（默认 39527，须与 docker-compose.prod.yml 一致）、SCP_OPTS
#
# 生产必备：本地须存在 configs/auth_password_rsa.pem（首次: bash scripts/gen_auth_password_rsa.sh，勿提交 git）
# 可选：deploy/.env.prod 存在时同步为远程 ~/kaizao-server/.env，用于覆盖 VB_JWT_SECRET、VB_OSS_BASE_URL 等（见 deploy/env.prod.example）
# 若 push 在「传输镜像包」阶段断连，可重试同条命令；若包已在远端 ~/kaizao-server.tar.gz，可 SSH 登录后执行:
#   gunzip -c ~/kaizao-server.tar.gz | docker load && rm -f ~/kaizao-server.tar.gz && cd ~/kaizao-server && docker compose -f docker-compose.prod.yml up -d
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
# 大镜像包传输易断连，scp 默认带保活（可用环境变量覆盖）
SCP_OPTS="${SCP_OPTS:--o ServerAliveInterval=10 -o ServerAliveCountMax=60 -o TCPKeepAlive=yes}"
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

    echo "==> [3/5] 同步 compose / migrations / scripts / 生产 RSA 到远程..."
    if [ ! -s "${SCRIPT_DIR}/configs/auth_password_rsa.pem" ]; then
        echo "错误: 缺少非空 ${SCRIPT_DIR}/configs/auth_password_rsa.pem（生产必须挂载，禁止 DEV_AUTO_KEY）"
        echo "请执行: bash scripts/gen_auth_password_rsa.sh  生成后妥善备份，勿提交 git"
        exit 1
    fi
    # 勿用 ssh "... ~/..." ：~ 会在**本地** shell 展开，远程目录可能未创建
    ssh "${REMOTE_HOST}" 'mkdir -p "$HOME/kaizao-server/migrations" "$HOME/kaizao-server/scripts" "$HOME/kaizao-server/configs"'
    # 旧版单文件 bind 若误建为目录，清掉以便 scp 写入 PEM
    ssh "${REMOTE_HOST}" '[ -d "$HOME/kaizao-server/configs/auth_password_rsa.pem" ] && rm -rf "$HOME/kaizao-server/configs/auth_password_rsa.pem" || true'
    scp ${SCP_OPTS} docker-compose.prod.yml "${REMOTE_HOST}:~/kaizao-server/docker-compose.prod.yml"
    scp ${SCP_OPTS} scripts/apply_migrations.sh "${REMOTE_HOST}:~/kaizao-server/scripts/apply_migrations.sh"
    for f in migrations/*.up.sql; do
        [ -f "$f" ] || continue
        scp ${SCP_OPTS} "$f" "${REMOTE_HOST}:~/kaizao-server/migrations/$(basename "$f")"
    done
    scp ${SCP_OPTS} "${SCRIPT_DIR}/configs/config.yaml" "${REMOTE_HOST}:~/kaizao-server/configs/config.yaml"
    scp ${SCP_OPTS} "${SCRIPT_DIR}/configs/auth_password_rsa.pem" "${REMOTE_HOST}:~/kaizao-server/configs/auth_password_rsa.pem"
    scp ${SCP_OPTS} "${SCRIPT_DIR}/deploy/env.prod.example" "${REMOTE_HOST}:~/kaizao-server/env.prod.example"
    if [ -f "${SCRIPT_DIR}/deploy/.env.prod" ]; then
        echo "    同步 deploy/.env.prod -> 远程 .env"
        scp ${SCP_OPTS} "${SCRIPT_DIR}/deploy/.env.prod" "${REMOTE_HOST}:~/kaizao-server/.env"
    fi

    echo "==> [4/5] 传输镜像包到远程..."
    scp ${SCP_OPTS} /tmp/${IMAGE_NAME}.tar.gz "${REMOTE_HOST}:~/${IMAGE_NAME}.tar.gz"

    echo "==> [5/5] 远程加载镜像、启动、补迁移、健康检查..."
    # 通过 ssh 传入变量；heredoc 单引号避免本地展开，远程用已 export 的变量
    ssh "${REMOTE_HOST}" \
        "export IMAGE_NAME=${IMAGE_NAME} PROD_HTTP_PORT=${PROD_HTTP_PORT} MYSQL_PWD=${PROD_MYSQL_PASSWORD}; bash -s" <<'REMOTE_SCRIPT'
        set -e
        echo "    加载镜像..."
        gunzip -c ~/"${IMAGE_NAME}".tar.gz | docker load
        rm -f ~/"${IMAGE_NAME}".tar.gz

        cd ~/kaizao-server
        if [ -d "$HOME/kaizao-server/configs/auth_password_rsa.pem" ]; then
            echo "错误: 远程 configs/auth_password_rsa.pem 为目录（旧版 bind 误建）。请 SSH 执行: rm -rf ~/kaizao-server/configs/auth_password_rsa.pem 后重新 push"
            exit 1
        fi
        test -s "$HOME/kaizao-server/configs/auth_password_rsa.pem" || { echo "错误: 远程缺少非空 configs/auth_password_rsa.pem"; exit 1; }
        echo "    启动服务..."
        docker compose -f docker-compose.prod.yml up -d

        export MYSQL_PASSWORD="${MYSQL_PWD}"
        export MYSQL_CONTAINER=kaizao-mysql MYSQL_USER=kaizao MYSQL_DATABASE=kaizao
        export MIGRATIONS_DIR="$HOME/kaizao-server/migrations" WAIT_MYSQL_SEC=90
        echo "    补跑迁移（utf8mb4，002–007 best-effort）..."
        bash "$HOME/kaizao-server/scripts/apply_migrations.sh"

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
    if [ ! -s "${SCRIPT_DIR}/configs/auth_password_rsa.pem" ]; then
        echo "错误: 缺少非空 configs/auth_password_rsa.pem，请 bash scripts/gen_auth_password_rsa.sh"
        exit 1
    fi
    ssh "${REMOTE_HOST}" 'mkdir -p "$HOME/kaizao-server/migrations" "$HOME/kaizao-server/configs" "$HOME/kaizao-server/scripts"'
    scp ${SCP_OPTS} docker-compose.prod.yml "${REMOTE_HOST}:~/kaizao-server/docker-compose.prod.yml"
    scp ${SCP_OPTS} deploy.sh "${REMOTE_HOST}:~/kaizao-server/deploy.sh"
    scp ${SCP_OPTS} scripts/apply_migrations.sh "${REMOTE_HOST}:~/kaizao-server/scripts/apply_migrations.sh"
    for f in migrations/*.up.sql; do
        [ -f "$f" ] || continue
        scp ${SCP_OPTS} "$f" "${REMOTE_HOST}:~/kaizao-server/migrations/$(basename "$f")"
    done
    scp ${SCP_OPTS} "${SCRIPT_DIR}/configs/config.yaml" "${REMOTE_HOST}:~/kaizao-server/configs/config.yaml"
    scp ${SCP_OPTS} "${SCRIPT_DIR}/configs/auth_password_rsa.pem" "${REMOTE_HOST}:~/kaizao-server/configs/auth_password_rsa.pem"
    scp ${SCP_OPTS} "${SCRIPT_DIR}/deploy/env.prod.example" "${REMOTE_HOST}:~/kaizao-server/env.prod.example"
    if [ -f "${SCRIPT_DIR}/deploy/.env.prod" ]; then
        scp ${SCP_OPTS} "${SCRIPT_DIR}/deploy/.env.prod" "${REMOTE_HOST}:~/kaizao-server/.env"
    fi
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
