# VCC 开造 — API 接口规范（Mock 数据对应）

> 版本：v2.0（Phase 2）
> 日期：2026-03-23
> 说明：此文档整理前端 Mock 层对应的所有 API 接口，方便后端按此规范实现。

## 通用约定

### 请求格式
- Content-Type: `application/json`
- 认证: `Authorization: Bearer <access_token>`

### 响应格式

```json
{
  "code": 0,
  "message": "ok",
  "data": {},
  "meta": { "page": 1, "page_size": 20, "total": 100, "total_pages": 5 },
  "request_id": "uuid"
}
```

- `code`: 0 成功, 非0 业务错误
- `meta`: 仅分页接口返回

---

## 1. 认证模块

### 1.1 发送短信验证码
- **POST** `/api/v1/auth/sms-code`
- **Body**: `{ "phone": "13800138000", "purpose": 2 }`
- **Response**: `{ "code": 0, "message": "验证码已发送" }`
- **说明**: purpose=1 注册, purpose=2 登录

### 1.2 手机号登录/注册
- **POST** `/api/v1/auth/login`
- **Body**: `{ "phone": "13800138000", "code": "1234" }`
- **Response**:
```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "access_token": "string",
    "refresh_token": "string",
    "user_id": "string",
    "role": 0,
    "is_new_user": true
  }
}
```
- **说明**: role=0 未选角色, role=1 需求方, role=2 专家; is_new_user=true 时前端进入引导流程

### 1.3 刷新 Token
- **POST** `/api/v1/auth/refresh`
- **Body**: `{ "refresh_token": "string" }`
- **Response**: `{ "data": { "access_token": "string", "refresh_token": "string" } }`

### 1.4 退出登录
- **POST** `/api/v1/auth/logout`
- **Headers**: 需认证
- **Response**: `{ "code": 0 }`

---

## 2. 用户模块

### 2.1 获取当前用户信息
- **GET** `/api/v1/users/me`
- **Headers**: 需认证
- **Response**:
```json
{
  "code": 0,
  "data": {
    "id": "string",
    "uuid": "string",
    "nickname": "string",
    "avatar_url": "string|null",
    "role": 1,
    "bio": "string|null",
    "city": "string|null",
    "is_verified": false,
    "credit_score": 500,
    "level": 1,
    "total_orders": 0,
    "completed_orders": 0,
    "completion_rate": 0.0,
    "avg_rating": 0.0,
    "hourly_rate": null,
    "available_status": 1,
    "skills": [],
    "role_tags": []
  }
}
```

### 2.2 更新用户信息
- **PUT** `/api/v1/users/me`
- **Headers**: 需认证
- **Body**: 任意用户字段子集, 如 `{ "role": 1, "nickname": "张三" }`
- **Response**: `{ "code": 0, "message": "更新成功" }`

---

## 3. 项目模块

### 3.1 获取项目列表
- **GET** `/api/v1/projects`
- **Query**: `?page=1&page_size=20&category=app&sort=latest`
- **Headers**: 需认证
- **Response**:
```json
{
  "code": 0,
  "data": [
    {
      "id": "string",
      "uuid": "string",
      "owner_id": "string",
      "title": "string",
      "description": "string",
      "category": "app|web|miniprogram|design|data|consult",
      "budget_min": 3000,
      "budget_max": 8000,
      "progress": 68,
      "status": 5,
      "tech_requirements": ["Flutter", "GPT-4"],
      "view_count": 126,
      "bid_count": 5,
      "created_at": "2026-03-15T10:00:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 2, "total_pages": 1 }
}
```

### 3.2 创建项目
- **POST** `/api/v1/projects`
- **Headers**: 需认证
- **Body**:
```json
{
  "title": "string",
  "description": "string",
  "category": "app",
  "budget_min": 3000,
  "budget_max": 8000,
  "tech_requirements": ["Flutter"],
  "complexity": "medium"
}
```
- **Response**: `{ "code": 0, "data": { "id": "string", "uuid": "string" } }`

---

## 4. 首页聚合模块

