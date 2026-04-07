# Admin 后管平台 — 后端接口对照清单

> 前端项目 `admin-web/` 所使用的全部后端接口汇总。
> 基线：`server/internal/router/router.go` + `server/internal/handler/admin.go`
> 更新时间：2026-04-07

---

## 一、已实现接口（可直接联调）

以下接口后端已有完整业务逻辑（非 placeholder），可直接联调。

### 1.1 Admin 专用接口（`/api/v1/admin/...`）

| # | 方法 | 路径 | Handler | 前端函数 | 前端文件 |
|---|------|------|---------|----------|----------|
| 1 | GET | `/admin/invite-codes` | `AdminHandler.ListInviteCodes` | `getInviteCodes` | `api/invite-codes.ts` |
| 2 | POST | `/admin/invite-codes` | `AdminHandler.CreateInviteCode` | `createInviteCode` / `createInviteCodeForTeam` | `api/invite-codes.ts` / `api/teams.ts` |
| 3 | GET | `/admin/teams/:uuid/current-invite-code` | `AdminHandler.GetTeamCurrentInviteCode` | `getTeamCurrentInviteCode` | `api/teams.ts` |
| 4 | PUT | `/admin/users/:uuid/onboarding` | `AdminHandler.UpdateUserOnboarding` | `updateUserOnboarding` | `api/users.ts` |

### 1.2 通用接口（前端复用的非 admin 路径）

以下接口为公共路由，admin 端通过 JWT 令牌（role=9）访问：

| # | 方法 | 路径 | 前端函数 | 前端文件 | 说明 |
|---|------|------|----------|----------|------|
| 5 | POST | `/auth/login-password` | `loginByPassword` | `api/auth.ts` | 管理员登录 |
| 6 | GET | `/auth/password-key` | `getPasswordKey` | `api/auth.ts` | 获取密码加密公钥（暂未使用） |
| 7 | GET | `/teams` | `getTeams` | `api/teams.ts` | 团队列表 |
| 8 | GET | `/teams/:uuid` | `getTeamDetail` | `api/teams.ts` | 团队详情 |
| 9 | GET | `/teams/:uuid/static-assets` | `getTeamStaticAssets` | `api/teams.ts` | 团队静态资源 |
| 10 | GET | `/projects/:id` | `getProjectDetail` | `api/projects.ts` | 项目详情 |
| 11 | GET | `/projects/:id/files` | `getProjectFiles` | `api/projects.ts` | 项目文档列表 |
| 12 | POST | `/projects/:id/files` | `uploadProjectFile` | `api/projects.ts` | 上传项目文档 |
| 13 | GET | `/projects/:id/bids` | `getProjectBids` | `api/projects.ts` | 投标列表 |
| 14 | GET | `/projects/:id/milestones` | `getProjectMilestones` | `api/projects.ts` | 里程碑列表 |
| 15 | GET | `/projects/:id/tasks` | `getProjectTasks` | `api/projects.ts` | 任务列表 |
| 16 | GET | `/projects/:id/reviews` | `getProjectReviews` | `api/projects.ts` | 项目评价列表 |
| 17 | GET | `/projects/:id/prd` | `getProjectPRD` | `api/projects.ts` | 项目 PRD |

---

## 二、需要修改的接口（Placeholder，路由已注册但返回空壳）

以下路由在 `router.go` 中已注册但绑定的是 `placeholder` 函数（固定返回 `{ code: 0, data: { status: "endpoint ready" } }`），需要**补全真正的业务逻辑**。

### 2.1 用户管理

**`GET /api/v1/admin/users`** — 用户列表

前端函数：`getUsers`（`api/users.ts`）

Query 参数：
```
page=1
page_size=20
keyword=xxx           # 搜索昵称、手机号、UUID
role=1                # 0=未选 1=项目方 2=团队方 9=管理员
status=1              # 0=已冻结 1=正常
onboarding_status=1   # 0=未提交 1=待审核 2=已通过 3=已拒绝
start_date=2026-01-01
end_date=2026-04-01
```

期望返回：
```json
{
  "code": 0,
  "data": [
    {
      "uuid": "user_001",
      "nickname": "张三",
      "avatar_url": "https://...",
      "role": 1,
      "phone": "13800138000",
      "onboarding_status": 2,
      "credit_score": 100,
      "level": 3,
      "completed_orders": 5,
      "status": 1,
      "created_at": "2026-01-01T10:00:00Z",
      "last_login_at": "2026-04-01T15:00:00Z",
      "onboarding_submitted_at": "2026-01-05T10:00:00Z",
      "onboarding_reviewed_at": "2026-01-06T10:00:00Z",
      "onboarding_application_note": "申请备注",
      "resume_url": "https://..."
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 100, "total_pages": 5 }
}
```

