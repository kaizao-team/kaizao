#!/usr/bin/env bash
# =============================================================================
# 开造 VCC - 服务健康检查脚本
# 用法: bash healthcheck.sh
# =============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_service() {
    local name="$1"
    local check_cmd="$2"
    local timeout="${3:-5}"

    printf "  %-20s" "$name"

    if eval "timeout $timeout $check_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}[FAIL]${NC}"
        FAIL=$((FAIL + 1))
    fi
}

check_service_warn() {
    local name="$1"
    local check_cmd="$2"
    local timeout="${3:-5}"

    printf "  %-20s" "$name"

    if eval "timeout $timeout $check_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${YELLOW}[WARN]${NC}"
        WARN=$((WARN + 1))
    fi
}

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  开造 VCC - 服务健康检查${NC}"
echo -e "${CYAN}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# ---- Docker 环境检查 ----
echo -e "${CYAN}[Docker 环境]${NC}"
check_service "Docker Engine" "docker info"
check_service "Docker Compose" "docker compose version"
echo ""

# ---- 基础设施服务 ----
echo -e "${CYAN}[基础设施服务]${NC}"

# PostgreSQL
check_service "PostgreSQL" "docker exec vcc-postgres pg_isready -U vibebuild -d vibebuild"

# Redis
check_service "Redis" "docker exec vcc-redis redis-cli ping"

# Elasticsearch
check_service "Elasticsearch" "curl -sf http://localhost:9200/_cluster/health" 10

# Milvus etcd
check_service "Milvus etcd" "docker exec vcc-milvus-etcd etcdctl endpoint health" 10

# Milvus MinIO
check_service "Milvus MinIO" "curl -sf http://localhost:9000/minio/health/live"

# Milvus
check_service "Milvus" "curl -sf http://localhost:9091/healthz" 15
echo ""

# ---- 应用服务 ----
echo -e "${CYAN}[应用服务]${NC}"

# Go Server
check_service "Go Server" "curl -sf http://localhost:8080/health"

# AI Agent
check_service "AI Agent" "curl -sf http://localhost:8000/health" 10

# Nginx
check_service "Nginx" "curl -sf http://localhost/health"
echo ""

# ---- 连通性检查 ----
echo -e "${CYAN}[连通性检查]${NC}"

# Nginx -> Server 代理
check_service_warn "Nginx->Server" "curl -sf http://localhost/api/v1/health"

# Nginx -> AI Agent 代理
check_service_warn "Nginx->AI Agent" "curl -sf http://localhost/ai/health"
echo ""

# ---- Docker 容器状态 ----
echo -e "${CYAN}[容器状态]${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
    docker-compose ps 2>/dev/null || \
    echo "  无法获取容器状态"
echo ""

# ---- 资源使用 ----
echo -e "${CYAN}[资源使用]${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
    $(docker compose ps -q 2>/dev/null) 2>/dev/null || \
    echo "  无法获取资源统计"
echo ""

# ---- 汇总 ----
echo -e "${CYAN}============================================${NC}"
TOTAL=$((PASS + FAIL + WARN))
echo -e "  检查项总计: ${TOTAL}"
echo -e "  ${GREEN}通过: ${PASS}${NC}"
if [ "$WARN" -gt 0 ]; then
    echo -e "  ${YELLOW}警告: ${WARN}${NC}"
fi
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}失败: ${FAIL}${NC}"
fi
echo -e "${CYAN}============================================${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}存在失败的服务，请检查日志: docker-compose logs <服务名>${NC}"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}存在警告项，建议检查相关服务${NC}"
    exit 0
else
    echo -e "${GREEN}所有服务运行正常${NC}"
    exit 0
fi
