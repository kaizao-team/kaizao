# MVP 未实现需求清单

> 基于商业计划书 MVP v1.0 功能列表，逐项核对前后端代码后生成
> 日期：2026-03-29
> 状态标记：✅ 已实现 | ⚠️ 部分实现（有骨架但未打通） | ❌ 未实现

---

## 一、MVP 功能对照总表

### 1. 用户系统（手机号 + 微信登录）

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 手机号注册/登录 | ⚠️ | 后端 `auth.go` 有接口，短信验证码模型存在，但**实际短信发送未接入**（固定验证码 or mock） |
| 微信登录 | ⚠️ | 路由存在 `/auth/wechat`，handler 有骨架，但**微信 SDK 未接入** |
| JWT Token 刷新 | ✅ | 已实现 |
| 角色选择（需求方/专家） | ✅ | 前端有 `role_select_page.dart`，后端 User.Role 字段支持 |
| **需求方 onboarding 手机号采集** | ❌ | `demander_profile_page.dart` 无手机号输入框 |
| **专家 onboarding 手机号采集** | ❌ | `expert_profile_page.dart` 无手机号输入框 |

### 2. 需求发布 + AI 辅助填写

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 需求分类选择 | ✅ | 前端 `post_category_step.dart` |
| AI 多轮对话澄清需求 | ⚠️ | **Go 后端 `prd.go` 的 AIChat 返回硬编码文本，未调用 AI-Agent 服务**；AI-Agent 端 `requirement_router.py` 有完整实现（含 SSE 流式），但 Go 后端未转发 |
| 草稿保存 | ✅ | `SaveDraft` 已实现 |
| 匹配模式选择 | ✅ | 前端 `post_match_mode.dart` |

### 3. AI 需求拆解引擎（PRD + EARS 卡片生成）

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 生成 PRD | ⚠️ | **Go 后端 `GeneratePRD` 返回硬编码 mock 数据**；AI-Agent 端有完整的 PRD 生成 + EARS 拆解实现，但未打通 |
| PRD 查看页面 | ✅ | 前端 `prd_page.dart` + `ears_card_widget.dart` 已实现 |
| EARS 卡片编辑 | ⚠️ | 路由存在，handler 仅返回 mock 成功 |
| 预算/工期预估 | ⚠️ | PRD 生成时有 `budget_suggestion` 字段，但是硬编码值 |

### 4. 智能撮合（需求浏览 + 投标 + 基础推荐）

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 需求广场列表 | ✅ | `market/projects` 已实现 |
| 专家广场列表 | ✅ | `market/experts` 已实现 |
| 投标（创建） | ✅ | `bid.go` CreateBid 已实现 |
| 投标列表查看 | ✅ | `bid.go` ListBids 已实现 |
| 选定投标（接受） | ✅ | `bid.go` AcceptBid 已实现，会更新 project 状态和 provider |
| AI 投标建议 | ⚠️ | `AISuggestion` **返回硬编码数据**，未调用 AI-Agent 的 `/api/v2/match/recommend` |
| 智能推荐匹配 | ❌ | 路由 `/projects/:id/recommendations` 和 `/projects/:id/quick-match` 均为 placeholder |
| **撮合成功后的消息通知** | ❌ | AcceptBid 后仅更新 project 状态，**未创建通知记录、未推送消息** |

### 5. 项目管理看板（任务状态 + 里程碑）

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 任务列表 | ✅ | `ListTasks` 已实现 |
| 任务状态更新 | ✅ | `UpdateTaskStatus` 已实现 |
| 里程碑列表 | ✅ | `ListMilestones` 已实现 |
| 每日简报 | ⚠️ | `GetDailyReports` 路由存在，返回 mock 数据 |
| 看板 UI | ✅ | 前端 `kanban_board.dart` + `milestone_timeline.dart` 已实现 |

### 6. IM 即时消息（MVP 不要求完整实现）

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 会话列表 | ✅ | `Conversation.List` 已实现 |
| 消息收发 | ✅ | `Conversation.SendMessage` / `ListMessages` 已实现 |
| 已读标记 | ✅ | `Conversation.MarkRead` 已实现 |
| WebSocket 实时推送 | ❌ | 仅 HTTP 轮询，无 WS |

### 7. 单次验收 + 基础验收清单

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 验收页面 | ✅ | 前端 `acceptance_page.dart` + checklist widget |
| 接受里程碑 | ✅ | `AcceptMilestone` 已实现 |
| 请求修改 | ✅ | `RequestRevision` 已实现 |

### 8. 双向评价 + 星级评分

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 创建评价 | ✅ | `Review.Create` 已实现，多维度评分 |
| 评价列表 | ✅ | `Review.ListByProject` 已实现 |
| 评价 UI | ✅ | 前端 `rate_page.dart` + star_rating widget |

### 9. 担保交易（微信支付 / 支付宝）

