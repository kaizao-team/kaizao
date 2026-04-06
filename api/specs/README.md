# VCC 开造 — API 接口规范（Mock 数据对应）

> 版本：v2.0（Phase 2）
> 日期：2026-03-28（**修订** 2026-04-06，见下表）
> 说明：此文档整理前端 Mock 层对应的所有 API 接口，方便后端按此规范实现。

## 修订记录

| 日期 | 说明 |
|------|------|
| 2026-04-06 | **团队预算区间**：`teams.budget_min` / `budget_max`（元）；`GET/PUT /users/me` 与专家广场、首页推荐、团队详情见各模块 spec；迁移 `013_teams_budget_range.up.sql`。 |
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

## 模块索引

- [01-auth.md](01-auth.md) — 认证模块
- [02-users.md](02-users.md) — 用户模块
- [03-projects.md](03-projects.md) — 项目模块
- [04-home.md](04-home.md) — 首页聚合模块
- [05-market.md](05-market.md) — 需求广场模块
- [06-publish.md](06-publish.md) — 需求发布模块 (Phase 3)
- [07-prd.md](07-prd.md) — PRD 文档模块 (Phase 3)
- [08-bidding.md](08-bidding.md) — 投标/撮合模块 (Phase 4)
- [09-pm.md](09-pm.md) — 项目管理模块 (Phase 4)
- [10-chat-accp-pay.md](10-chat-accp-pay.md) — 聊天/验收/支付模块 (Phase 5)
- [11-profile.md](11-profile.md) — 个人资料模块
- [12-wallet.md](12-wallet.md) — 钱包模块
- [13-team.md](13-team.md) — 组队系统模块
- [14-rating.md](14-rating.md) — 评价系统模块
- [15-notification.md](15-notification.md) — 通知模块
- [16-admin.md](16-admin.md) — 管理后台

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
