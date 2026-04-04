# ============ 构建阶段 ============
# go.mod/go.sum 未变时，Docker 会复用「go mod download」层。
# 若已安装 docker buildx，可用 Dockerfile.buildkit（BuildKit 缓存卷，改依赖后多为增量）：
#   USE_DOCKERFILE_BUILDKIT=1 bash scripts/wsl_deploy_test.sh
#   或 USE_DOCKERFILE_BUILDKIT=1 bash deploy.sh push
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY go.mod go.sum ./
RUN GOPROXY=https://goproxy.cn,direct go mod download

COPY . .

RUN GOPROXY=https://goproxy.cn,direct CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o /app/kaizao-server ./cmd/server

# ============ 运行阶段 ============
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata wget

ENV TZ=Asia/Shanghai

WORKDIR /app

COPY --from=builder /app/kaizao-server .
COPY --from=builder /app/configs ./configs

EXPOSE 8080

ENTRYPOINT ["./kaizao-server"]
