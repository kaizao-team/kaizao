## 4. 首页聚合模块

### 4.1 需求方首页数据
- **GET** `/api/v1/home/demander`
- **Headers**: 需认证
- **`categories`**：固定 **4** 项，`key` / `name` / `icon` 与 **通用约定 — 项目分类枚举** 表一致；**`count`** 为当前库中 **已发布（`status = 2`）** 且 `category = key` 的项目数量。
- **Response**:
```json
{
  "code": 0,
  "data": {
    "ai_prompt": "string (AI 入口提示文案)",
    "categories": [
      { "key": "data", "name": "数据", "icon": "bar_chart", "count": 12 },
      { "key": "dev", "name": "研发", "icon": "code", "count": 45 },
      { "key": "visual", "name": "视觉设计", "icon": "brush", "count": 8 },
      { "key": "solution", "name": "解决方案", "icon": "lightbulb", "count": 20 }
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
        "id": "string (团队UUID)",
        "leader_uuid": "string (队长用户UUID)",
        "nickname": "string (队长昵称)",
        "avatar_url": "string|null (队长头像)",
        "rating": 4.9,
        "skill": "string (队长主要技能)",
        "hourly_rate": 300,
        "budget_min": 5000,
        "budget_max": 20000,
        "completed_orders": 23,
        "vibe_level": "vc-T1",
        "vibe_power": 0,
        "member_count": 3
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
