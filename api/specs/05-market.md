## 5. 需求广场模块

### 5.1 获取需求广场列表
- **GET** `/api/v1/market/projects`
- **Query**:
  - `page` (int, default 1) — 页码
  - `page_size` (int, default 10) — 每页条数
  - `category` (string, optional) — 分类筛选：与项目入库字段一致，取值 `data` \| `dev` \| `visual` \| `solution`；为空或 `all` 时不筛选。建议勿再传旧 6 类字符串；数据清洗后旧键不存在，筛选结果可能为空。
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
      "category": "dev",
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

### 5.1b 专家广场列表（团队维度）
- **GET** `/api/v1/market/experts`
- **Query**: `page`（int, default 1）、`page_size`（int, default 20, max 50）
- **Headers**: 可选认证（`OptionalJWTAuth`）
- **Response**:
```json
{
  "code": 0,
  "data": [
    {
      "id": "string (团队UUID)",
      "leader_uuid": "string (队长用户UUID)",
      "team_name": "string",
      "vibe_level": "vc-T1",
      "vibe_power": 0,
      "member_count": 3,
      "rating": 4.9,
      "hourly_rate": 300,
      "budget_min": 5000,
      "budget_max": 20000,
      "nickname": "string (队长昵称)",
      "avatar_url": "string|null (队长头像)",
      "completed_projects": 23,
      "tagline": "string|null (队长简介)",
      "skills": ["Flutter", "Go"]
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 5, "total_pages": 1 }
}
```
- **说明**：以 **团队** 为主实体，查 `teams` 表（`status=1 AND available_status=1`），且 **队长**须为已通过入驻的专家（`users.role IN (2,3)`、`onboarding_status=2`），与旧版「专家用户列表」准入一致；按 `vibe_power DESC, avg_rating DESC` 排序。`nickname`、`avatar_url`、`skills` 等来自团队 leader。**`hourly_rate`** 为咨询单价（元/小时）；**`budget_min` / `budget_max`** 为团队接单意向预算区间（元），仅存团队。**收藏专家**（**§2.5**）时 `target_id` 直接传团队 `id`（团队 UUID），后端以团队 UUID 存储。

### 5.2 获取项目详情
- **GET** `/api/v1/projects/:id`
- **Headers**: 可选认证（`OptionalJWTAuth`）
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
    "prd_summary": "本项目旨在构建一个跨平台移动应用...",
    "milestones": [
      {
        "id": "ms_001",
        "title": "需求确认与原型设计",
        "status": "completed",
        "progress": 100,
        "due_date": "2026-04-15T00:00:00Z",
        "amount": 3000.00
      },
      {
        "id": "ms_002",
        "title": "核心功能开发",
        "status": "in_progress",
        "progress": 50,
        "due_date": "2026-05-01T00:00:00Z",
        "amount": 5000.00
      }
    ],
    "my_bid_status": "pending"
  }
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `prd_summary` | string | PRD 摘要文本；优先取 `confirmed_prd.summary`，其次 `ai_prd.summary`，均无则为空字符串 |
| `milestones` | array | 项目里程碑列表，从数据库实际查询；无里程碑时返回空数组 `[]` |
| `milestones[].id` | string | 里程碑 UUID |
| `milestones[].title` | string | 里程碑标题 |
| `milestones[].status` | string | 状态：`pending`(1) / `in_progress`(2) / `completed`(3) / `revision_requested`(4) / `delivered`(5) |
| `milestones[].progress` | int | 进度百分比：completed=100, delivered=90, in_progress=50, pending=0 |
| `milestones[].due_date` | string\|null | 截止日期 |
| `milestones[].amount` | number\|null | 里程碑金额 |
| `my_bid_status` | string\|null | 当前登录用户对该项目的投标状态；`omitempty`，未登录或未投标时不返回此字段。值为 `pending` / `accepted` / `rejected` / `withdrawn` |

- **说明**: `prd_summary` 从项目的 `confirmed_prd` 或 `ai_prd` JSON 字段中提取 `summary` 键值；`milestones` 从 `milestones` 表实际查询；`my_bid_status` 仅在已登录用户对该项目有投标记录时出现，供前端判断"发起投标"或"已投标"按钮状态

---
