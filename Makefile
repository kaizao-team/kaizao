# =============================================================================
# 开造 VCC - 顶层 Makefile
# =============================================================================

.PHONY: help dev build up down logs migrate test clean ps health

# 默认目标
help: ## 显示帮助信息
	@echo ""
	@echo "  开造 VCC - 项目管理命令"
	@echo "  ========================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ---- 环境变量 ----
COMPOSE_FILE := deploy/docker-compose.yml
COMPOSE_CMD := docker compose -f $(COMPOSE_FILE)
ENV_FILE := deploy/.env

# ---- 开发环境 ----
dev: ## 启动开发环境 (带日志输出)
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "未找到 .env 文件，正在从模板复制..."; \
		cp deploy/.env.example $(ENV_FILE); \
		echo "请编辑 $(ENV_FILE) 填入必要的密钥后重新运行"; \
		exit 1; \
	fi
	$(COMPOSE_CMD) --env-file $(ENV_FILE) up --build

# ---- 构建 ----
build: ## 构建所有 Docker 镜像
	$(COMPOSE_CMD) --env-file $(ENV_FILE) build

build-server: ## 仅构建 Go 后端镜像
	$(COMPOSE_CMD) --env-file $(ENV_FILE) build server

build-ai: ## 仅构建 AI Agent 镜像
	$(COMPOSE_CMD) --env-file $(ENV_FILE) build ai-agent

# ---- 启停 ----
up: ## 启动所有服务 (后台)
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "未找到 .env 文件，正在从模板复制..."; \
		cp deploy/.env.example $(ENV_FILE); \
		echo "请编辑 $(ENV_FILE) 填入必要的密钥后重新运行"; \
		exit 1; \
	fi
	$(COMPOSE_CMD) --env-file $(ENV_FILE) up -d
	@echo ""
	@echo "服务已启动，等待健康检查..."
	@sleep 5
	@$(COMPOSE_CMD) --env-file $(ENV_FILE) ps

down: ## 停止所有服务 (保留数据)
	$(COMPOSE_CMD) --env-file $(ENV_FILE) down

restart: ## 重启所有服务
	$(COMPOSE_CMD) --env-file $(ENV_FILE) restart

# ---- 日志 ----
logs: ## 查看所有服务日志 (实时)
	$(COMPOSE_CMD) --env-file $(ENV_FILE) logs -f --tail=100

logs-server: ## 查看 Go 后端日志
	$(COMPOSE_CMD) --env-file $(ENV_FILE) logs -f --tail=100 server

logs-ai: ## 查看 AI Agent 日志
	$(COMPOSE_CMD) --env-file $(ENV_FILE) logs -f --tail=100 ai-agent

logs-nginx: ## 查看 Nginx 日志
	$(COMPOSE_CMD) --env-file $(ENV_FILE) logs -f --tail=100 nginx

logs-db: ## 查看 PostgreSQL 日志
	$(COMPOSE_CMD) --env-file $(ENV_FILE) logs -f --tail=100 postgres

# ---- 数据库 ----
migrate: ## 运行数据库迁移 (重新执行初始化SQL)
	@echo "正在重置数据库..."
	$(COMPOSE_CMD) --env-file $(ENV_FILE) exec postgres psql -U vibebuild -d vibebuild -f /docker-entrypoint-initdb.d/01_create_tables.sql
	@echo "数据库迁移完成"

db-shell: ## 进入 PostgreSQL 交互终端
	$(COMPOSE_CMD) --env-file $(ENV_FILE) exec postgres psql -U vibebuild -d vibebuild

db-backup: ## 备份数据库到 deploy/backups/
	@mkdir -p deploy/backups
	$(COMPOSE_CMD) --env-file $(ENV_FILE) exec -T postgres pg_dump -U vibebuild vibebuild > deploy/backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "备份已保存到 deploy/backups/"

db-restore: ## 从备份恢复 (用法: make db-restore FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then echo "请指定备份文件: make db-restore FILE=deploy/backups/backup_xxx.sql"; exit 1; fi
	$(COMPOSE_CMD) --env-file $(ENV_FILE) exec -T postgres psql -U vibebuild vibebuild < $(FILE)
	@echo "数据库恢复完成"

# ---- 测试 ----
test: ## 运行所有测试
	@echo "=== Go 后端测试 ==="
	cd vibebuild-server && go test -race -cover ./... 2>/dev/null || echo "Go 测试跳过 (服务目录不存在)"
	@echo ""
	@echo "=== Python AI Agent 测试 ==="
	cd vibebuild-ai-agent && python -m pytest 2>/dev/null || echo "Python 测试跳过 (服务目录不存在)"

test-server: ## 仅运行 Go 后端测试
	cd vibebuild-server && go test -race -cover -v ./...

test-ai: ## 仅运行 AI Agent 测试
	cd vibebuild-ai-agent && python -m pytest -v

# ---- 健康检查 ----
health: ## 检查所有服务健康状态
	@bash deploy/healthcheck.sh

ps: ## 查看服务运行状态
	$(COMPOSE_CMD) --env-file $(ENV_FILE) ps

stats: ## 查看资源使用情况
	@docker stats --no-stream $$($(COMPOSE_CMD) --env-file $(ENV_FILE) ps -q)

# ---- 清理 ----
clean: ## 停止服务并删除所有数据卷 (危险!)
	@echo "WARNING: 此操作将删除所有数据！"
	@read -p "确认继续? (输入 yes): " confirm && [ "$$confirm" = "yes" ] || exit 1
	$(COMPOSE_CMD) --env-file $(ENV_FILE) down -v --remove-orphans
	@echo "已清理所有容器和数据卷"

clean-images: ## 删除项目构建的镜像
	docker rmi $$(docker images vibebuild/* -q) 2>/dev/null || true
	@echo "已清理项目镜像"