---

**`PUT /api/v1/admin/users/:uuid/status`** — 冻结/解冻用户

前端函数：`updateUserStatus`（`api/users.ts`）

请求体：
```json
{
  "status": 0,
  "reason": "违规操作"
}
```

期望返回：`{ "code": 0, "message": "已更新" }`

---

### 2.2 项目管理

**`GET /api/v1/admin/projects`** — 项目列表

前端函数：`getAdminProjects`（`api/projects.ts`）

Query 参数：
```
page=1
page_size=20
keyword=xxx           # 搜索标题、UUID
status=2              # 1=草稿 2=已发布 3=匹配中 4=进行中 5=已完成 6=已关闭
category=xxx
budget_min=1000
budget_max=50000
start_date=2026-01-01
end_date=2026-04-01
```

期望返回：
```json
{
  "code": 0,
  "data": [
    {
      "uuid": "proj_001",
      "title": "智能客服系统",
      "owner_id": "user_001",
      "owner_nickname": "张三",
      "owner_avatar": "https://...",
      "provider_id": null,
      "team_id": null,
      "category": "Web开发",
      "budget_min": 5000,
      "budget_max": 20000,
      "agreed_price": null,
      "status": 2,
      "bid_count": 3,
      "view_count": 120,
      "published_at": "2026-03-01T10:00:00Z",
      "created_at": "2026-02-28T10:00:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 50, "total_pages": 3 }
}
```

---

**`PUT /api/v1/admin/projects/:uuid/review`** — 项目审核

前端函数：`reviewProject`（`api/projects.ts`）

请求体：
```json
{
  "action": "approve",
  "reason": "可选的审核说明"
}
```

action 枚举：`approve` / `reject` / `close`

---

### 2.3 Dashboard 数据看板

**`GET /api/v1/admin/dashboard`** — 数据看板

前端函数：`getDashboard`（`api/dashboard.ts`）

期望返回：
```json
{
  "code": 0,
  "data": {
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
      { "date": "2026-03-01", "count": 10 },
      { "date": "2026-03-02", "count": 15 }
    ],
    "project_trend": [
      { "date": "2026-03-01", "count": 5 }
    ],
    "order_trend": [
      { "date": "2026-03-01", "amount": 12345.00 }
    ]
  }
}
```

---

### 2.4 举报管理

**`GET /api/v1/admin/reports`** — 举报列表

前端函数：`getReports`（`api/reports.ts`）

Query 参数：
```
page=1
page_size=20
status=1              # 1=待处理 2=已处理
```

期望返回：
```json
{
  "code": 0,
  "data": [
    {
      "uuid": "rpt_001",
      "reporter_id": "user_001",
      "reporter_nickname": "张三",
      "target_type": "user",
      "target_id": "user_002",
      "reason_type": "spam",
      "reason_detail": "发布垃圾信息",
      "evidence": { "images": ["https://..."], "text": "截图说明" },
      "status": 1,
      "handler_id": null,
      "handle_result": null,
      "created_at": "2026-03-15T10:00:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 10 }
}
```

---

**`PUT /api/v1/admin/reports/:uuid`** — 处理举报

前端函数：`handleReport`（`api/reports.ts`）

请求体：
```json
{
  "handle_result": "已核实，冻结被举报账号",
  "action": "freeze_user"
}
```

---

### 2.5 仲裁管理

**`GET /api/v1/admin/arbitrations`** — 仲裁列表

前端函数：`getArbitrations`（`api/arbitrations.ts`）

Query 参数：
```
page=1
page_size=20
status=1              # 1=待处理 2=处理中 3=已裁决
```

期望返回：
```json
{
  "code": 0,
  "data": [
    {
      "uuid": "arb_001",
      "project_id": "proj_001",
      "project_title": "智能客服系统",
      "order_id": "ord_001",
      "applicant_id": "user_001",
      "applicant_nickname": "张三",
      "respondent_id": "user_002",
      "respondent_nickname": "李四",
      "reason": "交付质量不达标",
      "evidence": { "images": [], "text": "详细说明" },
      "status": 1,
      "arbiter_id": null,
      "verdict": null,
      "verdict_type": null,
      "refund_amount": null,
      "arbitrated_at": null,
      "created_at": "2026-03-20T10:00:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 5 }
}
```

