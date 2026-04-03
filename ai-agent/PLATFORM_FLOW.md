# 开造平台 — 全流程详解（从注册到撮合完成）

> 本文档梳理整个平台的完整业务流程，覆盖三端：Flutter App（前端）、Go Server（业务后端）、Python AI Agent（AI 服务）。
> 标注【已实现】【占位】【未实现】表示当前代码状态。

---

## 全局流程总览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  Phase 0: 启动 & 引导                                                       │
│  ┌───────┐    ┌──────────┐    ┌──────────┐    ┌────────────────┐           │
│  │ Splash │───→│ Onboarding│───→│   登录    │───→│   选择角色      │           │
│  │  启动页 │    │  引导页   │    │ 手机/微信 │    │ 发起人 or 造物者 │           │
│  └───────┘    └──────────┘    └──────────┘    └───────┬────────┘           │
│                                                       │                     │
│                              ┌─────────────────────────┤                     │
│                              ▼                         ▼                     │
│  Phase 1A: 发起人 Onboarding              Phase 1B: 造物者 Onboarding        │
│  ┌──────────────────┐                    ┌──────────────────────┐           │
│  │ 填写基本信息       │                    │ 填写基本信息 + 技能    │           │
│  │ → 引导创建需求     │                    │ → 补充简历/作品集      │           │
│  │ → 引导填写需求     │                    │ → AI 评级定级(vc-T)   │           │
│  │ → 完成 ✅         │                    │ → 完成 ✅             │           │
│  └────────┬─────────┘                    └──────────┬───────────┘           │
│           │                                         │                       │
│           ▼                                         ▼                       │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │                        首页 (Home)                              │         │
│  │  底部 5 Tab: 首页 | 广场 | 消息 | 项目 | 我的                    │         │
│  └────────────────────────────────────────────────────────────────┘         │
│           │                                         │                       │
│           ▼                                         ▼                       │
│  Phase 2: 发起人发布需求                   Phase 2': 造物者浏览接造           │
│  ┌──────────────────┐                    ┌──────────────────────┐           │
│  │ AI 需求分析对话    │                    │ 广场浏览需求列表       │           │
│  │ → PRD 生成确认    │                    │ → 查看需求详情        │           │
│  │ → 架构设计        │                    │ → 投标报价            │           │
│  │ → 任务分解        │                    │                      │           │
│  │ → 项目管理方案    │                    │  或 收到智能推荐通知   │           │
│  │ → 需求发布到广场  │                    │  或 被一键派单         │           │
│  └────────┬─────────┘                    └──────────┬───────────┘           │
│           │                                         │                       │
│           ▼                                         ▼                       │
│  Phase 3: 撮合                                                              │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │  发起人查看投标列表 → 选择造物者 → 确认合作 → 创建订单         │            │
│  │  或: AI 智能推荐 → 发起人一键确认                              │            │
│  │  或: 急速匹配 → 系统自动派单                                   │            │
│  └────────────────────────────────────────┬────────────────────┘            │
│                                           │                                 │
│                                           ▼                                 │
│  Phase 4: 项目执行                                                          │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │  支付托管 → 里程碑管理 → EARS 任务看板 → IM 沟通               │            │
│  │  → AI 进度提醒 → 分阶段交付 → AI 质量检查 → 验收              │            │
│  └────────────────────────────────────────┬────────────────────┘            │
│                                           │                                 │
│                                           ▼                                 │
│  Phase 5: 完结                                                              │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │  全部里程碑验收通过 → 资金释放 → 双向评价 → 作品认证(可选)      │            │
│  └─────────────────────────────────────────────────────────────┘            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 0: 启动 & 登录注册

### 0.1 APP 启动

```
/splash → 检查本地 Token
  ├── Token 有效 → /home（直接进首页）
  ├── Token 过期 → POST /api/v1/auth/refresh 尝试续期
  │   ├── 成功 → /home
  │   └── 失败 → /onboarding
  └── 无 Token → /onboarding（引导页）
```

