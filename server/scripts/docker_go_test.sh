#!/bin/bash
# 在 golang 容器内执行 go test（避免 Windows/PowerShell 引号破坏 ./...）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
docker run --rm \
  -v "$ROOT:/app" -w /app \
  -e GOPROXY="${GOPROXY:-https://goproxy.cn,direct}" \
  golang:1.22-bookworm \
  bash -c 'go test -count=1 ./...'