### 4.1 需求方首页数据
- **GET** `/api/v1/home/demander`
- **Headers**: 需认证
- **Response**:
```json
{
  "code": 0,
  "data": {
    "ai_prompt": "string (AI 入口提示文案)",
    "categories": [
      {
        "key": "app|web|miniprogram|design|data|consult",
        "name": "string",
        "icon": "string (Material Icon name)",
        "count": 128
      }
    ],
    "my_projects": [
      {
        "id": "string",
        "uuid": "string",
        "owner_id": "string",
        "title": "string",
        "description": "string",
        "category": "string",
        "budget_min": 3000,
        "budget_max": 8000,
        "progress": 68,
        "status": 5,
        "tech_requirements": ["Flutter"],
        "view_count": 126,
        "bid_count": 5,
        "created_at": "2026-03-15T10:00:00Z"
      }
    ],
    "recommended_experts": [
      {
        "id": "string",
        "nickname": "string",
        "avatar_url": "string|null",
        "rating": 4.9,
        "skill": "string (主要技能)",
        "hourly_rate": 300,
        "completed_orders": 23
      }
    ]
  }
}
```

### 4.2 专家首页数据
- **GET** `/api/v1/home/expert`
- **Headers**: 需认证
- **Response**:
```json
{
  "code": 0,
  "data": {
    "revenue": {
      "total_income": 28500.0,
      "month_income": 6800.0,
      "pending_income": 3200.0,
      "trend": 12.5
    },
    "recommended_demands": [
      {
        "id": "string",
        "uuid": "string",
        "owner_id": "string",
        "title": "string",
        "description": "string",
        "category": "string",
        "budget_min": 8000,
        "budget_max": 15000,
        "match_score": 92,
        "status": 2,
        "tech_requirements": ["Flutter", "WebRTC"],
        "view_count": 56,
        "bid_count": 2,
        "created_at": "2026-03-20T09:00:00Z"
      }
    ],
    "skill_heat": [
      { "name": "Flutter", "heat": 95 }
    ],
    "team_opportunities": [
      {
        "id": "string",
        "project_title": "string",
        "needed_role": "string",
        "team_size": 5,
        "budget": 50000
      }
    ]
  }
}
```
- **说明**: `revenue.trend` 为百分比涨跌幅，正值为增长; `skill_heat.heat` 取值 0-100; `match_score` 为 AI 匹配度百分比

---

## 5. 需求广场模块

### 5.1 获取需求广场列表
- **GET** `/api/v1/market/projects`
- **Query**:
  - `page` (int, default 1) — 页码
  - `page_size` (int, default 10) — 每页条数
  - `category` (string, optional) — 分类筛选: `app|web|miniprogram|design|data|consult`，为空或 `all` 时不筛选
  - `sort` (string, default `latest`) — 排序: `latest` 最新 / `budget_desc` 预算降序 / `match` 匹配度降序
  - `budget_min` (double, optional) — 预算最低值
  - `budget_max` (double, optional) — 预算最高值
- **Headers**: 需认证
- **Response**:
```json
{
  "code": 0,
  "data": [
    {
      "id": "string",
      "uuid": "string",
      "owner_id": "string",
      "owner_name": "string",
      "title": "string",
      "description": "string",
      "category": "app",
      "budget_min": 8000,
      "budget_max": 15000,
      "match_score": 92,
      "status": 2,
      "tech_requirements": ["Flutter", "WebRTC"],
      "view_count": 56,
      "bid_count": 2,
      "created_at": "2026-03-20T09:00:00Z"
    }
  ],
  "meta": { "page": 1, "page_size": 10, "total": 15, "total_pages": 2 }
}
```
- **说明**: 返回状态为"已发布(2)"的项目; `match_score` 为基于当前用户技能匹配的百分比（后端可选实现，前端容错为 null）

### 5.2 获取项目详情
- **GET** `/api/v1/projects/:id`
- **Headers**: 需认证
- **Response**:
```json
{
  "code": 0,
  "data": {
    "id": "string",
    "uuid": "string",
    "owner_id": "string",
    "owner_name": "string",
    "title": "string",
    "description": "string",
    "category": "string",
    "budget_min": 8000,
    "budget_max": 15000,
    "match_score": 92,
    "status": 2,
    "tech_requirements": ["Flutter", "WebRTC"],
    "view_count": 56,
    "bid_count": 2,
    "created_at": "2026-03-20T09:00:00Z",
    "prd_summary": "string (PRD 摘要文本)",
    "milestones": [
      {
        "id": "string",
        "title": "string",
        "status": "completed|in_progress|pending",
        "progress": 100
      }
    ]
  }
}
```
- **说明**: `prd_summary` 为AI生成的PRD摘要; `milestones` 为里程碑列表，Phase 3 完善详细里程碑功能

