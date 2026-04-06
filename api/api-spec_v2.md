# VCC 开造 — API 接口规范（Mock 数据对应）

> 版本：v2.0（Phase 2）
> 日期：2026-03-28（**修订** 2026-04-06，见下表）
> 说明：此文档整理前端 Mock 层对应的所有 API 接口，方便后端按此规范实现。

> **本文件已按模块拆分至 [`specs/`](specs/) 目录**，各模块独立维护。本文件保留完整内容作为兼容引用，新增/修改请优先编辑 `specs/` 下的对应文件。索引见 [`specs/README.md`](specs/README.md)。

## 修订记录

| 日期 | 说明 |
|------|------|
| 2026-04-06 | **团队预算区间（仅存 teams）**：迁移 `013_teams_budget_range.up.sql` 为 `teams` 新增 `budget_min`、`budget_max`（元，接单意向区间）。保留 `hourly_rate` 为咨询单价。**§2.1** `GET /users/me`：`role=2/3` 时从主团队读取 `budget_min`/`budget_max`，无团队为 `null`。**§2.2** `PUT /users/me`：可选写入预算区间，仅更新主团队；无主团队或非专家/团队方时 **400**；区间非法 **20005**。**§5.1b**、**§4.1** `recommended_experts`、**§10.3** 团队详情响应均带 `budget_min`/`budget_max`。`UserService.UpdateProfile` 增加 `teamBudgetFields` 参数。 |
| 2026-04-06 | **项目详情补全与团队方投标状态**：**§5.2** `GET /projects/:id` 三项改进：① `prd_summary` 从 `confirmed_prd.summary` 或 `ai_prd.summary` JSON 字段实际读取（不再返回空字符串）；② `milestones` 从 `milestones` 表实际查询，返回 `id`/`title`/`status`/`progress`/`due_date`/`amount`（不再硬编码空数组）；③ 新增 `my_bid_status` 字段（`omitempty`），已登录用户对该项目有投标时返回 `pending`/`accepted`/`rejected`/`withdrawn`，供前端渲染"已投标"状态。**§10.3** `GET /teams/:uuid` 团队详情字段补全：新增 `team_name`/`description`/`avatar_url`/`vibe_level`/`vibe_power`/`hourly_rate`/`avg_rating`/`member_count`/`total_projects`/`available_status`/`experience_years`/`resume_summary`/`skills` 及队长展示字段 `leader_uuid`/`nickname`/`leader_avatar_url`/`completed_projects`/`tagline`；成员信息新增 `user_id`(UUID)/`avatar_url`。Repository 层新增 `FindLatestByProjectAndBidderID`；`ProjectHandler` 新增 `MilestoneService` 依赖。 |
| 2026-04-06 | **团队对齐缺陷修复**：**§2.5** 收藏 `target_type=expert` 时 `favorites.target_id` **统一存储团队 UUID**（非用户 UUID）；传入用户 UUID 自动解析为其主团队 UUID；收藏列表 expert 项附带 `team_name`。**§5.1b** 专家列表说明更新：收藏时 `target_id` 直接传团队 `id`。**§8.2** 投标绑定团队时新增成员关系校验——投标人须为该团队队长或活跃成员，否则返回 **`30007`**。**§2.2** `UpdateProfile` 同步团队字段时区分 `ErrRecordNotFound`（无主团队，忽略）与真实查询错误（回滚事务），避免数据不一致。 |
| 2026-04-06 | **团队实体对齐（供给侧全面切换）**：在撮合域基础上，将 **专家广场、首页推荐、用户信息、收藏资格** 全面切到以 **团队（teams）** 为主实体。**§5.3** `GET /market/experts`：改查 `teams` 表（`status=1 AND available_status=1`），按 `vibe_power DESC, avg_rating DESC` 排序；响应新增 `team_name`、`vibe_level`、`vibe_power`、`member_count`，保留 leader 展示字段。**§4.1** `GET /home/demander` 的 `recommended_experts` 同步改查 `teams`，新增 `vibe_level`、`vibe_power`、`member_count`。**§2.1** `GET /users/me`：`role=2/3` 时 `hourly_rate` 与 `available_status` 从主团队读取（`FindPrimaryTeamForUser`），无团队回退用户自身值。**§2.2** `PUT /users/me`：写入 `hourly_rate` / `available_status` 时事务内同步到主团队。**§2.5** 收藏：`expertEligibleForFavorite` 改查主团队 `available_status`，无团队不可收藏。**§8.2** 投标：`BidService.Create` 实际写入 `bid.TeamID`（此前参数未赋值 bug 修复）。数据库迁移 `012_teams_biz_fields.up.sql` 为 `teams` 新增 `available_status`、`hourly_rate` 列。集成测试 `test_api_v2.py` **§5.3b**、**§4.1c**、**§2.2f** 新增。 |
| 2026-04-06 | **智能推荐与团队实体对齐（撮合域）**：供给方对外以 **团队** 为主实体。**§8.5** `GET /api/v1/projects/:id/recommendations`：AI-Agent 仍按用户 UUID（`provider_id`）召回；服务端将每名候选解析为 **主团队**（优先任 **队长** 且 `teams.status=1`，否则取 `team_members` 中 **最近加入** 的活跃成员）。无法解析团队的候选 **不出现在** 列表。成功条目 `bid_type` 为 `team`，含 `team_id`、`team_name`、`team_avatar_url`（可选）、`team_members`（≤8 条：`user_id`、`nickname`、`avatar_url`、`role_in_team`）；`provider_id`/`user_id` 为锚点用户，并带其展示字段。**§8.6** `POST .../quick-match`：首条「用户存在且可解析主团队」；写入 **`bids.team_id`**，选标后 **`projects.team_id`**；成功文案「已选定团队」，`data` 含 `team_id`、`team_name`；失败 **`30009`** / AI 不可用 **`50001`**。**§8.1** `GET .../bids`：有 `bids.team_id` 时返回 `team_*` 与 `bid_type: team`，否则 `personal`。**§8.3** 接受投标时若投标含 `team_id` 则同步项目 `team_id`。集成测试：`api/test_api_v2.py` **3.5b**。 |
| 2026-03-28 | **项目分类**：枚举由原先的 6 类（`app` / `web` / `miniprogram` / `design` / `data` / `consult`）调整为 4 类：`data` \| `dev` \| `visual` \| `solution`。需求方首页 `GET /api/v1/home/demander` 的 `categories` 固定为上述 4 项；创建/更新项目时 `category` 须为四者之一，旧值返回 **400**。草稿 `POST /api/v1/projects/draft` 未传 `category` 时默认 **`dev`**（原为 `app`）。列表/广场筛选建议仅传新四值；库内数据已清洗后传旧字符串可能无匹配。历史值迁移见 `kaizao/server/migrations/005_project_category_normalize.up.sql`。 |
| 2026-03-23 | v2.0（Phase 2）初版整理。 |

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

