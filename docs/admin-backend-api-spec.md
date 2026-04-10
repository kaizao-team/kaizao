# Admin 后管平台 — 后端接口文档

> Base URL: `https://api.kaizao.com/api/v1`
> 所有 `/admin/*` 接口需 **JWT Header** + 数据库 **`role=9` 管理员**
> 更新时间：2026-04-07

---

## 统一响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": { ... },
  "meta": { "page": 1, "page_size": 20, "total": 100, "total_pages": 5 },
  "request_id": "xxx"
}
```

- `code=0` 成功，非零为业务错误码
- `meta` 仅列表接口返回
- 所有时间字段为 ISO 8601 格式

---

## 1. 用户管理

### 1.1 GET `/admin/users` — 用户列表

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认 1 |
| page_size | int | 否 | 每页条数，默认 20，最大 100 |
| keyword | string | 否 | 搜索昵称、UUID |
| role | int | 否 | 1=项目方 2=团队方 9=管理员 |
| status | int | 否 | 0=已冻结 1=正常 |
| onboarding_status | int | 否 | 0=未提交 1=待审核 2=已通过 3=已拒绝 |
| start_date | string | 否 | 注册起始日期 YYYY-MM-DD |
| end_date | string | 否 | 注册结束日期 YYYY-MM-DD |

**响应 data** (数组)

```json
[
  {
    "uuid": "user_001",
    "nickname": "张三",
    "avatar_url": "https://...",
    "phone": "138****8000",
    "role": 1,
    "status": 1,
    "onboarding_status": 2,
    "credit_score": 500,
    "level": 3,
    "completed_orders": 5,
    "created_at": "2026-01-01T10:00:00+08:00",
    "last_login_at": "2026-04-01T15:00:00+08:00",
    "onboarding_submitted_at": "2026-01-05T10:00:00+08:00",
    "onboarding_reviewed_at": "2026-01-06T10:00:00+08:00",
    "onboarding_application_note": "申请备注",
    "resume_url": "https://..."
  }
]
```

> 手机号已脱敏，中间 4 位用 `*` 替换

---

### 1.2 GET `/admin/users/:uuid` — 用户详情

**响应 data**

```json
{
  "uuid": "user_001",
  "nickname": "张三",
  "avatar_url": "https://...",
  "phone": "138****8000",
  "role": 1,
  "gender": 1,
  "bio": "全栈开发者",
  "city": "北京",
  "is_verified": false,
  "credit_score": 500,
  "level": 3,
  "status": 1,
  "onboarding_status": 2,
  "freeze_reason": null,
  "total_orders": 10,
  "completed_orders": 8,
  "avg_rating": 4.50,
  "total_earnings": 50000.00,
  "last_login_at": "2026-04-01T15:00:00+08:00",
  "created_at": "2026-01-01T10:00:00+08:00",
  "onboarding_submitted_at": "2026-01-05T10:00:00+08:00",
  "onboarding_reviewed_at": "2026-01-06T10:00:00+08:00",
  "onboarding_application_note": "申请备注",
  "resume_url": "https://..."
}
```

---

### 1.3 GET `/admin/users/:uuid/skills` — 用户技能

**响应 data** (数组)

```json
[
  {
    "skill_id": 1,
    "skill_name": "Go",
    "category": "后端",
    "proficiency": 4,
    "years_of_experience": 5,
    "is_primary": true
  }
]
```

---

### 1.4 GET `/admin/users/:uuid/portfolios` — 用户作品集

**响应 data** (数组) — 返回 Portfolio 模型完整字段

---

### 1.5 PUT `/admin/users/:uuid/status` — 冻结/解冻用户

**请求体**

```json
{
  "status": 0,
  "reason": "违规操作"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | int | 是 | 0=冻结 1=解冻 |
| reason | string | 否 | 冻结原因（冻结时建议填写） |

**响应**: `{ "code": 0, "message": "已更新" }`

> 不可冻结 role=9 超级管理员，返回 90003

---

### 1.6 PUT `/admin/users/:uuid/onboarding` — 审核入驻

**请求体**

```json
{
  "status": "approved",
  "reason": "可选，拒绝时建议填写"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | string | 是 | `approved` / `rejected` |
| reason | string | 否 | 拒绝原因 |

**响应**: `{ "code": 0, "message": "已更新" }`

---

## 2. 项目管理

### 2.1 GET `/admin/projects` — 项目列表

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 默认 1 |
| page_size | int | 否 | 默认 20 |
| keyword | string | 否 | 搜索标题、UUID |
| status | int | 否 | 1=草稿 2=已发布 3=匹配中 4=进行中 5=已完成 6=已关闭 |
| category | string | 否 | 项目分类 |
| budget_min | float | 否 | 预算下限 |
| budget_max | float | 否 | 预算上限 |
| start_date | string | 否 | YYYY-MM-DD |
| end_date | string | 否 | YYYY-MM-DD |

**响应 data** (数组)

```json
[
  {
    "uuid": "proj_001",
    "title": "智能客服系统",
    "category": "Web开发",
    "status": 2,
    "budget_min": 5000,
    "budget_max": 20000,
    "agreed_price": null,
    "bid_count": 3,
    "view_count": 120,
    "provider_id": null,
    "team_id": null,
    "owner_id": "user_001",
    "owner_nickname": "张三",
    "owner_avatar": "https://...",
    "published_at": "2026-03-01T10:00:00+08:00",
    "created_at": "2026-02-28T10:00:00+08:00"
  }
]
```

---

### 2.2 PUT `/admin/projects/:uuid/review` — 项目审核

**请求体**

```json
{
  "action": "approve",
  "reason": "可选的审核说明"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| action | string | 是 | `approve` / `reject` / `close` |
| reason | string | 否 | reject/close 时建议填写 |

- approve → status=2(已发布) + 自动设 published_at
- reject / close → status=6(已关闭) + close_reason

**响应**: `{ "code": 0, "message": "已更新" }`

---

## 3. Dashboard 数据看板

### 3.1 GET `/admin/dashboard` — 数据看板

**响应 data**

```json
{
  "user_count": 1234,
  "user_today": 12,
  "project_count": 456,
  "project_week": 23,
  "active_team_count": 89,
  "order_total_amount": 1234567.00,
  "order_month_amount": 123456.00,
  "pending_onboarding_count": 5,
  "pending_report_count": 2,
  "user_trend": [
    { "date": "2026-03-08", "count": 10 },
    { "date": "2026-03-09", "count": 15 }
  ],
  "project_trend": [
    { "date": "2026-03-08", "count": 5 }
  ],
  "order_trend": [
    { "date": "2026-03-08", "amount": 12345.00 }
  ]
}
```

| 字段 | 说明 |
|------|------|
| user_count | 总用户数 |
| user_today | 今日注册 |
| project_count | 总项目数 |
| project_week | 本周新项目 |
| active_team_count | 活跃团队（status=1） |
| order_total_amount | 累计已支付订单总额 |
| order_month_amount | 本月已支付总额 |
| pending_onboarding_count | 待审核入驻数 |
| pending_report_count | 待处理举报数 |
| user_trend | 近 30 天每日注册数 |
| project_trend | 近 30 天每日发布数 |
| order_trend | 近 30 天每日订单额（`amount` 字段） |

---

## 4. 举报管理

### 4.1 GET `/admin/reports` — 举报列表

**Query 参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| page | int | 默认 1 |
| page_size | int | 默认 20 |
| status | int | 1=待处理 2=已处理 |

**响应 data** (数组)

```json
[
  {
    "uuid": "rpt_001",
    "reporter_id": 123,
    "reporter_nickname": "张三",
    "target_type": "user",
    "target_id": 456,
    "reason_type": 1,
    "reason_detail": "发布垃圾信息",
    "evidence": ["https://..."],
    "status": 1,
    "handler_id": null,
    "handle_result": null,
    "handled_at": null,
    "created_at": "2026-03-15T10:00:00+08:00"
  }
]
```

---

### 4.2 PUT `/admin/reports/:uuid` — 处理举报

**请求体**

```json
{
  "handle_result": "已核实，冻结被举报账号",
  "action": "freeze_user"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| handle_result | string | 是 | 处理结果说明 |
| action | string | 否 | `freeze_user` 时额外冻结被举报用户 |

**响应**: `{ "code": 0, "message": "已处理" }`

---

## 5. 仲裁管理

### 5.1 GET `/admin/arbitrations` — 仲裁列表

**Query 参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| page | int | 默认 1 |
| page_size | int | 默认 20 |
| status | int | 1=待处理 2=已裁决 |

**响应 data** (数组)

```json
[
  {
    "uuid": "arb_001",
    "project_id": 100,
    "project_title": "智能客服系统",
    "order_id": 50,
    "applicant_id": 123,
    "applicant_nickname": "张三",
    "respondent_id": 456,
    "respondent_nickname": "李四",
    "reason": "交付质量不达标",
    "evidence": [],
    "status": 1,
    "arbiter_id": null,
    "verdict": null,
    "verdict_type": null,
    "refund_amount": null,
    "arbitrated_at": null,
    "created_at": "2026-03-20T10:00:00+08:00"
  }
]
```

---

### 5.2 PUT `/admin/arbitrations/:uuid` — 处理仲裁

**请求体**

```json
{
  "verdict": "交付物不符合 PRD 要求，部分退款",
  "verdict_type": "partial_refund",
  "refund_amount": 5000.00
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| verdict | string | 是 | 裁决说明 |
| verdict_type | string | 否 | `support_applicant` / `support_respondent` / `partial_refund` / `mediation` |
| refund_amount | float | 否 | partial_refund 时填写退款金额 |

**响应**: `{ "code": 0, "message": "已处理" }`

---

## 6. 订单与财务管理

### 6.1 GET `/admin/orders` — 订单列表

**Query 参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| page | int | 默认 1 |
| page_size | int | 默认 20 |
| order_no | string | 订单号搜索（模糊） |
| status | int | 1=待支付 2=已支付 3=托管中 4=已释放 5=已退款 6=已过期 |
| payment_method | string | `wechat` / `alipay` |
| amount_min | float | 金额下限 |
| amount_max | float | 金额上限 |
| start_date | string | YYYY-MM-DD |
| end_date | string | YYYY-MM-DD |

**响应 data** (数组)

```json
[
  {
    "id": 1,
    "uuid": "ord_001",
    "order_no": "ORD20260401001",
    "project_id": 100,
    "project_title": "智能客服系统",
    "payer_id": "user_001",
    "payer_nickname": "张三",
    "payee_nickname": "李四",
    "amount": 10000.00,
    "platform_fee_rate": 0.12,
    "platform_fee": 1200.00,
    "actual_amount": 8800.00,
    "payment_method": "wechat",
    "status": 3,
    "created_at": "2026-03-01T10:00:00+08:00",
    "paid_at": "2026-03-01T10:05:00+08:00"
  }
]
```

---

### 6.2 GET `/admin/orders/:id` — 订单详情

**响应 data** — Order 模型完整字段

---

### 6.3 GET `/admin/finance/summary` — 财务汇总

**响应 data**

```json
{
  "total_gmv": 1234567.00,
  "month_gmv": 123456.00,
  "total_platform_fee": 61728.00,
  "pending_escrow_amount": 50000.00,
  "pending_refund_count": 3
}
```

| 字段 | 说明 |
|------|------|
| total_gmv | 历史已支付订单总额 |
| month_gmv | 本月已支付总额 |
| total_platform_fee | 历史平台手续费总额 |
| pending_escrow_amount | 当前托管中金额（status=3） |
| pending_refund_count | 退款中订单数 |

---

### 6.4 GET `/admin/withdrawals` — 提现记录

**Query 参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| page | int | 默认 1 |
| page_size | int | 默认 20 |
| status | int | 筛选提现状态 |

**响应 data** (数组)

```json
[
  {
    "uuid": "wd_001",
    "user_id": "user_002",
    "user_nickname": "李四",
    "amount": 5000.00,
    "withdraw_method": "alipay",
    "withdraw_account": "138****8000",
    "status": 1,
    "created_at": "2026-03-25T10:00:00+08:00"
  }
]
```

---

## 7. 评价管理

### 7.1 GET `/admin/reviews` — 评价列表

**Query 参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| page | int | 默认 1 |
| page_size | int | 默认 20 |
| status | int | 1=正常 2=已隐藏 |
| rating_min | float | 最低评分 |
| rating_max | float | 最高评分 |
| is_anonymous | bool | 是否匿名 |
| start_date | string | YYYY-MM-DD |
| end_date | string | YYYY-MM-DD |

**响应 data** (数组)

```json
[
  {
    "uuid": "rev_001",
    "project_id": 100,
    "reviewer_id": "user_001",
    "reviewer_nickname": "张三",
    "reviewer_role": 1,
    "reviewee_id": "user_002",
    "reviewee_nickname": "李四",
    "overall_rating": 4.5,
    "content": "交付质量很好",
    "tags": ["高质量", "准时交付"],
    "member_ratings": [],
    "is_anonymous": false,
    "status": 1,
    "reply_content": null,
    "created_at": "2026-03-10T10:00:00+08:00",
    "dimension_ratings": {
      "quality": 5.0,
      "communication": 4.0,
      "timeliness": 5.0,
      "professionalism": 4.0
    }
  }
]
```

---

### 7.2 PUT `/admin/reviews/:uuid/status` — 隐藏/恢复评价

**请求体**

```json
{
  "status": 2
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | int | 是 | 1=恢复正常 2=隐藏 |

**响应**: `{ "code": 0, "message": "已更新" }`

---

## 8. 邀请码管理

### 8.1 POST `/admin/invite-codes` — 批量创建邀请码

**Body**: `{ "count": 10, "note": "备注", "expires_at": "2027-12-31T23:59:59Z" }`

- `count`：创建数量，默认 10，最大 200。创建新码不禁用旧码。
- **响应**: `{ "codes": ["KZ-ABCD1234", ...], "count": 10 }`

### 8.2 GET `/admin/invite-codes` — 邀请码列表

- **Query**: `page`, `page_size`

### 8.3 PUT `/admin/teams/:uuid/approval` — 审核团队

**Body**: `{ "status": "approved" | "rejected", "reason": "可选" }`

**响应**: `{ "code": 0, "message": "已更新" }`

> 详见 `api/specs/16-admin.md`

---

## 错误码

| code | 说明 |
|------|------|
| 90001 | 无管理员权限 |
| 90002 | 目标不存在 |
| 90003 | 不可冻结超级管理员 |
| 90004 | 审核操作无效 |
| 90005 | 用户已被冻结 |
| 90006 | 项目不存在 |
| 90007 | 举报记录不存在 |
| 90008 | 仲裁记录不存在 |
| 90009 | 订单不存在 |
| 90010 | 评价不存在 |
| 90011 | 无效的操作类型 |
| 99001 | 参数错误 |

---

## 路由总览

```
GET    /api/v1/admin/users                         用户列表
GET    /api/v1/admin/users/:uuid                   用户详情
GET    /api/v1/admin/users/:uuid/skills            用户技能
GET    /api/v1/admin/users/:uuid/portfolios        用户作品集
PUT    /api/v1/admin/users/:uuid/status            冻结/解冻
PUT    /api/v1/admin/users/:uuid/onboarding        审核入驻
GET    /api/v1/admin/projects                      项目列表
PUT    /api/v1/admin/projects/:uuid/review         项目审核
GET    /api/v1/admin/dashboard                     数据看板
GET    /api/v1/admin/reports                       举报列表
PUT    /api/v1/admin/reports/:uuid                 处理举报
GET    /api/v1/admin/arbitrations                  仲裁列表
PUT    /api/v1/admin/arbitrations/:uuid            处理仲裁
GET    /api/v1/admin/orders                        订单列表
GET    /api/v1/admin/orders/:id                    订单详情
GET    /api/v1/admin/finance/summary               财务汇总
GET    /api/v1/admin/withdrawals                   提现记录
GET    /api/v1/admin/reviews                       评价列表
PUT    /api/v1/admin/reviews/:uuid/status          隐藏/恢复评价
POST   /api/v1/admin/invite-codes                  批量创建邀请码
GET    /api/v1/admin/invite-codes                  邀请码列表
PUT    /api/v1/admin/teams/:uuid/approval          审核团队
```