| 步骤 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 引导页 | `OnboardingPage` | 无 | 【已实现】 |
| 手机验证码 | `LoginPage` | `POST /api/v1/auth/sms-code` | 【已实现】 |
| 注册 | `LoginPage` | `POST /api/v1/auth/register` | 【已实现】 |
| 登录 | `LoginPage` | `POST /api/v1/auth/login` | 【已实现】 |
| 微信登录 | `LoginPage` | `POST /api/v1/auth/wechat` | 【占位】 |
| Token 刷新 | 自动 | `POST /api/v1/auth/refresh` | 【已实现】 |

### 0.2 注册流程细节

```
用户打开 APP
  → 3 页引导页滑动（介绍平台价值）
  → 输入手机号 → 获取验证码（60 秒倒计时）
  → 输入验证码 + 昵称
  → 选择角色：
      "我是发起人（我有需求）" → Role=1（demand）
      "我是造物者（我能开发）" → Role=2（provider）
  → 注册成功，拿到 JWT Token
  → 进入角色专属 Onboarding
```

**注册请求:**
```json
POST /api/v1/auth/register
{
  "phone": "13800138000",
  "sms_code": "123456",
  "nickname": "小李",
  "role": 1    // 1=发起人, 2=造物者
}
```

**返回:**
```json
{
  "user": { "uuid": "xxx", "nickname": "小李", "role": 1, "level": 1, "credit_score": 500 },
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 7200
}
```

---

## Phase 1A: 发起人 Onboarding（4 步）

```
/role-select → 选"我是发起人"
  → /onboard/demander/1  基本信息填写（行业、公司/个人）
  → /onboard/demander/2  引导页"如何创建需求"（教学）
  → /onboard/demander/3  引导页"如何填写需求"（教学）
  → /onboard/demander/4  完成页 → 进入首页
```

| 步骤 | 前端页面 | 说明 | 状态 |
|------|---------|------|------|
| Step 1 | `DemanderProfilePage` | 填写基本信息 | 【已实现】 |
| Step 2 | `DemanderGuideCreatePage` | 教学：怎么创建需求 | 【已实现】 |
| Step 3 | `DemanderGuideFillPage` | 教学：怎么填写需求 | 【已实现】 |
| Step 4 | `DemanderCompletePage` | 完成引导，进首页 | 【已实现】 |

---

## Phase 1B: 造物者 Onboarding（3 步）

```
/role-select → 选"我是造物者"
  → /onboard/expert/1  基本信息 + 技能选择 + 作品链接
  → /onboard/expert/2  补充简历（上传简历文件或填写经历）
  → /onboard/expert/3  AI 自动评级 → 展示 vc-T 等级结果
  → 进入首页
```

| 步骤 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| Step 1 | `ExpertProfilePage` | `PUT /api/v1/users/me` + `PUT /api/v1/users/me/skills` | 【占位】 |
| Step 2 | `ExpertSupplementPage` | `POST /api/v1/upload`（简历） | 【占位】 |
| Step 3 | `ExpertLevelPage` | `POST /api/v2/rating/evaluate/file` (AI Agent) | 【已实现】 |

**AI 评级接口:**
```
POST /api/v2/rating/evaluate/file   ← 上传简历文件
POST /api/v2/rating/evaluate/text   ← 纯文本简历
```

返回 vc-T1~T5 等级 + 五维度雷达图数据 + 升级建议。

---

## Phase 2: 发起人发布需求

这是平台最核心的流程，AI Agent 全程驱动。

### 2.1 入口

发起人在首页点击 **"发布需求"** 或 **"AI 帮我梳理需求"** 按钮。

### 2.2 AI 需求分析对话（3 阶段流水线）

