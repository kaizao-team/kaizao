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
    "contact_phone": "138****8888",
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

与 **§2.1** 一致（含 `onboarding_status`、`skills`、`hourly_rate` 等工作台字段）。**§8.1** 描述的是**对外公开资料**（`GET /users/:id`），字段集合不同，勿混用。

### 8.3 PUT /api/v1/users/:id — 更新资料

**请求体**（均为可选，但至少传一项；`tagline` 与 `bio` 均映射到用户 `bio`，以后端实现为准）:
```json
{
  "nickname": "新昵称",
  "tagline": "一句话介绍",
  "bio": "个人简介",
  "contact_phone": "13800138000"
}
```

**响应 `data`**:
```json
{
  "id": "user_uuid",
  "nickname": "新昵称",
  "bio": "个人简介"
}
```

### 8.4 GET /api/v1/users/:id/skills — 获取技能标签

**响应**（`data` 为数组；`id` 一般为词库技能整型 ID）:
```json
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "skill_id": 1,
      "name": "Flutter",
      "category": "mobile",
      "proficiency": 4,
      "years_of_experience": 3,
      "is_primary": true
    }
  ]
}
```

### 8.5 PUT /api/v1/users/:id/skills — 更新技能标签

**路径别名**：`PUT /api/v1/users/me/skills`（当前登录用户，与 `PUT /users/:id/skills` 等价语义）。

**请求体**（`skills` 必填，最多 20 条；`id` 可为字符串或数字，与 `skill_id` 二选一用于关联词库技能）:
```json
{
  "skills": [
    {
      "skill_id": 1,
      "name": "Flutter",
      "category": "mobile",
      "proficiency": 4,
      "years_of_experience": 3,
      "is_primary": true
    }
  ]
}
```

**响应**: `{ "code": 0, "message": "技能更新成功" }`

### 8.6 GET /api/v1/users/:id/portfolios — 获取作品集

**路径**：`GET /api/v1/users/me/portfolios` 为当前用户作品列表（字段结构相同）。

**响应**（单项还可含 `category`、`tech_stack`、`preview_url`、`demo_video_url`、`images[]`（`url`/`caption`）等）:
```json
{
  "code": 0,
  "data": [
    {
      "id": "pf_01",
      "title": "智能客服系统",
      "cover_url": "https://example.com/cover.png",
      "description": "基于 GPT-4 的多轮对话客服系统",
      "category": "app",
      "tags": ["Flutter", "AI", "WebSocket"],
      "tech_stack": ["Flutter", "AI", "WebSocket"],
      "created_at": "2026-01-15T10:00:00Z"
    }
  ]
}
```

### 8.7 作品集写操作（当前用户）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/users/me/portfolios` | **Body**：`title`（必填）、`description`、`category`（`app\|web\|miniprogram\|design\|data\|other`，缺省 `other`）、`cover_url`、`preview_url`、`tech_stack`（字符串数组）、`images`（`{url,caption}[]`）、`demo_video_url`。成功 `data`：`id`、`title`。 |
| PUT | `/api/v1/users/me/portfolios/:uuid` | **Body**：上述字段均可选；`tech_stack`/`images` 传 `null` 表示不更新该类字段。 |
| DELETE | `/api/v1/users/me/portfolios/:uuid` | 删除本人作品 |

---