---

## 后续迭代接口（Phase 3+）

以下接口将在后续阶段补充 Mock 和规范：

- `GET /api/v1/projects/search` — 项目搜索
- `GET /api/v1/projects/:id/bids` — 投标列表
- `POST /api/v1/projects/:id/bids` — 提交投标
- `GET /api/v1/conversations` — 会话列表
- `GET /api/v1/conversations/:id/messages` — 消息列表
- `GET /api/v1/users/:id/profile` — 用户主页
- `POST /api/v1/orders` — 创建订单
- `GET /api/v1/wallet/balance` — 钱包余额
- `POST /api/v1/agent-sessions` — AI Agent 会话
- `GET /api/v1/income/summary` — 收入详情

---

## 6. 需求发布模块 (Phase 3)

### 6.1 AI 对话

- **POST** `/api/v1/projects/ai-chat`
- **描述**: 与 AI 对话梳理需求
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| message | string | Y | 用户消息内容 |
| category | string | N | 已选分类 |

- **Response**:

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "reply": "AI回复内容...",
    "can_generate_prd": false,
    "turn": 1
  }
}
```

### 6.2 生成 PRD

- **POST** `/api/v1/projects/generate-prd`
- **描述**: 基于 AI 对话生成 PRD 文档
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | Y | 项目分类 |
| chat_history | array | Y | 对话历史 [{role, content}] |

- **Response**:

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "prd_id": "prd_001",
    "title": "项目 PRD",
    "modules": [
      {
        "id": "mod_auth",
        "name": "认证模块",
        "cards": [
          {
            "id": "card_001",
            "module_id": "mod_auth",
            "title": "手机号登录",
            "type": "event",
            "priority": "P0",
            "description": "...",
            "event": "...",
            "action": "...",
            "response": "...",
            "state_change": "...",
            "acceptance_criteria": [
              {"id": "ac_001", "content": "...", "checked": false}
            ],
            "roles": ["frontend", "backend"],
            "effort_hours": 8,
            "dependencies": [],
            "tech_tags": ["Flutter", "SMS SDK"],
            "status": "pending"
          }
        ]
      }
    ],
    "budget_suggestion": {
      "min": 5000,
      "max": 15000,
      "reason": "基于项目复杂度..."
    }
  }
}
```

### 6.3 保存草稿

- **POST** `/api/v1/projects/draft`
- **描述**: 保存需求发布草稿
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | N | 项目分类 |
| budget_min | number | N | 预算下限 |
| budget_max | number | N | 预算上限 |
| match_mode | string | N | 撮合模式: ai/manual/invite |
| step | int | N | 当前步骤 |

- **Response**:

```json
{
  "code": 0,
  "message": "草稿已保存",
  "data": {
    "draft_id": "draft_001",
    "saved_at": "2026-03-20T10:00:00Z"
  }
}
```

### 6.4 发布项目

- **POST** `/api/v1/projects`
- **描述**: 发布新项目需求
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | Y | 项目分类 |
| prd_id | string | Y | PRD 文档 ID |
| budget_min | number | Y | 预算下限 |
| budget_max | number | Y | 预算上限 |
| match_mode | string | Y | 撮合模式: ai/manual/invite |

- **Response**:

```json
{
  "code": 0,
  "message": "项目发布成功",
  "data": {
    "id": "proj_001",
    "uuid": "proj_uuid_001",
    "status": 2
  }
}
```

## 7. PRD 文档模块 (Phase 3)

### 7.1 获取 PRD 数据

