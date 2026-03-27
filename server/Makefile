.PHONY: build run test lint clean docker-build docker-up docker-down docker-logs migrate

APP_NAME=kaizao-server
MAIN_PATH=./cmd/server
DOCKER_COMPOSE=docker compose

# 构建
build:
	@echo "Building $(APP_NAME)..."
	CGO_ENABLED=0 go build -ldflags="-w -s" -o bin/$(APP_NAME) $(MAIN_PATH)
	@echo "Build complete: bin/$(APP_NAME)"

# 本地运行
run:
	go run $(MAIN_PATH)/main.go

# 运行测试
test:
	go test -v -race -cover ./...

# 代码检查
lint:
	golangci-lint run ./...

# 清理构建产物
clean:
	rm -rf bin/
	go clean

# Docker Compose 构建镜像
docker-build:
	$(DOCKER_COMPOSE) build

# Docker Compose 启动所有服务
docker-up:
	$(DOCKER_COMPOSE) up -d

# Docker Compose 停止所有服务
docker-down:
	$(DOCKER_COMPOSE) down

# Docker Compose 查看日志
docker-logs:
	$(DOCKER_COMPOSE) logs -f server

# Docker Compose 重建并启动 server
docker-restart:
	$(DOCKER_COMPOSE) up -d --build server

# 数据库迁移（使用 mysql 客户端执行 SQL）
migrate:
	@echo "Running database migrations..."
	mysql -h 127.0.0.1 -P 3306 -u kaizao -pkaizao123 kaizao < migrations/001_init_schema.up.sql
	@echo "Migration complete."

# 生成 Swagger 文档
swagger:
	swag init -g cmd/server/main.go -o docs

# 格式化代码
fmt:
	go fmt ./...
	goimports -w .
