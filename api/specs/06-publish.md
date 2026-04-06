## 6. 需求发布模块 (Phase 3)

### 6.1 AI 对话

- **POST** `/api/v1/projects/ai-chat`
- **描述**: 与 AI 对话梳理需求
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| message | string | Y | 用户消息内容 |
| category | string | N | 已选分类；建议与 **项目分类枚举** 对齐（`data` \| `dev` \| `visual` \| `solution`），便于与创建项目、草稿一致；服务端是否强校验以实现为准 |

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
| category | string | Y | 项目分类，须为 `data` \| `dev` \| `visual` \| `solution` |
| chat_history | array | Y | 对话历史 [{role, content}] |

- **Response**（与当前服务端 `GeneratePRD` 实现一致；字段增删以发布版本为准）:

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "prd_id": "uuid",
    "title": "项目 PRD",
    "modules": [
      {
        "id": "mod_core",
        "name": "核心功能模块",
        "cards": [
          {
            "id": "card_001",
            "module_id": "mod_core",
            "title": "核心功能",
            "type": "event",
            "priority": "P0",
            "description": "基于对话内容生成的核心功能描述",
            "acceptance_criteria": [
              {"id": "ac_001", "content": "功能正常运行", "checked": false}
            ],
            "roles": ["frontend", "backend"],
            "effort_hours": 16,
            "dependencies": [],
            "tech_tags": [],
            "status": "pending"
          }
        ]
      }
    ],
    "budget_suggestion": {
      "min": 5000,
      "max": 15000,
      "reason": "基于项目复杂度和市场行情估算"
    }
  }
}
```

- **EARS 卡片扩展字段（Mock / 未来 AI 丰富展示时可选用，服务端未强制返回）**：

| 字段 | 说明 |
|------|------|
| `event` | 触发条件（When / 用户事件描述） |
| `action` | 系统行为（The system shall…） |
| `response` | 可观测响应或输出 |
| `state_change` | 状态迁移说明 |

### 6.3 保存草稿

- **POST** `/api/v1/projects/draft`
- **描述**: 保存需求发布草稿
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | N | 项目分类；**未传时服务端创建草稿默认写入 `dev`**（原为 `app`）；若显式传入须为 `data` \| `dev` \| `visual` \| `solution`，否则 **400** |
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
    "draft_id": "proj_uuid_001",
    "uuid": "proj_uuid_001",
    "saved_at": "2026-03-20T10:00:00Z"
  }
}
```

- **说明**：`draft_id` 与 `uuid` 均为该项目 UUID。分类校验与默认值见上表；与正式创建项目使用同一套四值枚举（见 **通用约定 — 项目分类枚举**）。

### 6.4 发布项目

- **POST** `/api/v1/projects`
- **描述**: 发布新项目需求（与 `CreateProjectReq` 校验一致）
- **Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | Y | 需求标题，5–200 字 |
| description | string | Y | 需求描述，不少于 20 字 |
| category | string | Y | 分类枚举：`data` \| `dev` \| `visual` \| `solution`；旧 6 类字符串 **400**（见 **通用约定 — 项目分类枚举**） |
| template_type | string | N | 模板类型 |
| budget_min | number | N | 预算下限 |
| budget_max | number | N | 预算上限 |
| deadline | string | N | 截止日期（ISO 日期字符串） |
| tech_requirements | string[] | N | 技术要求标签 |
| attachments | object[] | N | 附件，最多 10 项（`name`/`url`/`size`/`type`） |
| match_mode | int | N | 撮合模式：`1` AI / `2` 人工 / `3` 邀请，默认 `1` |
| is_draft | bool | N | `true` 为草稿（status=1），`false` 为已发布（status=2） |

- **Response**:

```json
{
  "code": 0,
  "message": "项目发布成功",
  "data": {
    "id": "proj_uuid_001",
    "uuid": "proj_uuid_001",
    "status": 2
  }
}
```

### 6.4.1 将草稿设为已发布（独立动作）
- **POST** `/api/v1/projects/:id/publish`
- **Headers**：需认证；**说明**：将已有项目从未发布流转为已发布（与 **6.4** `is_draft: false` 二选一即可，具体校验以实现为准）。

### 6.5 关闭需求

- **PUT** `/api/v1/projects/:id/close`
- **Headers**: 需认证（需求方）
- **Request Body**: `{ "reason": "可选，关闭说明" }`
- **说明**: 已关闭（status=4）再次关闭返回业务码 `20010`；**已撮合进行中（status=3）** 不允许关闭，返回业务码 **`20002`**（项目状态不允许此操作）。