---

**`PUT /api/v1/admin/arbitrations/:uuid`** — 处理仲裁

前端函数：`handleArbitration`（`api/arbitrations.ts`）

请求体：
```json
{
  "verdict": "交付物不符合 PRD 要求，部分退款",
  "verdict_type": "partial_refund",
  "refund_amount": 5000.00
}
```

verdict_type 枚举：`support_applicant` / `support_respondent` / `partial_refund` / `mediation`

---

## 三、未实现（需新增）的接口

以下接口**在后端 `router.go` 中完全未注册**（既不是 placeholder 也不是已实现），需要新增路由 + handler + service + 数据库查询。

### 3.1 用户详情管理

| # | 方法 | 路径 | 前端函数 | 前端文件 | 说明 |
|---|------|------|----------|----------|------|
| 1 | GET | `/admin/users/:uuid` | `getUserDetail` | `api/users.ts` | 用户详情（admin 视角，需返回完整信息） |
| 2 | GET | `/admin/users/:uuid/skills` | `getUserSkills` | `api/users.ts` | 用户技能标签 |
| 3 | GET | `/admin/users/:uuid/portfolios` | `getUserPortfolios` | `api/users.ts` | 用户作品集 |

> **备注：** 目前后端有公共接口 `GET /users/:id`、`GET /users/:id/skills`、`GET /users/:id/portfolios`。  
> 两种方案：
> 1. 新增 `/admin/users/:uuid/*` 路由（推荐，可返回更多管理字段如手机号、冻结原因等）
> 2. 管理端复用公共接口（但可能缺少管理专用字段）

---

### 3.2 订单与财务管理

| # | 方法 | 路径 | 前端函数 | 前端文件 | 说明 |
|---|------|------|----------|----------|------|
| 4 | GET | `/admin/orders` | `getAdminOrders` | `api/orders.ts` | 订单列表（分页、筛选） |
| 5 | GET | `/admin/orders/:id` | `getOrderDetail` | `api/orders.ts` | 订单详情 |
| 6 | GET | `/admin/finance/summary` | `getFinanceSummary` | `api/orders.ts` | 财务汇总（GMV、平台收入、托管金额等） |
| 7 | GET | `/admin/withdrawals` | `getWithdrawals` | `api/orders.ts` | 提现记录列表 |

**`GET /api/v1/admin/orders`** 期望参数：
```
page=1 / page_size=20
order_no=xxx          # 订单号搜索
status=1              # 1=待支付 2=已支付 3=托管中 4=已释放 5=已退款 6=已过期
payment_method=wechat # wechat / alipay
amount_min=100 / amount_max=50000
start_date / end_date
```

期望返回：
```json
{
  "code": 0,
  "data": [
    {
      "order_no": "ORD20260401001",
      "project_id": "proj_001",
      "project_title": "智能客服系统",
      "milestone_id": "ms_001",
      "payer_id": "user_001",
      "payer_nickname": "张三",
      "payee_id": "user_002",
      "payee_team_id": "team_001",
      "amount": 10000.00,
      "platform_fee_rate": 0.05,
      "platform_fee": 500.00,
      "actual_amount": 9500.00,
      "payment_method": "wechat",
      "status": 3,
      "created_at": "2026-03-01T10:00:00Z",
      "paid_at": "2026-03-01T10:05:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 30 }
}
```

**`GET /api/v1/admin/finance/summary`** 期望返回：
```json
{
  "code": 0,
  "data": {
    "total_gmv": 1234567.00,
    "month_gmv": 123456.00,
    "total_platform_fee": 61728.00,
    "pending_escrow_amount": 50000.00,
    "pending_refund_count": 3
  }
}
```

**`GET /api/v1/admin/withdrawals`** 期望返回：
```json
{
  "code": 0,
  "data": [
    {
      "uuid": "wd_001",
      "user_id": "user_002",
      "user_nickname": "李四",
      "amount": 5000.00,
      "withdraw_method": "alipay",
      "withdraw_account": "138****8000",
      "status": 1,
      "created_at": "2026-03-25T10:00:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 10 }
}
```

---

### 3.3 评价管理

