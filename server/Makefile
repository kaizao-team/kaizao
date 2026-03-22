.PHONY: build run test lint clean docker-build docker-up docker-down migrate

# 变量
APP_NAME=vibebuild-server
MAIN_PATH=./cmd/server
DOCKER_COMPOSE=docker-compose

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

# Docker 构建镜像
docker-build:
	docker build -t $(APP_NAME):latest .

# Docker Compose 启动
docker-up:
	$(DOCKER_COMPOSE) up -d

# Docker Compose 停止
docker-down:
	$(DOCKER_COMPOSE) down

# 数据库迁移（使用 psql 直接执行 SQL）
migrate:
	@echo "Running database migrations..."
	PGPASSWORD=vibebuild123 psql -h localhost -U vibebuild -d vibebuild -f migrations/001_init_schema.up.sql
	@echo "Migration complete."

# 生成 Swagger 文档（如使用 swaggo）
swagger:
	swag init -g cmd/server/main.go -o docs

# 格式化代码
fmt:
	go fmt ./...
	goimports -w .
