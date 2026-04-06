## 9. Wallet — 钱包模块 (v6.0 新增)

### 9.1 GET /api/v1/wallet/balance — 获取钱包余额

**响应**:
```json
{
  "code": 0,
  "data": {
    "available": 23680.0,
    "frozen": 15000.0,
    "total_earned": 86500.0,
    "total_withdrawn": 47820.0
  }
}
```

### 9.2 GET /api/v1/wallet/transactions — 获取交易记录

**Query 参数**: `page`, `page_size`

**响应**:
```json
{
  "code": 0,
  "data": [
    {
      "id": "txn_01",
      "type": "income|withdraw|fee",
      "title": "项目验收 - 智能客服系统",
      "amount": 3000.0,
      "status": "completed|processing",
      "created_at": "2026-03-20T14:30:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 10, "total": 7, "total_pages": 1 }
}
```

### 9.3 POST /api/v1/wallet/withdraw — 发起提现

**请求体**:
```json
{
  "amount": 5000.0,
  "method": "wechat|alipay"
}
```

**响应**:
```json
{
  "code": 0,
  "message": "提现申请已提交",
  "data": {
    "withdraw_id": "wd_xxx",
    "amount": 5000.0,
    "method": "wechat",
    "status": "processing",
    "estimated_arrival": "T+1个工作日"
  }
}
```

---