> **注意**：PM 方案不再属于需求分析流水线。PM 在撮合完成后由 lifecycle hook 自动生成（见 Phase 4）。

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  Stage 1: 需求分析（多轮对话，2-3 轮）                              │
│  ┌─────────────────────────────────────────────────────────┐      │
│  │ 用户: "我想做一个在线教育平台"                              │      │
│  │ AI: 返回结构化选择题（单选/多选/文本/数字）                  │      │
│  │ 用户: 选择答案，提交                                       │      │
│  │ AI: 返回下一轮问题，维度进度更新                            │      │
│  │ ... 重复 2-3 轮 ...                                       │      │
│  │ AI: completeness_score ≥ 80 → 自动生成 PRD                │      │
│  └─────────────────────────────────────────────────────────┘      │
│  用户确认 PRD → 自动拆解 EARS 任务                                 │
│  ✅ 产出: requirement.md                                          │
│                                                                   │
│  Stage 2: 架构设计（一键生成）                                      │
│  AI 读取 requirement.md → 生成系统架构 + API 设计 + 数据模型        │
│  用户确认                                                          │
│  ✅ 产出: design.md                                               │
│                                                                   │
│  Stage 3: 任务分解（一键生成）                                      │
│  AI 读取前两份文档 → 按模块拆分任务 + 双节奏估时                    │
│  用户确认 → 需求分析流水线完成，可以发布到广场                       │
│  ✅ 产出: task.md                                                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

| 阶段 | 接口 | 说明 | 状态 |
|------|------|------|------|
| 需求分析-首轮 | `POST /api/v2/requirement/start` | 创建项目 + 第一轮对话 | 【已实现】 |
| 需求分析-多轮 | `POST /api/v2/requirement/{id}/message` | 继续补充需求 | 【已实现】 |
| 需求分析-确认 | `POST /api/v2/requirement/{id}/confirm` | 确认 PRD → EARS 拆解 | 【已实现】 |
| 架构设计-生成 | `POST /api/v2/design/{id}/start` | 一键生成 | 【已实现】 |
| 架构设计-确认 | `POST /api/v2/design/{id}/confirm` | 确认 | 【已实现】 |
| 任务分解-生成 | `POST /api/v2/task/{id}/start` | 一键生成 | 【已实现】 |
| 任务分解-确认 | `POST /api/v2/task/{id}/confirm` | 确认 → 流水线完成 | 【已实现】 |
| 查看文档 | `GET /api/v2/{stage}/{id}/document` | 获取 Markdown 文档 | 【已实现】 |
| 查看进度 | `GET /api/v2/pipeline/{id}/status` | 全局状态 | 【已实现】 |

### 2.3 需求发布到广场

AI 需求分析流水线（3 阶段）完成后，需求方确认发布：

```
AI 产出 3 份文档（requirement.md + design.md + task.md）
  → 前端展示项目摘要（标题、预算、工期、技术栈、复杂度）
  → 发起人选择匹配模式：
      ○ 公开投标（发到广场，等造物者投标）
      ○ 智能推荐（AI 推荐 Top N 造物者，发起人选择）
      ○ 急速匹配（AI 自动分配最佳造物者）
  → 确认发布
```

> **注意**：PM 方案（project-plan.md）不在发布前生成。它需要知道造物者是谁、商定价格、商定工期，
> 这些只有在撮合完成后才有。见 Phase 4。

| 操作 | 后端接口 | 状态 |
|------|---------|------|
| 创建项目（Go Server） | `POST /api/v1/projects` | 【已实现】 |
| AI 辅助填充 PRD | `POST /api/v1/projects/{id}/ai-assist` | 【占位】 |
| 项目列表 | `GET /api/v1/projects` | 【已实现】 |
| 项目详情 | `GET /api/v1/projects/{id}` | 【已实现】 |

> **关键衔接点**: AI Agent 产出的文档需要同步到 Go Server 的 Project 记录中（`ai_prd` / `confirmed_prd` 字段）。
> 当前 AI Agent 和 Go Server 是独立的，需要在发布时做一次数据同步。

---

## Phase 2': 造物者浏览与接造

造物者侧的流程相对简单：

