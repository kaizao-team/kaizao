## 10. TEAM — 组队系统模块 (v7.0 新增)

### 10.1 GET /api/v1/teams — 组队大厅列表

**Query 参数**: `role`（可选；当前列表实现侧预留过滤，以服务端为准）

**说明**：`GET /api/v1/team-posts` 与本接口共用同一 Handler，响应结构一致。

**响应 `data`**:
```json
{
  "ai_recommended": [],
  "posts": [
    {
      "id": "寻人帖UUID",
      "project_name": "智能客服系统 v2.0",
      "project_id": "",
      "creator": { "id": "user_002", "nickname": "李开发", "avatar": null },
      "needed_roles": [
        { "name": "Flutter开发", "ratio": 40 },
        { "name": "后端开发", "ratio": 35 }
      ],
      "description": "寻找后端同学组队，熟悉 Go 与微服务",
      "filled_count": 0,
      "total_count": 2,
      "is_ai_recommended": false,
      "match_score": 0,
      "status": "recruiting",
      "created_at": "2026-03-22T10:00:00Z"
    }
  ]
}
```

- `ai_recommended`：当前实现多为空数组，占位供后续 AI 推荐。
- `needed_roles`：JSON 结构由发布帖时写入，可含 `name`、`ratio`、`filled` 等键，以后端存表为准。

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

### 10.3 GET /api/v1/teams/:uuid — 获取组队/团队详情

**Headers**: 可选认证（`OptionalJWTAuth`）