### 项目分类枚举（`category`）

请求体、查询参数及存储中的 **`category`**（项目需求分类）仅允许以下四值：

| `key`（请求与存储） | 含义 | 需求方首页 `name`（展示） | 首页 `icon`（字符串标识，供前端映射图标） |
|---------------------|------|---------------------------|------------------------------------------|
| `data` | 数据 | 数据 | `bar_chart` |
| `dev` | 研发 | 研发 | `code` |
| `visual` | 视觉设计 | 视觉设计 | `brush` |
| `solution` | 解决方案 | 解决方案 | `lightbulb` |

**历史值映射（迁移脚本已对库内清洗）**：`app` / `web` / `miniprogram` → `dev`；`design` → `visual`；`consult` → `solution`；`data` 保持；其余无法识别值 → `dev`（以迁移脚本约定为准）。

凡响应体中含项目信息的 **`category`** 字段（列表项、详情、`my_projects`、`recommended_demands` 等），在数据清洗完成后均为上述四值之一。

---

## 1. 认证模块

### 1.1 发送短信验证码
- **POST** `/api/v1/auth/sms-code`
- **Body**: `{ "phone": "13800138000", "purpose": 2 }`
- **Response**: `{ "code": 0, "message": "验证码已发送" }`
- **说明**: `purpose` 取值 `1` 注册、`2` 登录、`3` 其他业务（如绑定手机，与产品约定一致）

### 1.2 手机号登录/注册
- **POST** `/api/v1/auth/login`
- **Body**: `{ "phone": "13800138000", "code": "123456", "device_type": "web", "device_id": "可选" }`（`code` 须 6 位；`device_type` 可选 `android` \| `ios` \| `web`）
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
- **Response**: `{ "data": { "access_token": "string", "refresh_token": "string", "expires_in": 3600 } }`

### 1.4 退出登录
- **POST** `/api/v1/auth/logout`
- **Headers**: 需认证
- **Response**: `{ "code": 0 }`

