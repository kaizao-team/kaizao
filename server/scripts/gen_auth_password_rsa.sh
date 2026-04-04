#!/bin/bash
# 生成生产用 RSA 私钥（PKCS#1），写入 configs/auth_password_rsa.pem；已存在则跳过。
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/configs/auth_password_rsa.pem"
mkdir -p "$ROOT/configs"
if [ -s "$OUT" ]; then
  echo "已存在非空密钥: $OUT（不覆盖）"
  exit 0
fi
if [ -f "$OUT" ]; then
  echo "发现空文件或损坏的 $OUT，重新生成..."
  rm -f "$OUT"
fi
openssl genrsa -out "$OUT" 2048
chmod 600 "$OUT"
echo "已生成: $OUT"
echo "请勿提交 git；备份后用于 deploy.sh 同步到远程 ~/kaizao-server/configs/"
