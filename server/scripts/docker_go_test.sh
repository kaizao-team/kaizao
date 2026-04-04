#!/bin/bash
# 在 golang 容器内执行 go test（避免 Windows/PowerShell 引号破坏 ./...）
#
# 将容器内 GOPROXY 下载的模块与编译缓存映射到宿主机，重复执行时仅增量下载/编译：
#   默认目录（相对 kaizao/server）: .docker-cache/go/pkg/mod 与 .docker-cache/go-build
# 可通过环境变量覆盖宿主机路径：
#   KAIZAO_GO_MODCACHE      模块缓存（对应容器 /go/pkg/mod）
#   KAIZAO_GO_BUILD_CACHE   构建缓存（对应容器内 GOCACHE）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODCACHE="${KAIZAO_GO_MODCACHE:-$ROOT/.docker-cache/go/pkg/mod}"
BUILD_CACHE="${KAIZAO_GO_BUILD_CACHE:-$ROOT/.docker-cache/go-build}"
mkdir -p "$MODCACHE" "$BUILD_CACHE"

docker run --rm \
  -v "$ROOT:/app" -w /app \
  -v "$MODCACHE:/go/pkg/mod" \
  -v "$BUILD_CACHE:/root/.cache/go-build" \
  -e GOPROXY="${GOPROXY:-https://goproxy.cn,direct}" \
  -e GOMODCACHE=/go/pkg/mod \
  -e GOCACHE=/root/.cache/go-build \
  golang:1.22-bookworm \
  bash -c 'go test -count=1 ./...'