### 1.5 手机号注册（独立）
- **POST** `/api/v1/auth/register`
- **Body**: `{ "phone": "13800138000", "sms_code": "123456", "nickname": "昵称", "role": 2, "invite_code": "可选" }`
- **Response**（`data` 为 `AuthResp`）:
```json
{
  "code": 0,
  "data": {
    "user": {
      "uuid": "string",
      "nickname": "string",
      "avatar_url": null,
      "role": 1,
      "level": 1,
      "credit_score": 500,
      "is_verified": false
    },
    "access_token": "string",
    "refresh_token": "string",
    "expires_in": 3600
  }
}
```
- **说明**:
  - **邀请码不参与注册**；专家 `role=2/3` 注册成功后默认 `onboarding_status=1`（待入驻），但仍**正常返回** `access_token` / `refresh_token`，可登录后提交材料或兑换团队邀请码。
  - 需求方等非专家角色默认 `onboarding_status=2`（已通过）。
  - 专家完成入驻前**不会出现在**首页推荐专家、`GET /market/experts` 等列表（仅展示 `onboarding_status=2` 的专家）。

### 1.6 登录/注册策略（服务端配置）
- **配置文件** `registration`：仅 `disable_auto_register` 仍影响 **1.2 登录**（未注册且禁止静默注册时返回 `10017`）。`require_invite_roles` / `require_approval_roles` 已不再作用于注册接口。
- **环境变量**：`VB_REGISTRATION_DISABLE_AUTO_REGISTER`。
- **POST** `/api/v1/auth/login`：待审/已拒绝入驻**不拦截**登录；专家需通过材料审核或团队邀请码直通后才会上首页。
- **入驻状态** `onboarding_status`：`1` 待审核，`2` 已通过，`3` 已拒绝。`GET /api/v1/users/me` 含 `onboarding_status`、`onboarding_submitted_at`、`resume_url`、`onboarding_application_note`（若有）。
- **集成测试**：`api/test_api_v2.py` **1.5** 节为团队 `11111111-1111-1111-1111-111111111111`（迁移 003 种子）发码；`--full-onboarding` 跑「专家注册 → 兑换邀请码 → 新码轮换」。

### 1.7 获取密码加密公钥
- **GET** `/api/v1/auth/password-key`
- **Response `data`**：`key_id`、`algorithm`（`RSA-OAEP-SHA256`）、`public_key_pem`（PKCS#1 PEM）
- **说明**：客户端用公钥对 UTF-8 密码做 RSA-OAEP（SHA-256），密文 Base64 后作为 `password_cipher`。**禁止**在 JSON 根级传明文 `password`（业务码 `10023`）。细节与错误码见 `api/api-registry.md`。

### 1.8 图形验证码
- **GET** `/api/v1/auth/captcha`
- **Response `data`**：`captcha_id`、`image_base64`（PNG，无 `data:` 前缀）、`expires_in`（秒）

### 1.9 用户名密码注册
- **POST** `/api/v1/auth/register-password`
- **Body**：`username`（4–32，`a-zA-Z0-9_`）、`password_cipher`、`nickname`（可选）、`role`（0–3）、`phone`（可选，绑定手机，**无需**短信验证码）、`sms_code`（可选，服务端不校验）、`invite_code`（可选）
- **成功**：与 **1.5** 相同结构（`user`、`access_token`、`refresh_token`、`expires_in`）

