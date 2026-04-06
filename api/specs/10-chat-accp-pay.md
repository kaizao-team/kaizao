## Phase 5：CHAT + ACCP + PAY 模块接口

> v5.0 — 会话、验收、订单支付等；下列含 **创建订单** 补充说明。

### 5.0 创建订单
- **路径**：`POST /api/v1/orders`
- **鉴权**：Bearer Token（需求方）
- **Body**：`{ "project_id": "项目UUID", "amount": 0 }`（`project_id` 必填；`amount` 可选，具体计价以实现为准）
- **响应**：`message` 为「订单已创建」，`data` 含 `order_id`（UUID）、`order_no`、`status`（如 `pending`）

### 5.0b POST /api/v1/conversations（占位，未使用）

- **说明**：**业务会话仅在撮合成功（接受投标）时由服务端创建**（私聊 `conversation_type=1`、绑定 `project_id`、首条系统消息）。客户端**不要**依赖本接口创建会话；双方后续聊天请使用 **§5.3** `POST /api/v1/conversations/:uuid/messages`。
- **当前行为**：鉴权通过后返回占位成功 JSON（`data` 含 `status: "endpoint ready"`），**无业务语义**，后续若启用需单独改版文档。

### 5.1 获取会话列表

- **路径**：`GET /api/v1/conversations`
- **鉴权**：Bearer Token
- **描述**：获取当前用户的聊天会话列表（路径中的会话标识为 **UUID**，下文 `:uuid` 与路由一致）。仅包含 **未软删**（`status=1`）且当前用户为会话双方之一的记录。
- **查询参数**：

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| offset | int | 0 | 跳过条数，≥0 |
| limit | int | 20 | 每页条数，最大 100 |

- **响应**：`data` 为会话数组；带 **`meta`** 分页：`page`、`page_size`、`total`、`total_pages`（与列表类接口一致）。`unread_count` 为当前用户在该会话的未读条数：他人发送且消息 `id` 大于该用户在 `conversation_members` 中的 `last_read_msg_id` 的数量。`project_title` 来自关联项目标题（无项目时为空字符串）。

```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "conv_001",
      "peer_id": "user_201",
      "peer_name": "张开发",
      "peer_avatar": null,
      "last_message": "好的，我今天先完成看板页面的开发",
      "last_message_time": "2026-03-23T14:30:00Z",
      "unread_count": 3,
      "project_title": "智能客服系统"
    }
  ],
  "meta": {
    "page": 1,
    "page_size": 20,
    "total": 1,
    "total_pages": 1
  }
}
```

### 5.2 获取会话消息列表

- **路径**：`GET /api/v1/conversations/:uuid/messages`
- **鉴权**：Bearer Token
- **查询参数**：`before`（分页游标，**消息表自增 `id`**，仅服务端内部游标）, `limit`（默认 20）
- **描述**：获取某个会话的聊天消息。**仅会话双方**可调；**已软删**会话返回不存在。消息按 `id` **降序**返回（新消息在前，客户端可按需反转展示）。
- **响应**：

```json
{
  "code": 0,
  "data": [
    {
      "id": "msg_001",
      "sender_id": "user_201",
      "content": "你好，我对这个项目很感兴趣",
      "type": "text|image|task_card",
      "status": "sending|sent|failed",
      "created_at": "2026-03-23T10:00:00Z",
      "extra": {
        "task_id": "t3",
        "task_title": "API对接-认证模块",
        "task_type": "event",
        "task_status": "in_progress",
        "task_summary": "对接后端认证接口"
      }
    }
  ]
}
```

### 5.3 发送消息

- **路径**：`POST /api/v1/conversations/:uuid/messages`
- **鉴权**：Bearer Token
- **权限**：仅会话双方；非成员 **403**，业务码 `60002`；已软删会话 **404**（`60001`）。
- **请求体**：

```json
{
  "content": "消息内容",
  "type": "text"
}
```

- **响应**：

```json
{
  "code": 0,
  "data": {
    "id": "msg_new_001",
    "status": "sent"
  }
}
```

### 5.4 标记会话已读

