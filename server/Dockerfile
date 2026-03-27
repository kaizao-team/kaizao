# ============ 构建阶段 ============
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
