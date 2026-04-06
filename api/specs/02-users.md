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
    "onboarding_status": 2,
    "onboarding_submitted_at": null,
    "resume_url": null,
    "onboarding_application_note": null,
    "skills": [],
    "role_tags": []
  }
}
```
- **说明**：对于 `role=2/3`（专家 / 团队方），`hourly_rate` 与 `available_status` 优先从用户的 **主团队**（`FindPrimaryTeamForUser`：队长且 `teams.status=1`，否则取最近加入的活跃成员）读取；找不到团队时回退为用户自身的值。

### 2.2 更新用户信息
- **PUT** `/api/v1/users/me`
- **Headers**: 需认证
- **Body**: 任意用户字段子集, 如 `{ "role": 1, "nickname": "张三" }`
- **Response**: `{ "code": 0, "message": "更新成功" }`
- **说明**：对于 `role=2/3`，写入 `hourly_rate` 或 `available_status` 时会在同一事务内同步到用户的 **主团队**（`teams` 表），保证两侧数据一致。

### 2.3 专家提交入驻材料（进入人工审核）
- **POST** `/api/v1/users/me/onboarding/application`
- **Headers**: 需认证；仅 `role=2/3`。
- **Body**:
```json
{
  "resume_url": "https://example.com/cv.pdf",
  "note": "补充说明",
  "portfolio_uuids": ["作品集UUID-1"]
}
```
- **规则**：须至少提供 **有效 `resume_url`** 或 **至少 1 个属于本人的作品集 `portfolio_uuids`**（须已存在且 `status=1`）；通过后 `onboarding_status=1`，`onboarding_submitted_at` 写入时间，供运营在管理后台审核。

### 2.4 专家兑换团队邀请码（直通入驻）
- **POST** `/api/v1/users/me/onboarding/redeem-invite`
- **Headers**: 需认证；仅 `role=2/3`；已 `onboarding_status=2` 不可再兑。
- **Body**: `{ "invite_code": "KZ-XXXXXXXX" }`
- **行为**：核销**当前团队**下有效码（单次使用）；用户 `onboarding_status=2`，并加入该码所属团队（`team_members`）；**同时自动生成下一条团队邀请码**（旧码失效）。管理端可通过 **13.3** 查看当前有效明文。

### 2.5 收藏
- **POST** `/api/v1/favorites` — 需认证；**Body**：`{ "target_type": "project|expert", "target_id": "目标UUID" }`；成功 `message` 为「收藏成功」或「已收藏」，`data.id` 为收藏记录 UUID。
- **DELETE** `/api/v1/favorites` — 需认证；**Body** 同上；成功 `message`：`已取消收藏`。
- **GET** `/api/v1/users/me/favorites` — 需认证；**Query**：`page`、`page_size`（默认 20，最大 50）、`target_type`（可选，筛选 `project`/`expert`）。`data` 列表项含 `id`、`target_type`、`target_id`、`created_at`；`project` 时附带 `title`、`status`、`category`、`budget_min`、`budget_max`；`expert` 时附带 `team_name`、`nickname`、`avatar_url`、`rating`（来自团队 leader）。分页见 `meta`。
- **说明**：`target_type=expert` 时，`target_id` 支持传入 **团队 UUID** 或 **专家用户 UUID**（后端自动解析为其主团队 UUID）。**`favorites` 表中 `target_id` 始终为团队 UUID**，`target_type` 为 `project` 时存项目 UUID。收藏资格检查团队 `status=1 AND available_status=1` 且队长为已入驻专家；不满足条件返回 **`30010`**。取消收藏（`DELETE`）同样支持团队 UUID 或用户 UUID。

---