- **路径**：`POST /api/v1/conversations/:uuid/read`
- **鉴权**：Bearer Token
- **权限**：同 5.2 / 5.3。
- **行为**：将当前用户在该会话的已读位置更新为**当前最新消息的数据库 `id`**（写入 `conversation_members.last_read_msg_id`），用于驱动列表中的 `unread_count`。
- **响应**：`{ "code": 0, "message": "ok" }`

### 5.5 删除会话

- **路径**：`DELETE /api/v1/conversations/:uuid`
- **鉴权**：Bearer Token
- **权限**：同 5.2；**软删除**（会话 `status=2`），之后该 `:uuid` 对消息接口视为不存在。
- **响应**：`{ "code": 0, "message": "已删除" }`

### 5.6 获取验收清单

- **路径**：`GET /api/v1/milestones/:id/acceptance`
- **鉴权**：Bearer Token
- **描述**：获取某个里程碑的验收清单
- **响应**：

```json
{
  "code": 0,
  "data": {
    "milestone_id": "m1",
    "milestone_title": "需求确认 & 基础框架",
    "amount": 1500,
    "payee_name": "张开发",
    "preview_url": "https://preview.vibebuild.com/proj_001/m1",
    "items": [
      {
        "id": "ac_001",
        "description": "用户可通过手机号+验证码登录",
        "is_checked": true,
        "source_card": "FE-AUTH-001"
      }
    ]
  }
}
```

### 5.7 确认验收

- **路径**：`POST /api/v1/milestones/:id/accept`
- **鉴权**：Bearer Token
- **描述**：确认验收通过并释放托管资金
- **响应**：

```json
{
  "code": 0,
  "message": "验收通过，款项已释放",
  "data": {
    "status": "accepted",
    "released_amount": 1500
  }
}
```

### 5.8 提交修改请求

- **路径**：`POST /api/v1/milestones/:id/revision`
- **鉴权**：Bearer Token
- **请求体**：

```json
{
  "description": "登录页面输入手机号后没有弹出验证码",
  "related_items": ["ac_001", "ac_002"]
}
```

- **响应**：

```json
{
  "code": 0,
  "message": "修改请求已提交",
  "data": {
    "revision_id": "rev_001",
    "status": "revision_requested"
  }
}
```

### 5.9 获取订单详情

- **路径**：`GET /api/v1/orders/:id`
- **鉴权**：Bearer Token
- **描述**：获取订单确认页所需的全部信息
- **响应**：

```json
{
  "code": 0,
  "data": {
    "id": "order_001",
    "project_id": "1",
    "project_title": "智能客服系统",
    "payee_name": "张开发",
    "project_amount": 8000,
    "platform_fee": 400,
    "discount": 0,
    "total_amount": 8400,
    "milestones": [
      { "title": "需求确认 & 基础框架", "amount": 1500, "status": "paid" },
      { "title": "核心功能开发", "amount": 3000, "status": "current" },
      { "title": "通信 & 支付模块", "amount": 2000, "status": "pending" },
      { "title": "测试 & 上线", "amount": 1500, "status": "pending" }
    ],
    "guarantee_text": "资金由平台托管，验收通过后释放给供给方",
    "status": "pending"
  }
}
```

### 5.10 发起支付

- **路径**：`POST /api/v1/orders/:id/prepay`
- **鉴权**：Bearer Token
- **请求体**：

```json
{
  "payment_method": "wechat|alipay",
  "coupon_id": "cpn_001"
}
```

- **响应**：

```json
{
  "code": 0,
  "data": {
    "payment_id": "pay_001",
    "payment_method": "wechat",
    "payment_url": "https://pay.example.com/mock",
    "status": "success"
  }
}
```

### 5.11 查询支付状态

- **路径**：`GET /api/v1/orders/:id/status`
- **鉴权**：Bearer Token
- **响应**：

```json
{
  "code": 0,
  "data": {
    "status": "success|pending|failed",
    "paid_amount": 3000,
    "paid_at": "2026-03-23T15:00:00Z"
  }
}
```

### 5.12 获取优惠券列表

- **路径**：`GET /api/v1/coupons`
- **鉴权**：Bearer Token
- **响应**：

```json
{
  "code": 0,
  "data": [
    {
      "id": "cpn_001",
      "title": "新用户专享",
      "discount_amount": 200,
      "min_order_amount": 1000,
      "expire_date": "2026-04-30",
      "is_available": true,
      "reason": null
    }
  ]
}
```

---