```
造物者进入首页
  → 底部 Tab "广场" → 浏览需求列表
  → 筛选：类别、预算范围、技术栈、复杂度
  → 点进需求详情 → 查看 PRD 概览 + EARS 任务树
  → 决定投标 → 填写投标表单
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 浏览广场 | `MarketPage` | `GET /api/v1/projects` | 【已实现】 |
| 需求详情 | `ProjectDetailPage` | `GET /api/v1/projects/{id}` | 【已实现】 |
| PRD 详情 | `PrdPage` | `GET /api/v2/requirement/{id}/document` | 【已实现】 |
| 投标 | `BidFormPage` | `POST /api/v1/projects/{id}/bids` | 【占位】 |
| 查看投标 | `BidListPage` | `GET /api/v1/projects/{id}/bids` | 【占位】 |

**投标提交数据:**
```json
{
  "price": 3000,
  "estimated_days": 14,
  "proposal": "我有3年在线教育开发经验...",
  "tech_solution": "React + Node.js + MySQL，使用 Cursor 辅助开发"
}
```

---

## Phase 3: 撮合

### 3.1 三种撮合模式

#### 模式 A：公开投标（默认）

```
发起人发布需求 → 需求出现在广场
  → 造物者 A 投标 ¥3000 / 14天
  → 造物者 B 投标 ¥2500 / 10天
  → 造物者 C 投标 ¥4000 / 7天
  → 发起人在投标列表中查看、对比
  → 发起人选择造物者 B → 确认
```

#### 模式 B：AI 智能推荐

```
发起人发布需求，选"智能推荐"
  → POST /api/v2/match/recommend
  → AI 基于技能匹配度(30%) + 评级(25%) + 价格(20%) + 交付能力(15%) + 响应速度(10%) 打分
  → 返回 Top 5 造物者推荐列表 + 推荐理由
  → 发起人选择 → 确认
```

#### 模式 C：急速匹配

```
发起人选"急速匹配"
  → POST /api/v1/projects/{id}/quick-match
  → 系统自动匹配最佳造物者
  → 发送邀请通知 → 造物者 24 小时内响应
  → 接受 → 自动创建合作关系
```

### 3.2 撮合确认

```
发起人选定造物者
  → 系统展示合作详情（价格、工期、里程碑、付款计划）
  → 发起人确认 → 创建订单
  → 进入支付流程
```

| 操作 | 后端接口 | 状态 |
|------|---------|------|
| AI 推荐 | `POST /api/v2/match/recommend` (AI Agent) | 【已实现】 |
| 急速匹配 | `POST /api/v1/projects/{id}/quick-match` | 【占位】 |
| 接受投标 | `PUT /api/v1/bids/{id}/accept` | 【占位】 |
| AI 推荐造物者 | `GET /api/v1/projects/{id}/recommendations` | 【占位】 |

---

## Phase 4: 项目执行

### 4.0 撮合完成 → AI 自动生成 PM 方案（Lifecycle Hook）

```
发起人选定造物者 → Go 后端 BidService.Accept()
  → 异步调用 AI Agent: POST /api/v2/lifecycle/on-matched
  → AI Agent 加载 requirement.md + design.md + task.md
  → 注入撮合信息（商定价格、工期、造物者信息）
  → PM Agent 自动生成 project-plan.md（含里程碑计划）
  → 返回结构化里程碑数据 → Go 后端存入 milestones 表
```

| 操作 | 接口 | 说明 | 状态 |
|------|------|------|------|
| 撮合完成 Hook | `POST /api/v2/lifecycle/on-matched` | 自动生成 PM 方案 | 【已实现】 |
| 支付完成 Hook | `POST /api/v2/lifecycle/on-started` | 预留 | 【占位】 |
| 里程碑交付 Hook | `POST /api/v2/lifecycle/on-milestone-delivered` | 预留 | 【占位】 |
| 项目完成 Hook | `POST /api/v2/lifecycle/on-completed` | 预留 | 【占位】 |
| 查看 PM 文档 | `GET /api/v2/pm/{id}/document` | 获取已生成的 PM 方案 | 【已实现】 |
| 重新生成 PM | `POST /api/v2/pm/{id}/regenerate` | 工期/价格调整后重新生成 | 【已实现】 |

**Go 后端适配说明**：`BidService.Accept()` 需在 bid 接受后异步调用 AI Agent：
```go
// bid_service.go Accept() 末尾 — 异步触发 AI PM 生成
go s.callAIOnMatched(project.UUID, *bid.BidderID, bid.ID, bid.Price, bid.EstimatedDays)
```

### 4.1 支付托管

```
撮合确认 → 创建订单
  → 选择支付方式（微信 / 支付宝）
  → 支付 → 资金进入平台托管
  → 支付成功 → 项目状态变为"进行中"
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 确认订单 | `OrderConfirmPage` | `POST /api/v1/orders` | 【占位】 |
| 微信支付回调 | - | `POST /api/v1/orders/callback/wechat` | 【占位】 |
| 支付宝回调 | - | `POST /api/v1/orders/callback/alipay` | 【占位】 |
| 支付结果 | `PaymentResultPage` | - | 【已实现-前端】 |