### 1.10 用户名密码登录
- **POST** `/api/v1/auth/login-password`
- **Body**：`login_type`（`username`|`phone`）、`identity`、`password_cipher`、`captcha_id`、`captcha_code`、`device_type`（可选）
- **成功**（`SuccessMsg`，`data` 示例）：
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "user_id": "用户UUID",
  "role": 1,
  "is_new_user": false
}
```

### 1.11 微信登录
- **POST** `/api/v1/auth/wechat`
- **Body**：`code`（微信授权码，必填）、`device_type`（可选 `android`|`ios`|`web`）
- **说明**：当前实现多为占位（如返回 `message: wechat login endpoint ready`）；正式联调前请以当时服务端响应为准。

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
    "budget_min": null,
    "budget_max": null,
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
- **说明**：对于 `role=2/3`（专家 / 团队方），`hourly_rate` 与 `available_status` 优先从用户的 **主团队**（`FindPrimaryTeamForUser`：队长且 `teams.status=1`，否则取最近加入的活跃成员）读取；找不到团队时回退为用户自身的值。**`budget_min` / `budget_max`** 仅存储在 **`teams` 表**：有主团队时从主团队读取；无团队时为 `null`。

### 2.2 更新用户信息
- **PUT** `/api/v1/users/me`
- **Headers**: 需认证
- **Body**: 任意用户字段子集, 如 `{ "role": 1, "nickname": "张三" }`
- **Response**: `{ "code": 0, "message": "更新成功" }`
- **说明**：对于 `role=2/3`，写入 `hourly_rate` 或 `available_status` 时会在同一事务内同步到用户的 **主团队**（`teams` 表），保证两侧数据一致。可选 **`budget_min` / `budget_max`**（元）：**仅**写入主团队行，不写 `users`；合并后若上下限均非空须满足 `budget_max >= budget_min`（否则业务码 `20005`）。请求体中只要出现 `budget_min` 或 `budget_max`，且当前用户 **无主团队**（或非专家/团队方角色），返回 **HTTP 400**。

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
- **说明**：以 **团队** 为主实体，查 `teams` 表（`status=1 AND available_status=1`），且 **队长**须为已通过入驻的专家（`users.role IN (2,3)`、`onboarding_status=2`），与旧版「专家用户列表」准入一致；按 `vibe_power DESC, avg_rating DESC` 排序。`nickname`、`avatar_url`、`skills` 等来自团队 leader。**`hourly_rate`** 为咨询单价（元/小时）；**`budget_min` / `budget_max`** 为团队接单意向预算区间（元）。**收藏专家**（**§2.5**）时 `target_id` 直接传团队 `id`（团队 UUID），后端以团队 UUID 存储。

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
      }
    ],
    "my_bid_status": "pending"
  }
}
```
- **说明**: `prd_summary` 优先从 `confirmed_prd.summary` 提取，其次 `ai_prd.summary`，均无则为空字符串; `milestones` 从数据库实际查询里程碑记录，含 `due_date` 和 `amount`; `my_bid_status` 仅在已登录用户对该项目有投标记录时返回（`omitempty`），取值 `pending` / `accepted` / `rejected` / `withdrawn`，前端据此判断"发起投标"或"已投标"按钮状态

---

## 后续迭代接口（Phase 3+）

以下条目**保留为路线图**；其中多项已在下文章节落地，路径参数以路由为准（例如会话相关为 **`:uuid`** 而非 `:id`）。投标、智能推荐、快速撮合见 **§8**；实现对照 `kaizao/server/internal/router/router.go` 与 `api/test_api_v2.py`。

- `GET /api/v1/projects/search` — 项目搜索（当前占位）
- `GET|POST /api/v1/projects/:id/bids` — 已落地，见 **§8.1 / §8.2**
- `GET /api/v1/conversations`、`GET|POST /api/v1/conversations/:uuid/messages` 等 — 已落地，见 **Phase 5（CHAT）**；`POST /api/v1/conversations` **保持占位**（会话仅在撮合成功时创建，见 **§5.0b**）
- `GET /api/v1/users/:id` — 公开资料，见 **§8 PROF**（非 `/profile` 路径）
- `POST /api/v1/orders` — 已落地（创建订单）
- `GET /api/v1/wallet/balance` — 已落地，见 **Wallet**
- `POST /api/v1/ai/agent-sessions` — AI Agent 会话（占位）
- `GET /api/v1/income/summary` — 收入详情（占位）

