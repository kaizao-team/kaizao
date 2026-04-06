## 3. 项目模块

### 3.1 获取项目列表
- **GET** `/api/v1/projects`
- **Query**: `?page=1&page_size=20&category=dev&sort=latest`
- **Headers**: 需认证
- **`category`（可选）**：按 `projects.category` 精确筛选，取值见 **通用约定 — 项目分类枚举**；建议仅传 `data` \| `dev` \| `visual` \| `solution`。数据清洗后库内不再存在旧枚举字符串，传旧值时列表可能为空。
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
      "category": "data|dev|visual|solution",
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
  "category": "dev",
  "budget_min": 3000,
  "budget_max": 8000,
  "tech_requirements": ["Flutter"],
  "complexity": "medium"
}
```
- **`category`（必填）**：仅允许 `data` \| `dev` \| `visual` \| `solution`；传入 `app`、`web` 等旧枚举返回 **400**（参数校验失败）。与 **§6.4** 发布项目、`CreateProjectReq` 一致。
- **Response**: `{ "code": 0, "data": { "id": "string", "uuid": "string" } }`

### 3.3 更新项目
- **PUT** `/api/v1/projects/:id`
- **Headers**: 需认证（项目所有者）
- **Body**：可更新字段子集；**`category`（可选）**：若传入，须为 `data` \| `dev` \| `visual` \| `solution` 之一，旧值 **400**。
- **Response**：以实现为准（常见为 `{ "code": 0, "message": "ok" }` 或含更新后项目摘要）。

---