| # | 方法 | 路径 | 前端函数 | 前端文件 | 说明 |
|---|------|------|----------|----------|------|
| 8 | GET | `/admin/reviews` | `getAdminReviews` | `api/reviews.ts` | 评价列表（分页、筛选） |
| 9 | PUT | `/admin/reviews/:uuid/status` | `updateReviewStatus` | `api/reviews.ts` | 隐藏/恢复评价 |

**`GET /api/v1/admin/reviews`** 期望参数：
```
page=1 / page_size=20
status=1              # 1=正常 2=已隐藏
rating_min=1 / rating_max=5
is_anonymous=true
start_date / end_date
```

期望返回：
```json
{
  "code": 0,
  "data": [
    {
      "uuid": "rev_001",
      "project_id": "proj_001",
      "project_title": "智能客服系统",
      "reviewer_id": "user_001",
      "reviewer_nickname": "张三",
      "reviewer_role": 1,
      "reviewee_id": "user_002",
      "reviewee_nickname": "李四",
      "overall_rating": 4.5,
      "content": "交付质量很好，沟通顺畅",
      "tags": ["高质量", "准时交付"],
      "is_anonymous": false,
      "status": 1,
      "created_at": "2026-03-10T10:00:00Z",
      "dimension_ratings": {
        "quality": 5,
        "communication": 4,
        "timeliness": 5,
        "professionalism": 4
      },
      "member_ratings": [],
      "reply_content": null
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 20 }
}
```

**`PUT /api/v1/admin/reviews/:uuid/status`** 请求体：
```json
{
  "status": 2
}
```
status：`1` = 恢复正常，`2` = 隐藏

---

## 四、接口路径一致性说明

### 前端使用了非 `/admin` 前缀的接口

以下接口前端通过通用路径访问，建议后端确认这些接口在 admin token（role=9）下的数据权限是否合适：

| 前端路径 | 对应公共路由 | 建议 |
|----------|-------------|------|
| `/teams` | `GET /api/v1/teams` | 建议后续新增 `/admin/teams`，支持更多筛选字段 |
| `/teams/:uuid` | `GET /api/v1/teams/:uuid` | 可复用，但 admin 可能需要额外字段 |
| `/teams/:uuid/static-assets` | `GET /api/v1/teams/:uuid/static-assets` | 可复用 |
| `/projects/:id` | `GET /api/v1/projects/:id` | 可复用 |
| `/projects/:id/files` | `GET/POST /api/v1/projects/:id/files` | 可复用 |
| `/projects/:id/bids` | `GET /api/v1/projects/:id/bids` | 可复用 |
| `/projects/:id/milestones` | `GET /api/v1/projects/:id/milestones` | 可复用 |
| `/projects/:id/tasks` | `GET /api/v1/projects/:id/tasks` | 可复用 |
| `/projects/:id/reviews` | `GET /api/v1/projects/:id/reviews` | 可复用 |
| `/projects/:id/prd` | `GET /api/v1/projects/:id/prd` | 可复用 |
| `/auth/login-password` | `POST /api/v1/auth/login-password` | 共用登录接口 |

---

## 五、优先级建议

| 优先级 | 接口 | 类型 | 原因 |
|--------|------|------|------|
| **P0** | `GET /admin/users` | Placeholder → 实现 | 用户管理核心功能 |
| **P0** | `PUT /admin/users/:uuid/status` | Placeholder → 实现 | 冻结/解冻安全操作 |
| **P0** | `GET /admin/users/:uuid` | **新增** | 用户详情页依赖 |
| **P1** | `GET /admin/projects` | Placeholder → 实现 | 项目管理 |
| **P1** | `PUT /admin/projects/:uuid/review` | Placeholder → 实现 | 项目审核 |
| **P1** | `GET /admin/dashboard` | Placeholder → 实现 | 首页看板 |
| **P2** | 举报 2 个 | Placeholder → 实现 | 内容安全 |
| **P2** | 仲裁 2 个 | Placeholder → 实现 | 争议处理 |
| **P2** | 订单 4 个 | **新增** | 财务管理 |
| **P3** | 评价 2 个 | **新增** | 内容审核 |
| **P3** | 用户技能/作品集 2 个 | **新增** | 用户详情子页签 |

---

## 六、统计

| 分类 | 接口数 |
|------|--------|
| 已实现（Admin 专用） | 4 |
| 已实现（通用接口复用） | 13 |
| Placeholder（需补全逻辑） | 9 |
| 新增（完全未注册） | 9 |
| **合计** | **35** |