---

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
    "prd_id": "uuid（每次请求新生成）",
    "project_id": "项目UUID",
    "title": "{项目标题} PRD",
    "version": "1.0",
    "created_at": "项目创建时间",
    "modules": []
  }
}
```

- **说明**：当前 `GetPRD` 返回的 `modules` 可能为空数组，待 PRD 持久化与 AI 管线接入后与 **6.2** 中 `modules[].cards[]` 结构对齐；卡片扩展字段表见 **6.2**。

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

- **GET** `/api/v1/projects/:id/milestones`
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

- **GET** `/api/v1/projects/:id/daily-reports`
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

### 9.5 获取项目共享文件列表

- **GET** `/api/v1/projects/:id/files`
- **鉴权**：Bearer Token
- **权限**：项目需求方（`owner`）、已选服务方（`provider`），或项目已绑定团队下的团队成员。
- **Query**：`page`、`page_size`（默认 1 / 20，最大 100）；`file_kind`（可选，`reference`|`process`|`deliverable`，不传则不限）；`milestone_id`（可选，里程碑 **UUID**，仅返回关联该里程碑的文件）；`with_url`（可选，`1`/`true` 默认，为每条生成短时 `download_url`；`0`/`false` 则不生成，减轻列表开销）。
- **响应**：标准分页，`data` 为文件对象数组：

```json
{
  "code": 0,
  "data": [
    {
      "uuid": "文件UUID",
      "file_kind": "reference",
      "original_name": "需求说明.pdf",
      "content_type": "application/pdf",
      "size_bytes": 102400,
      "milestone_id": null,
      "uploaded_by_user_id": "用户UUID",
      "uploaded_by_nickname": "张三",
      "created_at": "2026-04-05T10:00:00Z",
      "download_url": "https://..."
    }
  ],
  "meta": { "page": 1, "page_size": 20, "total": 1, "total_pages": 1 }
}
```

- **说明**：`file_kind`：`reference` 参考资料，`process` 过程文件，`deliverable` 交付物。`download_url` 为对象存储预签名 GET，有效期约 15 分钟，用于下载或浏览器预览（依赖 `content_type`）。

### 9.6 上传项目共享文件

- **POST** `/api/v1/projects/:id/files`
- **鉴权**：Bearer Token
- **权限**：同 9.5。
- **Content-Type**：`multipart/form-data`
- **表单字段**：
  - `file`（必填）文件本体；
  - `file_kind`（可选，默认 `process`）：`reference` | `process` | `deliverable`；
  - `milestone_id`（可选）里程碑 UUID，关联阶段性文件。
- **响应**：`message` 为「上传成功」，`data` 为单条文件结构（同 9.5 一项，含 `download_url`）。
- **错误码**：`11013` 对象存储未启用；`11014` 过大；`11016` 上传失败；`11017` 空文件；`21008` 无权限；`21016` `file_kind` 非法；`21003` 里程碑不存在或不属于该项目。

### 9.7 获取单个项目文件（元数据 + 下载链接）

- **GET** `/api/v1/projects/:id/files/:fileUuid`
- **鉴权**：Bearer Token
- **权限**：同 9.5。
- **响应**：`data` 为单条文件对象（含 `download_url` 预签名链接）。
- **错误码**：`21015` 文件不存在或不属于该项目；`21008` 无权限。

---

## Phase 5：CHAT + ACCP + PAY 模块接口

> v5.0 — 会话、验收、订单支付等；下列含 **创建订单** 补充说明。

### 5.0 创建订单
- **路径**：`POST /api/v1/orders`
- **鉴权**：Bearer Token（需求方）
- **Body**：`{ "project_id": "项目UUID", "amount": 0 }`（`project_id` 必填；`amount` 可选，具体计价以实现为准）
- **响应**：`message` 为「订单已创建」，`data` 含 `order_id`（UUID）、`order_no`、`status`（如 `pending`）

### 5.0b POST /api/v1/conversations（占位，未使用）

- **说明**：**业务会话仅在撮合成功（接受投标）时由服务端创建**（私聊 `conversation_type=1`、绑定 `project_id`、首条系统消息）。客户端**不要**依赖本接口创建会话；双方后续聊天请使用 **§5.3** `POST /api/v1/conversations/:uuid/messages`。
- **当前行为**：鉴权通过后返回占位成功 JSON（`data` 含 `status: "endpoint ready"`），**无业务语义**，后续若启用需单独改版文档。

### 5.1 获取会话列表

- **路径**：`GET /api/v1/conversations`
- **鉴权**：Bearer Token
- **描述**：获取当前用户的聊天会话列表（路径中的会话标识为 **UUID**，下文 `:uuid` 与路由一致）。仅包含 **未软删**（`status=1`）且当前用户为会话双方之一的记录。
- **查询参数**：

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| offset | int | 0 | 跳过条数，≥0 |
| limit | int | 20 | 每页条数，最大 100 |

- **响应**：`data` 为会话数组；带 **`meta`** 分页：`page`、`page_size`、`total`、`total_pages`（与列表类接口一致）。`unread_count` 为当前用户在该会话的未读条数：他人发送且消息 `id` 大于该用户在 `conversation_members` 中的 `last_read_msg_id` 的数量。`project_title` 来自关联项目标题（无项目时为空字符串）。

```json
{
  "code": 0,
  "message": "success",
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
  ],
  "meta": {
    "page": 1,
    "page_size": 20,
    "total": 1,
    "total_pages": 1
  }
}
```

### 5.2 获取会话消息列表

- **路径**：`GET /api/v1/conversations/:uuid/messages`
- **鉴权**：Bearer Token
- **查询参数**：`before`（分页游标，**消息表自增 `id`**，仅服务端内部游标）, `limit`（默认 20）
- **描述**：获取某个会话的聊天消息。**仅会话双方**可调；**已软删**会话返回不存在。消息按 `id` **降序**返回（新消息在前，客户端可按需反转展示）。
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

- **路径**：`POST /api/v1/conversations/:uuid/messages`
- **鉴权**：Bearer Token
- **权限**：仅会话双方；非成员 **403**，业务码 `60002`；已软删会话 **404**（`60001`）。
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

- **路径**：`POST /api/v1/conversations/:uuid/read`
- **鉴权**：Bearer Token
- **权限**：同 5.2 / 5.3。
- **行为**：将当前用户在该会话的已读位置更新为**当前最新消息的数据库 `id`**（写入 `conversation_members.last_read_msg_id`），用于驱动列表中的 `unread_count`。
- **响应**：`{ "code": 0, "message": "ok" }`

### 5.5 删除会话

- **路径**：`DELETE /api/v1/conversations/:uuid`
- **鉴权**：Bearer Token
- **权限**：同 5.2；**软删除**（会话 `status=2`），之后该 `:uuid` 对消息接口视为不存在。
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

**说明**: 团队详情返回完整业务字段，与 `GET /market/experts` 列表项对齐，另附 `description`、`resume_summary`、`experience_years`、`total_projects`、`available_status`、成员 `user_id`/`avatar_url` 等。`skills` 为队长技能名称列表。详见 **`specs/13-team.md`**。

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

---

## 12. 通知模块

**前缀**：`/api/v1/notifications`，均需 **Bearer**。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/notifications` | 列表；Query：`page`、`page_size`、`type`（可选，通知类型 int） |
| GET | `/notifications/unread-count` | `data.unread_count` |
| PUT | `/notifications/read-all` | 全部标记已读 |
| PUT | `/notifications/:uuid/read` | 单条已读 |

