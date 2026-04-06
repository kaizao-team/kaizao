## 8. 投标/撮合模块 (Phase 4)

### 8.1 获取投标列表

- **GET** `/api/v1/projects/:projectId/bids`
- **描述**：获取指定项目的所有投标。若投标在库中带有 **`team_id`**（团队投标或快速撮合写入），则 **`bid_type` 为 `team`** 并返回团队 UUID、名称、成员摘要；否则为 **`personal`**（见 **修订记录 2026-04-06**）。
- **响应**：

```json
{
  "code": 0,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "user_201",
      "user_name": "张开发",
      "avatar": null,
      "rating": 4.9,
      "completion_rate": 98,
      "bid_amount": 5000,
      "duration_days": 14,
      "proposal": "拥有5年Flutter开发经验...",
      "bid_type": "team",
      "team_id": "11111111-1111-1111-1111-111111111111",
      "team_name": "示例团队",
      "team_avatar_url": "https://...",
      "team_members": [
        {
          "user_id": "user_201",
          "nickname": "张开发",
          "avatar_url": "https://...",
          "role_in_team": "队长"
        }
      ],
      "skills": [],
      "created_at": "2026-03-20T10:00:00Z"
    }
  ]
}
```

- **说明**：`skills` 当前实现多为空数组；**不含** `match_score` / `is_ai_recommended` 等 Mock 扩展字段，除非后续版本补充。

### 8.2 提交投标

- **POST** `/api/v1/projects/:projectId/bids`
- **描述**：供给方提交投标。若 `team_id` 非空，服务端通过 `FindByUUID` 解析为内部 ID 并写入 `bids.team_id`；**同时校验投标人须为该团队的队长或活跃成员**，否则返回 **`30007`**（投标人不属于该团队）。
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
- **描述**：需求方选定供给方。若接受的投标记录上存在 **`team_id`**，项目进入已撮合状态时会 **同步写入 `projects.team_id`**，与团队实体绑定。
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

### 8.5 智能推荐团队列表

- **GET** `/api/v1/projects/:id/recommendations`
- **Headers**: 需认证（**仅需求发布者**）
- **Query**: `page`（默认 1）、`page_size`（默认 10，最大 20）
- **描述**: 服务端将请求转发至 AI-Agent `POST /api/v2/match/recommend`（需配置 `ai_agent.base_url` 或环境变量 `VB_AI_AGENT_BASE_URL`）。AI 侧仍按 **用户 UUID** 召回候选；Go 聚合层将每名候选解析为其在平台上的 **主团队**（优先担任队长的活跃团队，否则取最近加入的活跃成员关系），**无团队归属的候选会被跳过**（不入列表）。未配置或下游失败时返回业务码 **`50001`**（AI 服务暂不可用）。
- **响应**（`data` 字段摘要）:

```json
{
  "demand_id": "string",
  "match_type": "recommend_providers",
  "experts": [],
  "recommendations": [],
  "overall_suggestion": "string",
  "no_match_reason": null,
  "meta": {}
}
```

- **说明**: `experts` 与 `recommendations` 为同一批推荐条目（便于前端兼容）。单条以 **团队** 为主实体，典型字段包括：
  - **团队**: `bid_type` 恒为 `"team"`，`team_id`（团队 UUID）、`team_name`、`team_avatar_url`（可选）、`team_members`（成员摘要数组：含 `user_id`、`nickname`、`avatar_url`、`role_in_team` 等，最多 8 条）。
  - **召回锚点 / 联系人**: `provider_id`（与 `user_id` 相同，为 AI 召回的用户 UUID）、以及该用户的 `nickname`、`avatar_url`、`rating`、`completion_rate`、`primary_skill` / `highlight_skills` 等展示字段。

### 8.6 快速撮合（一键选标）

- **POST** `/api/v1/projects/:id/quick-match`
- **Headers**: 需认证（**仅需求发布者**）
- **描述**: 与 **8.5** 相同链路拉取推荐后，取 **首条** 同时满足「平台存在该用户」且「能解析出主团队」的条目，创建投标（写入 `bids.team_id`）并立即接受；`projects.team_id` 随选标一并写入。无可用推荐、用户不存在或无法解析团队时返回 **`30009`**（未找到可撮合的造物者）；AI 不可用时同 **8.5**（`50001`）。
- **响应**:

```json
{
  "code": 0,
  "message": "快速匹配完成，已选定团队",
  "data": {
    "status": "accepted",
    "bid_id": "string",
    "provider_id": "string",
    "team_id": "string",
    "team_name": "string",
    "match_score": 0,
    "recommendation_reason": "string",
    "highlight_skills": [],
    "dimension_scores": {},
    "agreed_price": 0,
    "estimated_duration_days": 0
  }
}
```

---