- **GET** `/api/v1/projects/:id/prd`
- **描述**: 获取项目的完整 PRD 文档数据
- **Response**:

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "prd_id": "prd_001",
    "project_id": "proj_001",
    "title": "项目 PRD",
    "version": "1.0",
    "created_at": "2026-03-20T10:00:00Z",
    "modules": [
      {
        "id": "mod_auth",
        "name": "认证模块",
        "icon": "lock",
        "order": 1,
        "cards": [
          {
            "id": "card_001",
            "module_id": "mod_auth",
            "title": "手机号登录",
            "type": "event",
            "priority": "P0",
            "description": "...",
            "event": "...",
            "action": "...",
            "response": "...",
            "state_change": "...",
            "acceptance_criteria": [
              {"id": "ac_001", "content": "手机号格式校验", "checked": true}
            ],
            "roles": ["frontend", "backend"],
            "effort_hours": 8,
            "dependencies": [],
            "tech_tags": ["Flutter", "SMS SDK"],
            "status": "in_progress"
          }
        ]
      }
    ]
  }
}
```

### 7.2 更新 EARS 卡片状态

- **PUT** `/api/v1/projects/:id/prd/cards/:cardId`
- **描述**: 更新 EARS 卡片验收标准勾选状态
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| criteria_id | string | Y | 验收标准 ID |

- **Response**:

```json
{
  "code": 0,
  "message": "更新成功",
  "data": {
    "criteria_id": "ac_001"
  }
}
```

---

## 8. 投标/撮合模块 (Phase 4)

### 8.1 获取投标列表

- **GET** `/api/v1/projects/:projectId/bids`
- **描述**：获取指定项目的所有投标
- **响应**：

```json
{
  "code": 0,
  "data": [
    {
      "id": "bid_001",
      "user_id": "user_201",
      "user_name": "张开发",
      "avatar": null,
      "rating": 4.9,
      "completion_rate": 98,
      "match_score": 95,
      "bid_amount": 5000,
      "duration_days": 14,
      "proposal": "拥有5年Flutter开发经验...",
      "bid_type": "personal|team",
      "team_name": null,
      "team_members": [{"name": "王前端", "role": "前端开发"}],
      "is_ai_recommended": true,
      "skills": ["Flutter", "Go"],
      "created_at": "2026-03-20T10:00:00Z"
    }
  ]
}
```

### 8.2 提交投标

- **POST** `/api/v1/projects/:projectId/bids`
- **描述**：供给方提交投标
- **请求体**：

```json
{
  "amount": 5000,
  "duration_days": 14,
  "proposal": "方案描述",
  "bid_type": "personal|team",
  "team_id": "team_001"
}
```

- **响应**：

```json
{
  "code": 0,
  "message": "投标成功",
  "data": { "bid_id": "bid_new_001", "status": "submitted" }
}
```

### 8.3 接受投标

- **POST** `/api/v1/bids/:bidId/accept`
- **描述**：需求方选定供给方
- **响应**：

```json
{
  "code": 0,
  "message": "已选定供给方",
  "data": { "status": "accepted" }
}
```

### 8.4 AI 投标建议

- **GET** `/api/v1/projects/:projectId/ai-suggestion`
- **描述**：获取 AI 基于项目分析的报价/工期建议
- **响应**：

```json
{
  "code": 0,
  "data": {
    "suggested_price_min": 4000,
    "suggested_price_max": 8000,
    "suggested_duration_days": 14,
    "skill_match_score": 85,
    "reason": "基于项目复杂度和市场行情..."
  }
}
```

---

## 9. 项目管理模块 (Phase 4)

### 9.1 获取项目任务列表（看板）

- **GET** `/api/v1/projects/:projectId/tasks`
- **描述**：获取项目下所有任务（看板三列）
- **响应**：

```json
{
  "code": 0,
  "data": [
    {
      "id": "t1",
      "title": "用户认证模块",
      "description": "实现手机号登录和JWT认证",
      "status": "todo|in_progress|completed",
      "priority": "P0|P1|P2",
      "assignee": "张开发",
      "milestone_id": "m1",
      "effort_hours": 8,
      "is_at_risk": false,
      "created_at": "2026-03-15T10:00:00Z",
      "completed_at": null
    }
  ]
}
```

### 9.2 更新任务状态

- **PUT** `/api/v1/tasks/:taskId/status`
- **描述**：更新任务状态（拖拽、标记完成）
- **请求体**：

```json
{ "status": "in_progress" }
```

- **响应**：

```json
{
  "code": 0,
  "message": "状态已更新",
  "data": { "status": "in_progress" }
}
```

### 9.3 获取里程碑列表

- **GET** `/api/v1/projects/:projectId/milestones`
- **描述**：获取项目里程碑时间轴数据
- **响应**：

```json
{
  "code": 0,
  "data": [
    {
      "id": "m1",
      "title": "需求确认 & 基础框架",
      "status": "completed|in_progress|pending",
      "progress": 100,
      "due_date": "2026-03-17",
      "amount": 1500,
      "task_count": 2,
      "completed_task_count": 2
    }
  ]
}
```

### 9.4 获取 AI 日报

- **GET** `/api/v1/projects/:projectId/daily-reports`
- **描述**：获取 AI 自动生成的项目日报列表
- **响应**：

```json
{
  "code": 0,
  "data": [
    {
      "id": "rpt_001",
      "date": "2026-03-22",
      "summary": "今日完成了首页UI骨架搭建...",
      "completed_tasks": ["t2"],
      "in_progress_tasks": ["t3", "t4"],
      "risk_items": ["t4 — 可能延期1天"],
      "tomorrow_plan": "继续推进需求广场页面"
    }
  ]
}
```

---

## Phase 5：CHAT + ACCP + PAY 模块接口

> v5.0 — 新增 10 个接口

### 5.1 获取会话列表

- **路径**：`GET /api/v1/conversations`
- **鉴权**：Bearer Token
- **描述**：获取当前用户的所有聊天会话列表
- **响应**：

```json
{
  "code": 0,
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
  ]
}
```

### 5.2 获取会话消息列表

- **路径**：`GET /api/v1/conversations/:id/messages`
- **鉴权**：Bearer Token
- **查询参数**：`before`(分页游标), `limit`(默认20)
- **描述**：获取某个会话的聊天消息
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

- **路径**：`POST /api/v1/conversations/:id/messages`
- **鉴权**：Bearer Token
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

- **路径**：`POST /api/v1/conversations/:id/read`
- **鉴权**：Bearer Token
- **响应**：`{ "code": 0, "message": "ok" }`

### 5.5 删除会话

- **路径**：`DELETE /api/v1/conversations/:id`
- **鉴权**：Bearer Token
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

## 8. PROF — 个人资料模块 (v6.0 新增)

### 8.1 GET /api/v1/users/:id — 获取用户资料

**请求参数**: Path 参数 `id`

**响应**:
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "user_001",
    "nickname": "张恒",
    "avatar": null,
    "tagline": "全栈 Vibe Coder",
    "role": 1,
    "rating": 4.9,
    "credit_score": 920,
    "is_verified": true,
    "phone": "138****8888",
    "wechat_bound": true,
    "stats": {
      "completed_projects": 12,
      "approval_rate": 98,
      "avg_delivery_days": 3.2,
      "total_earnings": 86500.0
    },
    "bio": "5年全栈开发经验...",
    "created_at": "2025-06-15T10:00:00Z"
  }
}
```