### 4.2 项目管理看板

```
支付完成 → 项目正式开工
  → 造物者在 ProjectManagePage 看到：
      - EARS 任务看板（待办 / 进行中 / 已完成）
      - 里程碑时间线
      - 每日 AI 进度摘要
  → 发起人看到：
      - 概览视图（模块进度、完成百分比）
      - 里程碑进度条
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 项目管理 | `ProjectManagePage` | `GET /api/v1/projects/{id}/overview` | 【占位】 |
| 任务列表 | - | `GET /api/v1/projects/{id}/tasks` | 【占位】 |
| 更新任务状态 | - | `PUT /api/v1/tasks/{id}/status` | 【占位】 |
| 里程碑列表 | - | `GET /api/v1/projects/{id}/milestones` | 【占位】 |
| 每日报告 | - | `GET /api/v1/projects/{id}/daily-reports` | 【占位】 |

### 4.3 IM 沟通

```
撮合成功 → 自动创建对话
  → 发起人和造物者在 ChatDetailPage 沟通
  → 支持文字、图片、文件
  → AI 翻译助手（非技术语言 → 技术语言）
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 会话列表 | `ConversationListPage` | `GET /api/v1/conversations` | 【占位】 |
| 聊天详情 | `ChatDetailPage` | `GET /api/v1/conversations/{id}/messages` | 【占位】 |
| 发消息 | - | `POST /api/v1/conversations/{id}/messages` | 【占位】 |
| AI 对话助手 | - | `POST /api/v2/chat/message` (AI Agent) | 【已实现】 |

### 4.4 分阶段交付与验收

```
造物者完成里程碑 1
  → 提交交付物（预览链接 + 说明）
  → AI 自动质量检查（代码规范、功能检查）
  → 发起人收到通知
  → 打开 AcceptancePage：
      - 在线预览
      - 对照验收标准逐项打勾
      - 通过 → 释放该里程碑资金
      - 不通过 → 提修改请求 → 造物者修改 → 重新提交
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 提交交付 | - | `POST /api/v1/milestones/{id}/deliver` | 【占位】 |
| 验收 | `AcceptancePage` | `PUT /api/v1/milestones/{id}/accept` | 【占位】 |
| 释放资金 | - | `POST /api/v1/orders/{id}/release` | 【占位】 |

---

## Phase 5: 完结

### 5.1 项目完成

```
全部里程碑验收通过
  → 项目状态 → "已完成"
  → 剩余托管资金全部释放给造物者
  → 触发双向评价
```

### 5.2 双向评价

```
发起人评价造物者：
  - 代码质量 ⭐⭐⭐⭐⭐
  - 沟通效率 ⭐⭐⭐⭐⭐
  - 交付时效 ⭐⭐⭐⭐⭐
  - 文字评价

造物者评价发起人：
  - 需求清晰度 ⭐⭐⭐⭐⭐
  - 反馈及时性 ⭐⭐⭐⭐⭐
  - 付款及时性 ⭐⭐⭐⭐⭐
  - 文字评价

评价影响：
  → 造物者: VibePower 积分变动 → vc-T 等级升降
  → 发起人: 信用分变动
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 评价 | `RatePage` | `POST /api/v1/projects/{id}/reviews` | 【占位】 |
| VibePower 调整 | - | `POST /api/v2/rating/{id}/adjust` (AI Agent) | 【已实现】 |
| 查看评价 | - | `GET /api/v1/users/{id}/reviews` | 【占位】 |

### 5.3 资金提现

