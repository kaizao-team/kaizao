# 开造 AI Agent — 前端联调接口文档

> 更新日期: 2026-03-31
> Base URL: `http://47.236.165.75:39528`
> Swagger UI: `http://47.236.165.75:39528/docs`
> 所有接口统一前缀: `/api/v2`
> 总计 **33 个接口**，覆盖 9 个模块

---

## 调用方标记说明

每个接口标注了**谁来调用**和**在哪个页面调用**：

| 标记 | 含义 |
|------|------|
| `🖥️ 前端` | 前端 Flutter App 直接调用 |
| `🔧 Go后端` | Go 后端服务间调用，前端**不需要**调用 |
| `🔑 管理端` | 管理后台调用，普通用户前端**不需要**调用 |

---

## 目录

1. [通用约定](#1-通用约定)
2. [流水线管理 Pipeline](#2-流水线管理-pipeline)
3. [需求分析 Requirement](#3-需求分析-requirement)
4. [架构设计 Design](#4-架构设计-design)
5. [任务拆解 Task](#5-任务拆解-task)
6. [项目管理 PM](#6-项目管理-pm)
7. [生命周期 Lifecycle](#7-生命周期-lifecycle-go-后端调用)
8. [智能撮合 Match](#8-智能撮合-match)
9. [对话助手 Chat](#9-对话助手-chat)
10. [团队评级 Rating](#10-团队评级-rating)
11. [前端页面 → 接口映射总表](#11-前端页面--接口映射总表)
12. [前端调用时序](#12-前端调用时序)

---

## 1. 通用约定

### 统一响应结构

所有接口返回格式：

```json
{
  "code": 0,
  "message": "success",
  "data": { ... },
  "request_id": "abc123"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | int | 0=成功，非 0=错误 |
| `message` | string | 成功时为 "success"，失败时为错误描述 |
| `data` | any | 业务数据，失败时为 null |
| `request_id` | string | 请求追踪 ID，可传 Header `X-Request-ID` |

### 通用错误码

| code | 含义 |
|------|------|
| 0 | 成功 |
| 40001 | 前置阶段未完成（阶段守卫拦截） |
| 40002 | 文档尚未生成 |
| 40401 | 项目不存在 |
| 50001 | 编排器未初始化 |
| 50002 | AI 匹配服务异常 |
| 50003 | AI 生成失败 |
| 50004 | PM 生成失败 |

### SSE 流式接口约定

路径以 `/stream` 结尾的接口返回 `text/event-stream`：

```
event: init
data: {"project_id": "xxx", "session_id": "xxx"}

event: chunk
data: {"content": "正在分析..."}

event: done
data: {"project_id": "xxx", "agent_message": "...", ...}

event: error
data: {"code": 50003, "message": "生成失败"}
```

### project_id 说明

`project_id` 统一使用 **Go 后端 `projects.uuid`**（36 位 UUID 字符串），不是自增 ID。

---

## 2. 流水线管理 Pipeline

> 管理项目的 AI 流水线生命周期

### 2.1 初始化流水线

> `🖥️ 前端` — **发布需求页 (PostPage)** 用户开始 AI 对话前调用，初始化流水线
>
> ⚠️ 此接口**不创建项目**。`project_id` 必须是 Go 后端已创建的项目 UUID。AI Agent 仅在 `ai_project_stages` 表中初始化阶段状态。

```
POST /api/v2/pipeline/start
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `project_id` | string | ✅ | Go 后端 projects.uuid（必须已存在） |
| `title` | string | 否 | 项目标题，默认空 |

**请求示例：**

```json
{
  "project_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "智能客服系统"
}
```

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "current_stage": "requirement",
  "stages": {
    "requirement": { "status": "pending" },
    "design": { "status": "pending" },
    "task": { "status": "pending" },
    "pm": { "status": "pending" }
  }
}
```

---

### 2.2 查询流水线状态

> `🖥️ 前端` — **项目详情页 (ProjectDetailPage)** / **PRD文档页 (PrdPage)** 查询当前进度

```
GET /api/v2/pipeline/{project_id}/status
```

**响应 `data`：** 同 2.1 响应结构

---

### 2.3 获取所有已生成文档

> `🖥️ 前端` — **项目详情页 (ProjectDetailPage)** / **PRD文档页 (PrdPage)** 展示所有 AI 文档

```
GET /api/v2/pipeline/{project_id}/documents
```

**响应 `data`：**

```json
{
  "documents": [
    {
      "stage": "requirement",
      "filename": "requirement.md",
      "path": "outputs/550e8400-.../v1/requirement.md",
      "size": 4096,
      "content": "# 需求文档\n..."
    }
  ]
}
```

---

## 3. 需求分析 Requirement

> 多轮对话收集需求 → 生成 PRD → 确认 PRD（发布/撮合/确认合作后再触发 EARS 拆解）

### 3.1 初始化 AI 流水线 + 首轮对话

> `🖥️ 前端` — **发布需求页 (PostPage)** 用户输入第一条需求描述时调用
>
> ⚠️ 此接口**不创建项目**。项目由 Go 后端创建并返回 `project_id`(UUID)，前端拿到后传给 AI Agent 初始化流水线。

```
POST /api/v2/requirement/start
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `project_id` | string | ✅ | Go 后端 projects.uuid |
| `message` | string | ✅ | 用户首条需求描述 |
| `title` | string | 否 | 项目标题 |

**请求示例：**

```json
{
  "project_id": "550e8400-...",
  "message": "我想做一个在线教育平台，支持直播和录播课程",
  "title": "在线教育平台"
}
```

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "session_id": "sess_abc123",
  "agent_message": "好的，我来帮您梳理需求。请问目标用户群体是...",
  "sub_stage": "gathering",
  "completeness_score": 25,
  "tool_result": { ... },
  "questions": ["目标用户群体是？", "课程类型有哪些？"],
  "dimension_coverage": {
    "functional": 0.2,
    "non_functional": 0.0,
    "business": 0.1,
    "technical": 0.0
  }
}
```

**字段说明：**

| 字段 | 说明 |
|------|------|
| `sub_stage` | `gathering`（收集中）→ `reviewing`（审查中）→ `confirmed`（已确认） |
| `completeness_score` | 0-100，达到阈值后前端可提示"需求已充分，可以确认" |
| `questions` | AI 追问的问题列表，前端可展示引导用户回答 |
| `dimension_coverage` | 四个维度的覆盖率（功能/非功能/商业/技术） |

---

### 3.2 多轮需求对话

> `🖥️ 前端` — **发布需求页 (PostPage)** AI 对话区域，用户每次回复调用

```
POST /api/v2/requirement/{project_id}/message
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `message` | string | ✅ | 用户回复内容 |

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "agent_message": "明白了。关于支付方式，您希望...",
  "sub_stage": "gathering",
  "completeness_score": 60,
  "tool_name": "analyze_requirement",
  "questions": ["支付方式有哪些？"],
  "dimension_coverage": { ... }
}
```

---

### 3.3 确认 PRD

> `🖥️ 前端` — **发布需求页 (PostPage)** 需求收集完毕，用户点击「确认 PRD」
>
> ⚠️ 此接口**仅确认 PRD**，不触发 EARS 拆解。EARS 拆解在撮合成功、确认合作后由 3.5 接口触发。

```
POST /api/v2/requirement/{project_id}/confirm
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `feedback` | string | 否 | 最终修改意见 |

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "sub_stage": "prd_confirmed",
  "completeness_score": 100
}
```

---

### 3.4 获取需求文档

> `🖥️ 前端` — **PRD文档页 (PrdPage)** / **项目详情页 (ProjectDetailPage)** 查看需求文档内容

```
GET /api/v2/requirement/{project_id}/document
```

**响应 `data`：**

```json
{
  "filename": "requirement.md",
  "path": "outputs/550e8400-.../v1/requirement.md",
  "size": 8192,
  "content": "# 需求规格说明书\n\n## 1. 项目概述\n..."
}
```

---

### 3.5 触发 EARS 拆解

> `🔧 Go后端` — 确认合作后由 Go 后端调用，前端**不直接调用**
>
> 业务流程：确认PRD → 发布项目 → 撮合匹配 → 确认合作 → **调用此接口** → EARS 拆解 → 生成 requirement.md

```
POST /api/v2/requirement/{project_id}/decompose
```

**请求体：** 无

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "sub_stage": "ears_decomposing",
  "ears_status": "processing"
}
```

> 后台异步执行 EARS 拆解，通过 `GET /pipeline/{project_id}/status` 轮询 `sub_stage` 变为 `tasks_ready` 表示完成。

---

### 3.6-3.8 流式接口（SSE）

> `🖥️ 前端` — 推荐使用流式版本，实时展示 AI 输出

| 接口 | 对应普通接口 | 请求体 | 调用方 |
|------|-------------|--------|--------|
| `POST /api/v2/requirement/start/stream` | 同 3.1 | 同 3.1 | 🖥️ 前端 |
| `POST /api/v2/requirement/{project_id}/message/stream` | 同 3.2 | 同 3.2 | 🖥️ 前端 |
| `POST /api/v2/requirement/{project_id}/decompose/stream` | 同 3.5 | 无 | 🔧 Go后端 |

返回 `text/event-stream`，事件格式参见 [SSE 约定](#sse-流式接口约定)。

---

## 4. 架构设计 Design

> 基于需求文档自动生成技术架构方案

### 4.1 启动架构设计

> `🖥️ 前端` — **发布需求页 (PostPage)** 需求确认后自动进入设计阶段，或**项目详情页 (ProjectDetailPage)** 手动触发

```
POST /api/v2/design/{project_id}/start
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `feedback` | string | 否 | 对设计方案的额外要求 |

**前置条件：** requirement 阶段已 confirmed（否则返回 code=40001）

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "agent_message": "架构设计方案已生成",
  "tool_name": "write_design_doc",
  "document_path": "outputs/550e8400-.../v1/design.md"
}
```

---

### 4.2 确认架构设计

> `🖥️ 前端` — **发布需求页 (PostPage)** / **项目详情页 (ProjectDetailPage)** 用户确认设计方案

```
POST /api/v2/design/{project_id}/confirm
```

**请求体：** 无

**前置条件：** design 文档已生成（否则返回 code=40002）

**响应 `data`：** 流水线状态摘要（同 2.1 格式）

---

### 4.3 获取设计文档

> `🖥️ 前端` — **PRD文档页 (PrdPage)** / **项目详情页 (ProjectDetailPage)** 查看设计文档

```
GET /api/v2/design/{project_id}/document
```

**响应 `data`：**

```json
{
  "filename": "design.md",
  "path": "outputs/550e8400-.../v1/design.md",
  "size": 12288,
  "content": "# 技术架构设计\n..."
}
```

---

### 4.4 流式启动（SSE）

> `🖥️ 前端` — **发布需求页 (PostPage)** / **项目详情页 (ProjectDetailPage)** 推荐使用流式版本

```
POST /api/v2/design/{project_id}/start/stream
```

请求体同 4.1，返回 SSE 流。

---

## 5. 任务拆解 Task

> 基于需求 + 设计文档拆解为可执行任务

### 5.1 启动任务拆解

> `🖥️ 前端` — **发布需求页 (PostPage)** 设计确认后自动进入任务阶段，或**项目详情页 (ProjectDetailPage)** 手动触发

```
POST /api/v2/task/{project_id}/start
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `feedback` | string | 否 | 对任务拆解的额外要求 |

**前置条件：** design 阶段已 confirmed（否则返回 code=40001）

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "agent_message": "任务拆解完成，共 8 个模块 23 个子任务",
  "tool_name": "write_task_doc",
  "document_path": "outputs/550e8400-.../v1/task.md"
}
```

---

### 5.2 确认任务文档

> `🖥️ 前端` — **发布需求页 (PostPage)** / **项目详情页 (ProjectDetailPage)** 确认任务拆解 → 流水线完成

```
POST /api/v2/task/{project_id}/confirm
```

**请求体：** 无

**前置条件：** task 文档已生成

**响应 `data`：** 流水线状态摘要

> **重要：** 确认后 3 阶段流水线结束，返回消息提示"需求分析流水线已完成，可以发布到广场"。PM 方案不在此阶段生成，而是在撮合完成后由 lifecycle hook 自动触发。

---

### 5.3 获取任务文档

> `🖥️ 前端` — **PRD文档页 (PrdPage)** / **项目详情页 (ProjectDetailPage)** 查看任务文档

```
GET /api/v2/task/{project_id}/document
```

**响应 `data`：**

```json
{
  "filename": "task.md",
  "path": "outputs/550e8400-.../v1/task.md",
  "size": 10240,
  "content": "# 任务拆解清单\n..."
}
```

---

### 5.4 流式启动（SSE）

> `🖥️ 前端` — **发布需求页 (PostPage)** / **项目详情页 (ProjectDetailPage)** 推荐使用流式版本

```
POST /api/v2/task/{project_id}/start/stream
```

请求体同 5.1，返回 SSE 流。

---

## 6. 项目管理 PM

> PM 方案由 lifecycle hook（on-matched）自动生成，前端不需手动触发生成

### 6.1 获取 PM 文档

> `🖥️ 前端` — **项目管理页 (ProjectManagePage)** / **项目详情页 (ProjectDetailPage)** 撮合成功后查看 PM 方案

```
GET /api/v2/pm/{project_id}/document
```

**响应 `data`：**

```json
{
  "filename": "project-plan.md",
  "path": "outputs/550e8400-.../v1/project-plan.md",
  "size": 15360,
  "content": "# 项目管理方案\n\n## 里程碑计划\n..."
}
```

> 如果项目尚未撮合成功，此接口返回 code=40002

---

### 6.2 重新生成 PM 方案

> `🖥️ 前端` — **项目管理页 (ProjectManagePage)** 工期/价格协商调整后重新生成

```
POST /api/v2/pm/{project_id}/regenerate
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agreed_price` | float | ✅ | 商定价格 |
| `agreed_days` | int | ✅ | 商定工期（天） |
| `feedback` | string | 否 | 调整原因或额外要求 |

**前置条件：** PM 文档已存在（首次由 on-matched hook 生成）

**请求示例：**

```json
{
  "agreed_price": 50000.00,
  "agreed_days": 45,
  "feedback": "甲方要求前端先行交付"
}
```

**响应 `data`：** PM 生成结果（含里程碑数据）

---

## 7. 生命周期 Lifecycle（Go 后端调用）

> ⚠️ 以下接口由 **Go 后端** 在业务节点异步调用，**前端无需直接调用**。列出仅供了解全链路流程。

### 7.1 撮合完成 Hook

> `🔧 Go后端` — Go `BidService.Accept()` 事务提交后异步调用，前端**不调用**

```
POST /api/v2/lifecycle/on-matched
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `project_id` | string | ✅ | projects.uuid |
| `provider_id` | int | ✅ | 造物者 user_id |
| `bid_id` | int | ✅ | 中标的 bid ID |
| `agreed_price` | float | ✅ | 商定价格 |
| `agreed_days` | int | ✅ | 商定工期（天） |
| `provider_info` | object | 否 | 造物者补充信息 |

**触发行为：** 自动加载 3 份前序文档 → PM Agent 生成项目管理方案 → 返回结构化里程碑

**响应 `data`：**

```json
{
  "project_id": "550e8400-...",
  "pm_document_path": "outputs/550e8400-.../v1/project-plan.md",
  "milestones": [
    {
      "title": "需求确认与原型设计",
      "duration_days": 7,
      "payment_ratio": 0.2
    },
    {
      "title": "核心功能开发",
      "duration_days": 20,
      "payment_ratio": 0.5
    }
  ]
}
```

---

### 7.2-7.4 占位 Hook（当前返回 200）

> `🔧 Go后端` — 全部由 Go 后端在业务节点自动调用，前端**不调用**

| 接口 | 请求体 | 触发时机 |
|------|--------|---------|
| `POST /api/v2/lifecycle/on-started` | `{project_id, order_id?}` | 托管支付成功 |
| `POST /api/v2/lifecycle/on-milestone-delivered` | `{project_id, milestone_id?}` | 造物者提交交付物 |
| `POST /api/v2/lifecycle/on-completed` | `{project_id}` | 全部里程碑验收 |

---

## 8. 智能撮合 Match

> 基于向量检索 + 多维评分为需求推荐专家

### 8.1 智能匹配推荐

> `🖥️ 前端` — **项目详情页 (ProjectDetailPage)** 项目发布后（status=2），需求方查看 AI 推荐的专家列表；仅 match_mode=2（AI推荐）或 3（混合）时调用

```
POST /api/v2/match/recommend
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `demand_id` | string | ✅ | 项目 UUID（projects.uuid） |
| `match_type` | string | 否 | 默认 `"recommend_providers"` |
| `user_id` | string | 否 | 当前用户 ID |
| `filters` | object | 否 | 筛选条件 |
| `pagination` | object | 否 | 分页参数 |

**filters 可选字段：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_verified_only` | bool | 仅已认证用户（credit_score >= 600） |

**pagination 字段：**

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `page` | int | 1 | 页码 |
| `page_size` | int | 10 | 每页数量（最大 20） |

**请求示例：**

```json
{
  "demand_id": "550e8400-...",
  "filters": { "is_verified_only": true },
  "pagination": { "page": 1, "page_size": 5 }
}
```

**响应 `data`（匹配成功）：**

```json
{
  "demand_id": "550e8400-...",
  "match_type": "recommend_providers",
  "recommendations": [
    {
      "provider_id": "user-uuid-001",
      "rank": 1,
      "match_score": 87.5,
      "recommendation_reason": "技能匹配度高、历史好评良好",
      "highlight_skills": ["Flutter", "Go", "Vue.js"],
      "similar_project_reference": "",
      "dimension_scores": {
        "skill_match": 92.0,
        "rating": 85.0,
        "price_match": 78.0,
        "response_speed": 90.0,
        "portfolio_similarity": 72.0
      }
    }
  ],
  "overall_suggestion": "建议优先与排名前3的供给方沟通...",
  "no_match_reason": null,
  "meta": {
    "total_candidates_scanned": 50,
    "processing_time_ms": 1200,
    "rag_references_used": 0
  }
}
```

**响应 `data`（匹配失败）：**

```json
{
  "demand_id": "550e8400-...",
  "recommendations": [],
  "no_match_reason": "暂未找到高度匹配的供给方，建议适当放宽技术栈要求或调整预算范围。",
  "meta": { "total_candidates_scanned": 50, "processing_time_ms": 800 }
}
```

**评分维度说明：**

| 维度 | 权重 | 说明 |
|------|------|------|
| `skill_match` | 30% | 技术栈匹配度 |
| `rating` | 25% | 历史评价和完成率 |
| `price_match` | 20% | 报价与预算匹配 |
| `response_speed` | 15% | 平均响应速度 |
| `portfolio_similarity` | 10% | 作品集相似度 |

---

## 9. 对话助手 Chat

> 通用对话入口，支持意图识别、多轮对话、Agent 转交

### 9.1 发送对话消息

> `🖥️ 前端` — **AI 对话页 (ChatDetailPage)** 全局悬浮入口，任意页面可唤起

```
POST /api/v2/chat/message
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `session_id` | string | ✅ | 对话会话 ID（前端生成 UUID） |
| `user_id` | string | ✅ | 用户 UUID |
| `user_role` | string | 否 | `"demander"` / `"expert"` / `"unknown"`，默认 unknown |
| `message` | object | ✅ | 消息内容 |
| `page_context` | object | 否 | 当前页面上下文 |

**message 结构：**

```json
{
  "type": "text",
  "content": "帮我找一个会 Flutter 的开发"
}
```

**page_context 结构：**

```json
{
  "page": "home",
  "project_id": null
}
```

**请求示例：**

```json
{
  "session_id": "chat_abc123",
  "user_id": "user-uuid-001",
  "user_role": "demander",
  "message": {
    "type": "text",
    "content": "帮我找一个会 Flutter 的开发"
  },
  "page_context": {
    "page": "home",
    "project_id": null
  }
}
```

**响应 `data`：** AI 回复内容，含意图识别结果、可能的页面导航指令等

---

## 10. 团队评级 Rating

> AI 评估专家/团队能力，生成 VibePower 评级（vc-T1 ~ vc-T10）

### 10.1 上传简历文件定级

> `🖥️ 前端` — **专家入驻-补充资料页 (ExpertSupplementPage)** 上传简历文件进行 AI 定级

```
POST /api/v2/rating/evaluate/file
Content-Type: multipart/form-data
```

**表单字段：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `resume_file` | File | ✅ | 简历文件（PDF / Word / Markdown / TXT） |
| `provider_id` | string | 否 | 留空自动生成 UUID |
| `display_name` | string | 否 | 显示名称 |
| `type` | string | 否 | `"individual"` 或 `"team"`，默认 individual |

**响应 `data`：**

```json
{
  "provider_id": "prov-uuid-001",
  "agent_message": "评估完成。综合技术深度和项目经验...",
  "vibe_power": 420,
  "vibe_level": "vc-T4",
  "level_icon": "🔷",
  "level_weight": 1.15,
  "report": {
    "score_tech_depth": 85,
    "score_project_exp": 72,
    "score_ai_proficiency": 68,
    "score_portfolio": 60,
    "score_background": 75
  },
  "review_tags": {
    "strengths": ["Flutter 精通", "全栈经验丰富"],
    "improvements": ["AI 工具使用经验较少"]
  }
}
```

---

### 10.2 纯文本定级

> `🖥️ 前端` — **专家入驻-补充资料页 (ExpertSupplementPage)** 手动输入简历文本定级

```
POST /api/v2/rating/evaluate/text
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `resume_text` | string | ✅ | 简历文本（最少 10 字） |
| `provider_id` | string | 否 | 留空自动生成 |
| `display_name` | string | 否 | 显示名称 |
| `type` | string | 否 | `"individual"` 或 `"team"` |

**响应 `data`：** 同 10.1

---

### 10.3-10.4 流式定级（SSE）

> `🖥️ 前端` — **专家入驻-补充资料页 (ExpertSupplementPage)** 推荐使用流式版本，实时展示评估过程

| 接口 | Content-Type | 说明 |
|------|-------------|------|
| `POST /api/v2/rating/evaluate/stream/file` | multipart/form-data | 文件上传 + SSE 流式，字段同 10.1 |
| `POST /api/v2/rating/evaluate/stream/text` | application/json | 纯文本 + SSE 流式，请求体同 10.2 |

SSE 事件序列：`init`（含 provider_id）→ `chunk`（流式内容）→ `done`（完整结果） / `error`

---

### 10.5 查看团队档案

> `🖥️ 前端` — **专家等级展示页 (ExpertLevelPage)** / **个人档案页 (ProfilePage)** 展示专家能力雷达图和等级

```
GET /api/v2/rating/{provider_id}/profile
```

**响应 `data`：**

```json
{
  "id": "prov-uuid-001",
  "user_id": "user-uuid-001",
  "type": "individual",
  "display_name": "张三",
  "vibe_power": 420,
  "vibe_level": "vc-T4",
  "level_icon": "🔷",
  "level_weight": 1.15,
  "skills": ["Flutter", "Go", "Python"],
  "experience_years": 5,
  "ai_tools": ["Cursor", "GitHub Copilot"],
  "resume_summary": "5年全栈开发经验...",
  "review_tags": { ... },
  "score_tech_depth": 85,
  "score_project_exp": 72,
  "score_ai_proficiency": 68,
  "score_portfolio": 60,
  "score_background": 75,
  "total_projects": 12,
  "completed_projects": 10,
  "avg_rating": 4.7,
  "on_time_rate": 92.5,
  "next_level": {
    "level": "vc-T5",
    "points_needed": 80
  }
}
```

---

### 10.6 查看积分历史

> `🖥️ 前端` — **个人档案页 (ProfilePage)** 展示 VibePower 积分变动记录

```
GET /api/v2/rating/{provider_id}/history?limit=50&offset=0
```

**Query 参数：**

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `limit` | int | 50 | 每页数量 |
| `offset` | int | 0 | 偏移量 |

**响应 `data`：**

```json
{
  "provider_id": "prov-uuid-001",
  "logs": [
    {
      "id": 1,
      "action": "project_completed",
      "points": 50,
      "reason": "按时完成项目交付",
      "project_id": "550e8400-...",
      "created_at": "2026-03-30T10:00:00"
    }
  ],
  "count": 15
}
```

---

### 10.7 积分调整（管理端）

> `🔑 管理端` — 管理后台调用，前端**不调用**。Go 后端在项目完成/评价等节点自动触发

```
POST /api/v2/rating/{provider_id}/adjust
```

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `action` | string | ✅ | `project_completed` / `five_star_review` / `overdue` / `bad_review` / `project_abandoned` |
| `points` | int | ✅ | 积分变动（正=加分，负=扣分） |
| `reason` | string | ✅ | 变动原因 |
| `project_id` | string | 否 | 关联项目 ID |

**响应 `data`：**

```json
{
  "provider_id": "prov-uuid-001",
  "old_power": 420,
  "new_power": 470,
  "points_delta": 50,
  "old_level": "vc-T4",
  "new_level": "vc-T5",
  "level_changed": true,
  "level_weight": 1.20
}
```

---

## 11. 前端页面 → 接口映射总表

> 一眼看清：哪个页面调哪些接口，哪些接口前端不碰

### 🖥️ 发布需求页 (PostPage)

> 需求方发起项目的核心页面，包含 AI 对话、需求采集、设计生成、任务拆解全流程

| 接口 | 用途 |
|------|------|
| `POST /api/v2/pipeline/start` | 初始化 AI 流水线 |
| `POST /api/v2/requirement/start/stream` | 首轮需求对话（推荐 SSE） |
| `POST /api/v2/requirement/{id}/message/stream` | 多轮需求对话（推荐 SSE） |
| `POST /api/v2/requirement/{id}/confirm` | 确认 PRD（轻量，立即返回） |
| `POST /api/v2/design/{id}/start/stream` | 生成架构设计（推荐 SSE） |
| `POST /api/v2/design/{id}/confirm` | 确认设计方案 |
| `POST /api/v2/task/{id}/start/stream` | 生成任务拆解（推荐 SSE） |
| `POST /api/v2/task/{id}/confirm` | 确认任务 → 流水线完成 |

### 🖥️ PRD 文档页 (PrdPage)

> 查看已生成的 AI 文档（需求/设计/任务），展示 EARS 规格和模块树

| 接口 | 用途 |
|------|------|
| `GET /api/v2/pipeline/{id}/status` | 查询流水线进度 |
| `GET /api/v2/pipeline/{id}/documents` | 获取所有文档列表 |
| `GET /api/v2/requirement/{id}/document` | 获取需求文档内容 |
| `GET /api/v2/design/{id}/document` | 获取设计文档内容 |
| `GET /api/v2/task/{id}/document` | 获取任务文档内容 |

### 🖥️ 项目详情页 (ProjectDetailPage)

> 项目全景页，展示项目状态、文档、投标信息、AI 推荐

| 接口 | 用途 |
|------|------|
| `GET /api/v2/pipeline/{id}/status` | 查询 AI 流水线状态 |
| `GET /api/v2/pipeline/{id}/documents` | 查询所有 AI 文档 |
| `POST /api/v2/match/recommend` | AI 智能撮合推荐（match_mode=2/3） |
| `GET /api/v2/pm/{id}/document` | 查看 PM 方案（撮合成功后） |

### 🖥️ 项目管理页 (ProjectManagePage)

> 撮合成功后的项目执行管理，里程碑追踪

| 接口 | 用途 |
|------|------|
| `GET /api/v2/pm/{id}/document` | 查看 PM 方案和里程碑 |
| `POST /api/v2/pm/{id}/regenerate` | 工期/价格调整后重新生成 PM |

### 🖥️ AI 对话页 (ChatDetailPage)

> 全局 AI 助手，悬浮入口可在任意页面唤起

| 接口 | 用途 |
|------|------|
| `POST /api/v2/chat/message` | 发送对话消息 |

### 🖥️ 专家入驻流程 (ExpertSupplementPage → ExpertLevelPage)

> 专家注册后上传简历 → AI 定级 → 展示等级结果

| 接口 | 用途 |
|------|------|
| `POST /api/v2/rating/evaluate/stream/file` | 上传简历文件定级（推荐 SSE） |
| `POST /api/v2/rating/evaluate/stream/text` | 纯文本简历定级（推荐 SSE） |
| `GET /api/v2/rating/{provider_id}/profile` | 展示定级结果和能力档案 |

### 🖥️ 个人档案页 (ProfilePage)

> 专家个人中心，展示等级、积分、能力雷达图

| 接口 | 用途 |
|------|------|
| `GET /api/v2/rating/{provider_id}/profile` | 查看专家档案和等级 |
| `GET /api/v2/rating/{provider_id}/history` | 查看积分变动记录 |

### 🔧 Go 后端内部调用（前端不碰）

> 这些接口由 Go 后端在业务节点自动调用，前端**无需关心**

| 接口 | 触发时机 |
|------|---------|
| `POST /api/v2/lifecycle/on-matched` | Go `BidService.Accept()` 后 → 自动生成 PM 方案 |
| `POST /api/v2/lifecycle/on-started` | 托管支付成功后（占位） |
| `POST /api/v2/lifecycle/on-milestone-delivered` | 造物者提交交付物后（占位） |
| `POST /api/v2/lifecycle/on-completed` | 全部里程碑验收后（占位） |

### 🔑 管理端调用（前端不碰）

| 接口 | 用途 |
|------|------|
| `POST /api/v2/rating/{provider_id}/adjust` | 积分调整（项目完成/好评/逾期等） |

---

## 12. 前端调用时序

### Phase 0: Go 后端创建项目

```
Go 后端 POST /projects → 返回 project_id (UUID)
前端拿到 project_id 后，开始调用 AI Agent 接口 ↓
```

### Phase 1: 需求采集（需求方 · PostPage）

```
① POST /api/v2/pipeline/start                  ← 初始化 AI 流水线（传入 Go 的 project_id）
② POST /api/v2/requirement/start/stream        ← 首轮需求对话
     ↓ （多轮对话，循环调用）
③ POST /api/v2/requirement/{id}/message/stream  ← 用户补充信息
     ↓ （completeness_score 达到阈值，analysis_complete=true）
④ POST /api/v2/requirement/{id}/confirm         ← 确认 PRD（轻量，立即返回）
     ↓ （发布项目 → 撮合匹配 → 确认合作）
⑤ POST /api/v2/requirement/{id}/decompose       ← 🔧 Go后端触发 EARS 拆解
```

### Phase 2: AI 文档生成（需求方 · PostPage）

```
⑤ POST /api/v2/design/{id}/start/stream        ← 生成架构设计
⑥ POST /api/v2/design/{id}/confirm             ← 确认设计
⑦ POST /api/v2/task/{id}/start/stream          ← 生成任务拆解
⑧ POST /api/v2/task/{id}/confirm               ← 确认任务 → 流水线完成 ✅
```

### Phase 3: 发布 + 撮合（ProjectDetailPage）

```
⑨ Go 后端发布项目 (status=2)
⑩ POST /api/v2/match/recommend                 ← 智能撮合（match_mode=2/3 时前端调用）
⑪ Go 后端 BidService.Accept()                  ← 需求方选定专家
⑫ Go 后端 → POST /api/v2/lifecycle/on-matched  ← 🔧 自动生成 PM（后端自动，前端不调用）
```

### Phase 4: 项目执行（ProjectManagePage）

```
⑬ GET /api/v2/pm/{id}/document                 ← 查看 PM 方案和里程碑
⑭ POST /api/v2/pm/{id}/regenerate              ← 工期/价格调整后重新生成（可选）
```

### 专家入驻流程（ExpertSupplementPage → ExpertLevelPage）

```
⑮ POST /api/v2/rating/evaluate/stream/file     ← 上传简历 AI 定级
⑯ GET /api/v2/rating/{id}/profile              ← 查看定级结果
```

### 随时可用

```
GET  /api/v2/pipeline/{id}/status              ← 🖥️ 项目详情/PRD页 查询进度
GET  /api/v2/pipeline/{id}/documents           ← 🖥️ 项目详情/PRD页 查询文档
GET  /api/v2/requirement/{id}/document         ← 🖥️ PRD页 获取需求文档
GET  /api/v2/design/{id}/document              ← 🖥️ PRD页 获取设计文档
GET  /api/v2/task/{id}/document                ← 🖥️ PRD页 获取任务文档
POST /api/v2/chat/message                      ← 🖥️ AI对话页 全局可用
GET  /api/v2/rating/{id}/profile               ← 🖥️ 个人档案页 查看等级
GET  /api/v2/rating/{id}/history               ← 🖥️ 个人档案页 积分记录
```

---

## 接口总览（33 个）

| # | 方法 | 路径 | 类型 | 调用方 | 前端页面 |
|---|------|------|------|--------|---------|
| 1 | POST | `/api/v2/pipeline/start` | JSON | 🖥️ 前端 | PostPage |
| 2 | GET | `/api/v2/pipeline/{project_id}/status` | JSON | 🖥️ 前端 | ProjectDetailPage / PrdPage |
| 3 | GET | `/api/v2/pipeline/{project_id}/documents` | JSON | 🖥️ 前端 | ProjectDetailPage / PrdPage |
| 4 | POST | `/api/v2/requirement/start` | JSON | 🖥️ 前端 | PostPage |
| 5 | POST | `/api/v2/requirement/{project_id}/message` | JSON | 🖥️ 前端 | PostPage |
| 6 | POST | `/api/v2/requirement/{project_id}/confirm` | JSON | 🖥️ 前端 | PostPage |
| 7 | GET | `/api/v2/requirement/{project_id}/document` | JSON | 🖥️ 前端 | PrdPage |
| 8 | POST | `/api/v2/requirement/start/stream` | SSE | 🖥️ 前端 | PostPage |
| 9 | POST | `/api/v2/requirement/{project_id}/message/stream` | SSE | 🖥️ 前端 | PostPage |
| 10 | POST | `/api/v2/requirement/{project_id}/decompose` | JSON | 🔧 Go后端 | — |
| 10b | POST | `/api/v2/requirement/{project_id}/decompose/stream` | SSE | 🔧 Go后端 | — |
| 11 | POST | `/api/v2/design/{project_id}/start` | JSON | 🖥️ 前端 | PostPage / ProjectDetailPage |
| 12 | POST | `/api/v2/design/{project_id}/confirm` | JSON | 🖥️ 前端 | PostPage / ProjectDetailPage |
| 13 | GET | `/api/v2/design/{project_id}/document` | JSON | 🖥️ 前端 | PrdPage |
| 14 | POST | `/api/v2/design/{project_id}/start/stream` | SSE | 🖥️ 前端 | PostPage / ProjectDetailPage |
| 15 | POST | `/api/v2/task/{project_id}/start` | JSON | 🖥️ 前端 | PostPage / ProjectDetailPage |
| 16 | POST | `/api/v2/task/{project_id}/confirm` | JSON | 🖥️ 前端 | PostPage / ProjectDetailPage |
| 17 | GET | `/api/v2/task/{project_id}/document` | JSON | 🖥️ 前端 | PrdPage |
| 18 | POST | `/api/v2/task/{project_id}/start/stream` | SSE | 🖥️ 前端 | PostPage / ProjectDetailPage |
| 19 | GET | `/api/v2/pm/{project_id}/document` | JSON | 🖥️ 前端 | ProjectManagePage |
| 20 | POST | `/api/v2/pm/{project_id}/regenerate` | JSON | 🖥️ 前端 | ProjectManagePage |
| 21 | POST | `/api/v2/lifecycle/on-matched` | JSON | 🔧 Go后端 | — |
| 22 | POST | `/api/v2/lifecycle/on-started` | JSON | 🔧 Go后端 | — |
| 23 | POST | `/api/v2/lifecycle/on-milestone-delivered` | JSON | 🔧 Go后端 | — |
| 24 | POST | `/api/v2/lifecycle/on-completed` | JSON | 🔧 Go后端 | — |
| 25 | POST | `/api/v2/match/recommend` | JSON | 🖥️ 前端 | ProjectDetailPage |
| 26 | POST | `/api/v2/chat/message` | JSON | 🖥️ 前端 | ChatDetailPage |
| 27 | POST | `/api/v2/rating/evaluate/file` | multipart | 🖥️ 前端 | ExpertSupplementPage |
| 28 | POST | `/api/v2/rating/evaluate/text` | JSON | 🖥️ 前端 | ExpertSupplementPage |
| 29 | POST | `/api/v2/rating/evaluate/stream/file` | SSE | 🖥️ 前端 | ExpertSupplementPage |
| 30 | POST | `/api/v2/rating/evaluate/stream/text` | SSE | 🖥️ 前端 | ExpertSupplementPage |
| 31 | GET | `/api/v2/rating/{provider_id}/profile` | JSON | 🖥️ 前端 | ExpertLevelPage / ProfilePage |
| 32 | GET | `/api/v2/rating/{provider_id}/history` | JSON | 🖥️ 前端 | ProfilePage |
| 33 | POST | `/api/v2/rating/{provider_id}/adjust` | JSON | 🔑 管理端 | — |