### 8.2 GET /api/v1/users/me — 获取当前登录用户

同 8.1 结构，返回当前 JWT 对应用户资料。

### 8.3 PUT /api/v1/users/:id — 更新资料

**请求体**:
```json
{
  "nickname": "新昵称",
  "tagline": "一句话介绍",
  "bio": "个人简介"
}
```

**响应**: `{ "code": 0, "message": "资料更新成功", "data": {...} }`

### 8.4 GET /api/v1/users/:id/skills — 获取技能标签

**响应**:
```json
{
  "code": 0,
  "data": [
    { "id": "skill_01", "name": "Flutter", "category": "mobile" }
  ]
}
```

### 8.5 PUT /api/v1/users/:id/skills — 更新技能标签

**请求体**: `{ "skills": [{ "id": "...", "name": "Flutter", "category": "mobile" }] }`

**响应**: `{ "code": 0, "message": "技能更新成功" }`

### 8.6 GET /api/v1/users/:id/portfolios — 获取作品集

**响应**:
```json
{
  "code": 0,
  "data": [
    {
      "id": "pf_01",
      "title": "智能客服系统",
      "cover_url": "https://...",
      "description": "基于 GPT-4 的多轮对话客服系统",
      "tags": ["Flutter", "AI", "WebSocket"],
      "created_at": "2026-01-15T10:00:00Z"
    }
  ]
}
```