```
造物者收到项目收入
  → 钱包余额增加
  → 可提现到微信/支付宝
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 钱包 | `WalletPage` | `GET /api/v1/wallet/balance` | 【占位】 |
| 提现 | - | `POST /api/v1/wallet/withdraw` | 【占位】 |
| 流水 | - | `GET /api/v1/wallet/transactions` | 【占位】 |

---

## 附加功能：组队

造物者可以组队接造大型项目：

```
造物者 A 在"组队大厅"发帖："招前端，React 项目，分成 40%"
  → 造物者 B 看到帖子 → 申请加入
  → A 确认 → 组队成功
  → 团队可以整体投标
  → 项目完成后按比例分账
```

| 操作 | 前端页面 | 后端接口 | 状态 |
|------|---------|---------|------|
| 组队大厅 | `TeamHallPage` | `GET /api/v1/team-posts` | 【占位】 |
| 发布组队帖 | `CreateTeamPostPage` | `POST /api/v1/team-posts` | 【占位】 |
| 确认组队 | `TeamConfirmPage` | `POST /api/v1/teams` | 【占位】 |
| 团队投标 | - | `POST /api/v1/projects/{id}/bids`（带 team_id） | 【占位】 |
| 分账 | - | `POST /api/v1/orders/{id}/split` | 【占位】 |

---

## 系统架构衔接关系

```
┌─────────────┐       ┌─────────────┐       ┌─────────────────┐
│  Flutter App │◄─────►│  Go Server  │◄─────►│  Python AI Agent │
│  (前端)      │       │  (业务后端)  │       │  (AI 服务)       │
│              │       │              │       │                  │
│ /api/v1/*    │───────│ 认证/用户/   │       │                  │
│              │       │ 项目/投标/   │       │                  │
│              │       │ 订单/支付/   │       │                  │
│              │       │ 沟通/评价    │       │                  │
│              │       │              │       │                  │
│ /api/v2/*    │───────┼──────────────┼──────►│ 需求分析 Agent   │
│              │       │              │       │ 设计 Agent       │
│              │       │              │       │ 任务 Agent       │
│              │       │              │       │ PM Agent         │
│              │       │              │       │ 评级 Agent       │
│              │       │              │       │ 匹配 Agent       │
│              │       │              │       │ 对话 Agent       │
└─────────────┘       └─────────────┘       └─────────────────┘

数据库:
├── PostgreSQL (Go Server): users, projects, bids, orders, milestones, tasks...
├── MySQL (AI Agent): projects, documents, provider_profiles, vibe_power_logs...
└── Redis: sessions, cache, rate-limit
```

> **当前最大的衔接缺口**：AI Agent 产出的文档和 Go Server 的 Project 数据是两套独立存储。
> 发布需求时需要一个同步机制，将 AI Agent 的 `requirement.md` / `design.md` 等文档内容同步到 Go Server 的 `confirmed_prd` 字段。

---

## 实现完成度汇总

| 模块 | 已实现 | 占位 | 未实现 | 说明 |
|------|--------|------|--------|------|
| 认证登录 | ✅ | 微信登录 | - | Go Server 核心已完成 |
| 用户管理 | 部分 | 大部分 | - | 注册/登录完成，个人资料接口占位 |
| AI 需求分析 | ✅ | - | - | 3 阶段流水线完成，PM 由 lifecycle hook 触发 |
| AI 评级 | ✅ | - | - | vc-T 十级体系完成 |
| AI 匹配 | ✅ | - | - | 推荐接口完成 |
| AI 对话 | ✅ | - | - | 意图识别+多轮对话完成 |
| 项目 CRUD | ✅ | 搜索 | - | Go Server 基本 CRUD 完成 |
| 投标系统 | - | ✅ | - | 全部占位 |
| 支付系统 | - | ✅ | - | 全部占位 |
| 沟通系统 | - | ✅ | - | 全部占位 |
| 验收系统 | - | ✅ | - | 全部占位 |
| 评价系统 | - | ✅ | - | 全部占位 |
| 钱包系统 | - | ✅ | - | 全部占位 |
| 团队系统 | - | ✅ | - | 全部占位 |
| 通知系统 | - | ✅ | - | 全部占位 |
| 管理后台 | - | ✅ | - | 全部占位 |
| 前端页面 | ✅ | - | - | Flutter 全部页面骨架已搭建 |