**响应**:
```json
{
  "code": 0,
  "data": {
    "id": "team_001",
    "team_name": "极速开发工作室",
    "project_name": "极速开发工作室",
    "project_id": "proj_001",
    "status": "active",
    "description": "专注移动端开发的高效团队",
    "avatar_url": "https://example.com/avatar.png",
    "vibe_level": "vc-T3",
    "vibe_power": 850,
    "hourly_rate": 300.00,
    "budget_min": 5000.00,
    "budget_max": 20000.00,
    "avg_rating": 4.85,
    "member_count": 3,
    "total_projects": 12,
    "available_status": 1,
    "experience_years": 5,
    "resume_summary": "团队在移动开发领域有丰富经验",
    "leader_uuid": "user_002",
    "nickname": "李开发",
    "leader_avatar_url": "https://example.com/leader.png",
    "completed_projects": 23,
    "tagline": "全栈开发，专注品质",
    "skills": ["Flutter", "Go", "React"],
    "created_at": "2026-03-01T10:00:00Z",
    "members": [
      {
        "id": 1,
        "user_id": "user_002",
        "nickname": "李开发",
        "avatar_url": "https://example.com/leader.png",
        "role": "Flutter开发",
        "ratio": 40,
        "is_leader": true,
        "status": "accepted"
      }
    ]
  }
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 团队 UUID |
| `team_name` | string | 团队名称（同 `project_name`） |
| `description` | string\|null | 团队简介 |
| `avatar_url` | string\|null | 团队头像 URL |
| `vibe_level` | string | 等级标识，如 `vc-T1` ~ `vc-T5` |
| `vibe_power` | int | 能力值分数 |
| `hourly_rate` | number\|null | 咨询单价 / 时薪（元/小时） |
| `budget_min` | number\|null | 团队接单意向预算下限（元），仅存 `teams` 表 |
| `budget_max` | number\|null | 团队接单意向预算上限（元），仅存 `teams` 表 |
| `avg_rating` | number | 平均评分（0.00 ~ 5.00） |
| `member_count` | int | 团队成员数 |
| `total_projects` | int | 历史项目总数 |
| `available_status` | int | 接单状态：1=接单中，0=暂停 |
| `experience_years` | int | 经验年限 |
| `resume_summary` | string\|null | 团队/队长简历摘要 |
| `leader_uuid` | string | 队长用户 UUID |
| `nickname` | string | 队长昵称 |
| `leader_avatar_url` | string\|null | 队长头像 |
| `completed_projects` | int | 队长已完成订单数 |
| `tagline` | string\|null | 队长签名/简介 |
| `skills` | string[] | 队长技能名称列表 |
| `members[].user_id` | string | 成员用户 UUID |
| `members[].avatar_url` | string\|null | 成员头像 |

### 10.3.1 POST `/api/v1/teams/:uuid/static-assets` — 上传团队静态文件（MinIO）

- **Headers**: 需认证；**队长或团队成员**可传。
- **Content-Type**: `multipart/form-data`
- **表单字段**:
  - `file`（必填）文件本体；
  - `purpose`（可选）业务用途，默认 `content`。
- **存储**：文件写入 **MinIO**（或 S3 兼容），元数据写入表 **`team_static_assets`**（桶名、`object_key`、原名、大小、类型等）。
- **响应 `data`**：`id`（资产 UUID）、`url`（依赖 `oss.base_url` 拼接）、`object_key`、`original_name`、`content_type`、`size_bytes`、`purpose`、`created_at`。
- **配置**：`oss.enabled=true` 且配置 `endpoint`（如 `minio:9000`）、`access_key_id`、`access_key_secret`、`bucket_name`；`oss.max_upload_mb` 限制单文件大小。
- **错误码**：`11013` 对象存储未启用；`11014` 文件过大；`11015` 非团队成员；`11016` 上传失败；`11017` 空文件。

### 10.3.2 GET `/api/v1/teams/:uuid/static-assets` — 团队静态文件元数据列表

- **Headers**: 需认证；队长或成员。
- **Query**: `page`, `page_size`
- **响应**: 分页列表，每项含 `id`、`url`、`object_key`、`original_name`、`content_type`、`size_bytes`、`purpose`、`uploaded_by_id`、`created_at`。

### 10.4 PUT /api/v1/teams/:uuid/split-ratio — 调整分成比例

**请求体**: `{ "ratios": [{ "member_id": "user_002", "ratio": 40 }] }`

**响应**: `{ "code": 0, "message": "分成比例已更新" }`

### 10.5 POST /api/v1/teams/:uuid/invite — 确认组队

**响应**: `{ "code": 0, "message": "组队确认成功，已通知所有成员" }`（路径参数为团队 **UUID**，与 **10.3.1** 一致）

### 10.6 POST /api/v1/team-invites/:id — 响应邀请

**路径参数**：`:id` 为**邀请记录 UUID**（路由参数名固定为 `id`）。

**请求体**: `{ "accept": true }`

**响应**: `{ "code": 0, "message": "已接受邀请" }` 或 `已拒绝邀请`

### 10.7 POST /api/v1/teams — 创建团队

- **Headers**: 需认证。
- **前置条件**：当前用户**无已有主团队**。若用户角色非专家/团队方（即 `role` 不为 2 或 3），服务端会在同一事务内自动将 `role` 提升为 **2**（专家）。
- **请求体**:
```json
{
  "name": "我的团队",
  "hourly_rate": 200.00,
  "available_status": 1,
  "budget_min": 5000.00,
  "budget_max": 20000.00,
  "description": "团队简介",
  "invite_code": "KZ-ABCD1234"
}
```
- **字段说明**：所有字段均可选。`name` 省略时默认为「{昵称}的团队」。`available_status` 省略时默认为 `1`（接单中）。`budget_max` 须 >= `budget_min`（若均非空）。
- **`invite_code`（可选）**：管理端发放的邀请码。传入有效邀请码时，团队创建后**直接审核通过**（`approval_status=2`），邀请码同时被核销（单次使用后过期）。不传或为空时，团队 `approval_status=1`（待审核），需管理端通过 `PUT /admin/teams/:uuid/approval` 审核。
- **响应**:
```json
{
  "code": 0,
  "message": "团队创建成功",
  "data": {
    "uuid": "team_xxx",
    "name": "我的团队"
  }
}
```
- **错误码**：`11021` 已有主团队不可重复创建；`20005` 预算范围不合法；`10013` 邀请码无效或已过期；`10014` 邀请码使用次数已用尽。

---