---

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

## 10. TEAM — 组队系统模块 (v7.0 新增)

### 10.1 GET /api/v1/teams — 组队大厅列表

**Query 参数**: `role` (可选，角色名过滤)

**响应**:
```json
{
  "code": 0,
  "data": {
    "ai_recommended": [{ "...TeamPost..." }],
    "posts": [
      {
        "id": "tp_001",
        "project_name": "智能客服系统 v2.0",
        "project_id": "proj_001",
        "creator": { "id": "user_002", "nickname": "李开发", "avatar": null },
        "needed_roles": [
          { "name": "Flutter开发", "ratio": 40, "filled": true },
          { "name": "后端开发", "ratio": 35, "filled": false }
        ],
        "description": "寻找后端同学组队...",
        "filled_count": 1,
        "total_count": 3,
        "is_ai_recommended": true,
        "match_score": 92,
        "status": "recruiting",
        "created_at": "2026-03-22T10:00:00Z"
      }
    ]
  }
}
```

### 10.2 POST /api/v1/team-posts — 发布寻人帖

**请求体**:
```json
{
  "project_name": "项目名",
  "description": "描述",
  "needed_roles": [
    { "name": "Flutter开发", "ratio": 40 },
    { "name": "后端开发", "ratio": 35 },
    { "name": "UI设计", "ratio": 25 }
  ]
}
```

**响应**: `{ "code": 0, "message": "寻人帖发布成功", "data": { "id": "tp_xxx", "status": "recruiting" } }`

### 10.3 GET /api/v1/teams/:id — 获取组队详情

**响应**:
```json
{
  "code": 0,
  "data": {
    "id": "team_001",
    "project_name": "智能客服系统 v2.0",
    "project_id": "proj_001",
    "status": "confirming",
    "members": [
      {
        "id": "user_002",
        "nickname": "李开发",
        "role": "Flutter开发",
        "ratio": 40,
        "is_leader": true,
        "status": "accepted"
      }
    ]
  }
}
```

### 10.4 PUT /api/v1/teams/:id/split-ratio — 调整分成比例

**请求体**: `{ "ratios": [{ "member_id": "user_002", "ratio": 40 }] }`

**响应**: `{ "code": 0, "message": "分成比例已更新" }`

### 10.5 POST /api/v1/teams/:id/invite — 确认组队

**响应**: `{ "code": 0, "message": "组队确认成功，已通知所有成员" }`

### 10.6 POST /api/v1/team-invites/:id — 响应邀请

**请求体**: `{ "accept": true }`

**响应**: `{ "code": 0, "message": "已接受邀请" }`

---

## 11. RATE — 评价系统模块 (v7.0 新增)

### 11.1 POST /api/v1/reviews — 提交评价

**请求体**:
```json
{
  "project_id": "proj_001",
  "reviewee_id": "user_002",
  "overall_rating": 4.5,
  "dimensions": [
    { "name": "代码质量", "rating": 5.0 },
    { "name": "沟通效率", "rating": 4.0 },
    { "name": "交付时效", "rating": 4.5 }
  ],
  "comment": "非常专业的开发者..."
}
```

**响应**: `{ "code": 0, "message": "评价提交成功", "data": { "review_id": "rev_xxx" } }`

### 11.2 GET /api/v1/projects/:id/reviews — 获取项目评价

**响应**:
```json
{
  "code": 0,
  "data": [
    {
      "id": "rev_001",
      "reviewer": { "id": "user_001", "nickname": "张恒", "role": "demander" },
      "reviewee": { "id": "user_002", "nickname": "李开发", "role": "expert" },
      "overall_rating": 4.5,
      "dimensions": [
        { "name": "代码质量", "rating": 5.0 },
        { "name": "沟通效率", "rating": 4.0 }
      ],
      "comment": "非常专业的开发者...",
      "created_at": "2026-03-20T10:00:00Z"
    }
  ]
}
```