| 功能点 | 状态 | 说明 |
|--------|------|------|
| 订单详情 | ✅ | `Order.GetDetail` 已实现 |
| 预支付 | ⚠️ | `Order.Prepay` 已实现但**未接入真实支付 SDK** |
| 订单状态查询 | ✅ | `Order.GetStatus` 已实现 |
| 支付回调 | ❌ | `callback/wechat` 和 `callback/alipay` 均为 placeholder |
| 资金释放 | ❌ | `orders/:id/release` 为 placeholder |
| 退款 | ❌ | `orders/:id/refund` 为 placeholder |
| 优惠券 | ⚠️ | 路由存在，返回 mock 数据 |
| 钱包 | ✅ | 余额查询、提现、流水列表均已实现 |

---

## 二、核心缺失项（优先级排序）

### P0 — 必须立即完成

#### 1. 🔴 Go 后端 → AI-Agent 服务调用链路打通

**现状**：Go 后端的 AI 相关接口（AIChat、GeneratePRD、AISuggestion）全部返回**硬编码 mock 数据**，完全未调用 AI-Agent Python 服务。AI-Agent 服务本身有完整实现（需求分析、PRD 生成、智能匹配），但两端没有连接。

**需要做的**：
- Go 后端新增 AI-Agent HTTP Client，配置 AI-Agent 服务地址
- `prd.go` AIChat → 转发到 `ai-agent /api/v2/requirement/start` 和 `/message`
- `prd.go` GeneratePRD → 转发到 `ai-agent /api/v2/requirement/{project_id}/confirm`
- `bid.go` AISuggestion → 转发到 `ai-agent /api/v2/match/recommend`
- 支持 SSE 流式透传（AI-Agent 已有 SSE 端点）

**涉及文件**：
- 新增：`server/internal/service/ai_client.go`（AI-Agent HTTP Client）
- 修改：`server/internal/handler/prd.go`
- 修改：`server/internal/handler/bid.go`
- 修改：`server/internal/config/config.go`（新增 AI-Agent 地址配置）

#### 2. 🔴 撮合成功后的消息通知

**现状**：`AcceptBid` 成功后仅更新 project 状态（status=3, provider_id），**未创建 Notification 记录、未通知双方**。通知模型 `Notification` 已定义，但通知相关的 4 个接口全部是 placeholder。

**需要做的**：
- 实现通知 CRUD 服务（创建、列表、标记已读、未读计数）
- `AcceptBid` 成功后自动创建通知：
  - 给需求方："您已选定 [团队/专家名称]，项目即将启动"
  - 给专家/团队："恭喜！您已被选定为 [项目名称] 的服务方，我们将尽快接洽"
- 前端通知列表页面对接真实接口（目前 `notification_settings_page.dart` 仅为设置页）

**涉及文件**：
- 新增：`server/internal/service/notification_service.go`
- 新增：`server/internal/handler/notification.go`
- 新增：`server/internal/repository/notification_repo.go`
- 修改：`server/internal/service/bid_service.go`（AcceptBid 后创建通知）
- 修改：`server/internal/router/router.go`（通知路由从 placeholder 改为实际 handler）

#### 3. 🔴 需求方 & 专家 onboarding 增加手机号采集

**现状**：User 模型有 `Phone` 字段，注册/登录时会存储手机号。但 onboarding 流程（资料完善页面）没有手机号输入/展示，且**注册时用的手机号不一定是联系手机号**。

**需要做的**：
- User 模型新增 `ContactPhone` 字段（联系手机号，区别于登录手机号）
- 需求方 onboarding `demander_profile_page.dart` 增加联系手机号输入框
- 专家 onboarding `expert_profile_page.dart` 增加联系手机号输入框
- 后端 UpdateProfile 接口支持 `contact_phone` 字段
- 撮合成功后通知中可展示对方联系方式

**涉及文件**：
- 修改：`server/internal/model/user.go`（新增 ContactPhone）
- 修改：`server/internal/handler/user_profile.go`
- 修改：`app/lib/features/onboarding/pages/demander_profile_page.dart`
- 修改：`app/lib/features/onboarding/pages/expert_profile_page.dart`
- 修改：`app/lib/features/onboarding/repositories/`（提交时带上手机号）

### P1 — 流程串联必须

#### 4. 🟡 需求发布 → 撮合 → 通知 → 项目管理 全流程串联

**现状**：各模块独立存在但流程未完整串联：

```
需求发布 ──→ AI 拆解 PRD ──→ 发布到广场 ──→ 专家投标 ──→ 选定专家 ──→ ？？？
                                                                      ↓
                                                              缺少：通知双方
                                                              缺少：自动创建订单
                                                              缺少：项目状态流转到"进行中"
                                                              缺少：自动创建会话
```

**需要补齐的流程节点**：

