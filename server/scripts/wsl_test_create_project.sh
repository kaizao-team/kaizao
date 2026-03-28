#!/bin/bash
set -euo pipefail
BASE="${1:-http://127.0.0.1:18080}"
PHONE="139$(date +%s | tail -c 9)"
echo "=== Base: $BASE  Phone: $PHONE ==="

echo "--- POST /api/v1/auth/sms-code ---"
curl -sS -X POST "$BASE/api/v1/auth/sms-code" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\",\"purpose\":2}"
echo

echo "--- POST /api/v1/auth/login (magic code) ---"
RESP=$(curl -sS -X POST "$BASE/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\",\"code\":\"952786\"}")
echo "$RESP"
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('access_token',''))")
if [ -z "$TOKEN" ]; then
  echo "FATAL: no access_token"
  exit 1
fi

echo "--- POST /api/v1/projects (create) ---"
curl -sS -X POST "$BASE/api/v1/projects" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "WSL集成测试项目创建",
    "description": "在WSL Docker环境下验证 POST /api/v1/projects 创建需求接口是否正常工作。",
    "category": "app",
    "budget_min": 3000,
    "budget_max": 12000,
    "tech_requirements": ["Flutter", "Go"],
    "match_mode": 1,
    "is_draft": false
  }'
echo
echo "=== done ==="