**列表项 `data[]` 常用字段**：`id`/`uuid`、`title`、`content`、`type` 与 `notification_type`（并存便于兼容）、`target_type`、`target_id`、`is_read`、`read_at`、`created_at`。分页见 `meta`。

---

## 13. 管理后台 — 团队邀请码与入驻审核

> 路由组：`/api/v1/admin/*`，需 **JWT** 且数据库用户 **`role=9` 管理员**（中间件以库中角色为准）。

邀请码**绑定团队**（`team_id`），每条有效码默认 **仅用一次**；专家在 **2.4** 兑换后旧码作废，系统**自动为该团队生成新码**（新码明文写入新行，供列表与「当前码」接口查看）。

### 13.1 POST `/api/v1/admin/invite-codes` — 为团队创建/刷新邀请码

**Body**:
```json
{
  "team_uuid": "团队UUID",
  "note": "首批专家",
  "expires_at": "2027-12-31T23:59:59Z"
}
```
- 若该团队已有**未使用且未禁用**的码，会先全部作废再插入新码。
- **响应** `data`：`code_plain`、`uuid`、`team_id`、`max_uses`（固定为 1）、`expires_at`、`note`。

### 13.2 GET `/api/v1/admin/invite-codes` — 邀请码列表

- **Query**: `page`, `page_size`, `team_uuid`（可选，按团队筛选）
- **响应**: 列表项含 `team_id`、`code_hint`、`code_plain`（当前行若曾存明文则返回；已核销的历史行通常无明文）、`used_count`/`max_uses`、`expires_at`、`note`、`disabled_at`、`created_at`。

### 13.3 GET `/api/v1/admin/teams/:uuid/current-invite-code` — 查看团队当前有效邀请码

- **响应**：无有效码时 `data.has_active=false`；有则 `has_active=true` 且含 `code_plain`、`uuid`、`expires_at`、`note` 等。

### 13.4 PUT `/api/v1/admin/users/:uuid/onboarding` — 审核入驻（材料通道）

**Body**: `{ "status": "approved" | "rejected", "reason": "可选，拒绝时建议填写" }`

**响应**: `{ "code": 0, "message": "已更新" }`

### 相关错误码（节选）

| code | 说明 |
|------|------|
| 10013 | 邀请码无效或已过期 |
| 10014 | 邀请码使用次数已用尽 |
| 10016 | 注册申请未通过审核（历史文案，仍可用于业务提示） |
| 10017 | 请先完成注册后再登录 |
| 10018 | 已完成入驻审核 |
| 10019 | 仅专家角色可提交入驻或兑换团队邀请码 |
| 11011 | 请至少提供简历链接或有效作品集 |
| 11012 | 团队不存在 |