| 触发事件 | 应发生的后续动作 | 现状 |
|---------|---------------|------|
| 专家投标 | 通知需求方"有新投标" | ❌ 未实现 |
| 需求方选定专家 | 通知专家"已被选定" + 自动创建双方会话 + 创建订单 | ❌ 仅更新了 project 状态 |
| 订单支付成功 | 项目状态改为"进行中" + 通知专家"已付款可开工" | ❌ 支付回调未实现 |
| 里程碑交付 | 通知需求方"有新交付待验收" | ❌ 未实现 |
| 验收通过 | 释放资金 + 通知专家"资金已释放" | ❌ 资金释放未实现 |

#### 5. 🟡 通知模块完整实现

**现状**：Notification 模型已定义，4 个 API 路由全部是 placeholder。

**需要做的**：
- 通知列表（分页、按类型筛选）
- 标记已读 / 全部已读
- 未读计数
- 前端通知列表页面（目前没有独立的通知列表页）

#### 6. 🟡 订单自动创建

**现状**：`orders POST` 为 placeholder。撮合成功后需要自动创建订单。

**需要做的**：
- AcceptBid 后自动创建 Order
- 或需求方确认后手动触发创建订单

---

## 三、Go 后端 placeholder 接口统计

以下接口在路由中注册但实际指向 `placeholder`（返回固定 `{"status": "endpoint ready"}`）：

| 路由 | 说明 | 优先级 |
|------|------|--------|
| `POST /projects/:id/tasks` | 创建任务 | P1 |
| `POST /projects/:id/milestones` | 创建里程碑 | P1 |
| `GET /projects/:id/overview` | 项目概览 | P2 |
| `GET /projects/:id/recommendations` | 智能推荐 | P1 |
| `POST /projects/:id/quick-match` | 快速匹配 | P2 |
| `POST /projects/:id/ai-assist` | AI 辅助 | P2 |
| `PUT /bids/:bidId/withdraw` | 撤回投标 | P2 |
| `POST /favorites` | 收藏 | P2 |
| `DELETE /favorites` | 取消收藏 | P2 |
| `POST /conversations` | 创建会话 | P1 |
| `GET /notifications` | 通知列表 | **P0** |
| `PUT /notifications/:uuid/read` | 标记已读 | **P0** |
| `PUT /notifications/read-all` | 全部已读 | **P0** |
| `GET /notifications/unread-count` | 未读数 | **P0** |
| `POST /devices` | 注册设备 | P2 |
| `POST /orders` | 创建订单 | **P0** |
| `POST /orders/callback/wechat` | 微信支付回调 | P1 |
| `POST /orders/callback/alipay` | 支付宝回调 | P1 |
| `POST /orders/:id/release` | 释放资金 | P1 |
| `POST /orders/:id/refund` | 退款 | P2 |
| `POST /orders/:id/split` | 分账 | P2 |
| `GET /income/summary` | 收入汇总 | P2 |
| `POST /ai/requirement-analysis` | AI 需求分析 | P1 |
| `POST /ai/generate-tasks` | AI 生成任务 | P1 |
| `POST /ai/agent-sessions` | AI Agent 会话 | P1 |
| 全部 admin/* 路由 | 管理后台 | P2 |
| `POST /me/portfolios` | 上传作品 | P2 |
| `POST /me/verification` | 实名认证 | P2 |
| `POST /me/certifications` | 技能认证 | P2 |
| `POST /teams` | 创建团队 | P2 |
| `GET /teams/ai-recommend` | AI 推荐队友 | P2 |
| `GET /projects/search` | 搜索 | P2 |
| `POST /upload` | 文件上传 | P1 |

---

## 四、AI-Agent 服务现状

AI-Agent Python 服务已有较完整的实现，但**与 Go 后端完全断开**：

| AI-Agent 模块 | 实现状态 | Go 后端调用状态 |
|---------------|---------|----------------|
| 需求分析（多轮对话 + PRD 生成） | ✅ 完整实现，支持 SSE 流式 | ❌ 未调用 |
| EARS 任务拆解 | ✅ 已实现 | ❌ 未调用 |
| 智能匹配推荐 | ✅ 有实现（依赖 Milvus） | ❌ 未调用 |
| LLM 客户端（Claude + 智谱） | ✅ 双模型支持 | — |
| 向量化（Embedding） | ✅ 已实现 | — |
| 项目管理 Agent | ⚠️ 有骨架 | ❌ 未调用 |
| 评分 Agent | ⚠️ 有骨架 | ❌ 未调用 |

---

## 五、下一步行动建议

按优先级排序，建议实施顺序：

1. **Go 后端新增 AI-Agent HTTP Client** — 把 AI 服务调用链路打通（1-2天）
2. **通知服务实现** — 4 个接口从 placeholder 改为真实实现（1天）
3. **AcceptBid 后触发通知 + 创建会话** — 撮合→通知→沟通流程串联（0.5天）
4. **Onboarding 增加手机号采集** — 前后端同步改（0.5天）
5. **订单自动创建** — AcceptBid 或确认后自动生成 Order（0.5天）
6. **前端通知列表页** — 展示通知列表 + 未读角标（1天）

**总计约 4-5 天可完成 MVP 核心流程串联。**
