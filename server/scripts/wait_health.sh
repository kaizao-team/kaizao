#!/bin/bash
set -euo pipefail
BASE="${1:-http://127.0.0.1:8080}"
for i in $(seq 1 30); do
  if curl -sf "${BASE}/health" > /dev/null 2>&1; then
    echo "Server healthy"
    exit 0
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done
echo "TIMEOUT: server not healthy"
exit 1
