# VibeBuild AI Agent 接口文档

> Base URL: `http://localhost:8000`
> Swagger UI: `http://localhost:8000/docs`
> 统一响应格式: `{ code: 0, message: "success", data: {...}, request_id: "..." }`

---

## 接口总览

所有接口统一使用 `/api/v2/` 前缀。

### 项目流水线（4 阶段顺序执行）

```
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: 需求分析（多轮对话）                                      │
│    POST /requirement/start       ← 创建项目 + 首轮对话            │
│    POST /requirement/{id}/message ← 多轮补充（重复 N 次）          │
│    POST /requirement/{id}/confirm ← 确认 PRD，生成 EARS           │
│                                                                   │
│  Step 2: 架构设计（一次性生成）                                     │
│    POST /design/{id}/start       ← 基于需求文档自动生成             │
│    POST /design/{id}/confirm     ← 确认设计文档                    │
│                                                                   │
│  Step 3: 任务分解（一次性生成）                                     │
│    POST /task/{id}/start         ← 基于需求+设计文档生成            │
│    POST /task/{id}/confirm       ← 确认任务文档                    │
│                                                                   │
│  Step 4: 项目管理（一次性生成）                                     │
│    POST /pm/{id}/start           ← 基于前三个文档生成               │
│    POST /pm/{id}/confirm         ← 确认管理方案                    │
│                                                                   │
│  随时可查:                                                         │
│    GET /pipeline/{id}/status     ← 项目全局进度                    │
│    GET /pipeline/{id}/documents  ← 所有已生成文档                   │
└─────────────────────────────────────────────────────────────────┘
```

> 注意：每个阶段必须按顺序执行，后一阶段依赖前一阶段 confirm 后才能启动。

### 独立功能模块

```
┌─────────────────────────────────────────────────────────────────┐
│  团队方评级（vc-T 序列 10 级）                                     │
│    POST /rating/evaluate/file    ← 上传简历文件 → AI 定级          │
│    POST /rating/evaluate/text    ← 纯文本简历 → AI 定级            │
│    POST /rating/evaluate/stream/* ← SSE 流式定级                  │
│    GET  /rating/{id}/profile     ← 查看团队方档案                  │
│    GET  /rating/{id}/history     ← 积分变动流水                    │
│    POST /rating/{id}/adjust      ← 平台内部积分调整                │
│                                                                   │
│  智能匹配                                                         │
│    POST /match/recommend         ← 为需求推荐团队方                │
│                                                                   │
│  对话助手                                                         │
│    POST /chat/message            ← 意图识别 + 多轮对话             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 一、流水线全局接口

### 1.1 创建项目

```
POST /api/v2/pipeline/start
```

**请求体:**

```json
{
  "title": "在线教育平台",
  "project_id": "my-project-001"   // 可选，不传则自动生成
}
```

**响应:**

```json
{
  "code": 0,
  "message": "项目已创建",
  "data": {
    "project_id": "my-project-001",
    "title": "在线教育平台",
    "current_stage": "requirement",
    "version": 1,
    "stages": {
      "requirement": { "status": "pending", "sub_stage": null },
      "design": { "status": "pending", "sub_stage": null },
      "task": { "status": "pending", "sub_stage": null },
      "pm": { "status": "pending", "sub_stage": null }
    }
  }
}
```

### 1.2 查看项目进度

```
GET /api/v2/pipeline/{project_id}/status
```

**响应:** 同 1.1 的 `data` 结构。

### 1.3 获取所有已生成文档

```
GET /api/v2/pipeline/{project_id}/documents
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "documents": [
      {
        "stage": "requirement",
        "filename": "requirement.md",
        "path": "outputs/my-project-001/v1/requirement.md",
        "size": 12345,
        "status": "confirmed"
      }
    ]
  }
}
```

---

## 二、需求分析接口（多轮对话）

### 2.1 启动需求分析（首轮对话）

```
POST /api/v2/requirement/start
```

**请求体:**

```json
{
  "message": "我想做一个在线教育平台，支持直播课和录播课",
  "title": "在线教育平台",
  "project_id": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| message | string | 是 | 用户的需求描述 |
| title | string | 否 | 项目标题，不传则从 message 截取 |
| project_id | string | 否 | 自定义项目 ID，不传则自动生成 |

**响应:**

```json
{
  "code": 0,
  "data": {
    "project_id": "a1b2c3d4e5f6",
    "session_id": "req-a1b2c3d4e5f6",
    "agent_message": "您好！您想做一个在线教育平台，我需要了解更多细节...",
    "sub_stage": "clarifying",
    "completeness_score": 25,
    "tool_result": {
      "tool_name": "ask_clarification",
      "completeness_score": 25,
      "questions": [...]
    }
  }
}
```

| 响应字段 | 说明 |
|----------|------|
| project_id | 项目 ID，后续所有接口都用它 |
| session_id | 会话 ID（内部用，前端无需关心） |
| agent_message | Agent 的回复文本，直接展示给用户 |
| sub_stage | 当前子阶段：`clarifying` / `prd_draft` / `prd_confirmed` / `tasks_ready` |
| completeness_score | 需求完整度 0-100，>=80 时 Agent 会自动生成 PRD |
| tool_result | Agent 调用的工具及结果摘要 |

### 2.2 多轮对话（继续补充需求）

```
POST /api/v2/requirement/{project_id}/message
```

**请求体:**

```json
{
  "message": "目标用户是K12学生，先做微信小程序，需要直播、录播、作业批改"
}
```

**响应:** 结构同 2.1，`sub_stage` 和 `completeness_score` 会随对话推进变化。

> **多轮对话流程说明:**
> 1. 前端拿到 `agent_message` 展示给用户
> 2. 用户输入回复，调用此接口
> 3. 重复直到 `sub_stage` 变为 `prd_draft`（Agent 认为信息充足，已生成 PRD 草稿）
> 4. 此时调用 confirm 接口确认

### 2.3 确认 PRD

```
POST /api/v2/requirement/{project_id}/confirm
```

**请求体:**

```json
{
  "feedback": null
}
```

| 字段 | 说明 |
|------|------|
| feedback | 可选，对 PRD 的修改意见。传 null 表示直接确认 |

**响应:**

```json
{
  "code": 0,
  "data": {
    "project_id": "a1b2c3d4e5f6",
    "agent_message": "PRD 已确认，EARS 任务已拆解完成。",
    "sub_stage": "tasks_ready",
    "completeness_score": 100,
    "document_path": "outputs/a1b2c3d4e5f6/v1/requirement.md"
  }
}
```

> 确认后 `sub_stage` 变为 `tasks_ready`，需求阶段完成，可以进入架构设计。

### 2.4 获取需求文档

```
GET /api/v2/requirement/{project_id}/document
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "filename": "requirement.md",
    "path": "outputs/a1b2c3d4e5f6/v1/requirement.md",
    "size": 8192
  }
}
```

---

## 三、架构设计接口

### 3.1 启动架构设计

```
POST /api/v2/design/{project_id}/start
```

**前置条件:** 需求阶段已 confirmed。

**请求体:**

```json
{
  "feedback": ""
}
```

| 字段 | 说明 |
|------|------|
| feedback | 可选，对设计的额外要求（如"偏好 React + Go 技术栈"） |

**响应:**

```json
{
  "code": 0,
  "data": {
    "project_id": "a1b2c3d4e5f6",
    "agent_message": "架构设计已完成，包含系统架构、API 设计...",
    "tool_name": "produce_design",
    "document_path": "outputs/a1b2c3d4e5f6/v1/design.md"
  }
}
```

### 3.2 确认架构设计

```
POST /api/v2/design/{project_id}/confirm
```

**请求体:** 无（空 body 或 `{}`）

**响应:**

```json
{
  "code": 0,
  "message": "阶段 design 已确认，可以开始 task 阶段",
  "data": { /* 项目状态摘要 */ }
}
```

### 3.3 获取设计文档

```
GET /api/v2/design/{project_id}/document
```

---

## 四、任务分解接口

### 4.1 启动任务分解

```
POST /api/v2/task/{project_id}/start
```

**前置条件:** 设计阶段已 confirmed。

**请求体:**

```json
{
  "feedback": ""
}
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "project_id": "a1b2c3d4e5f6",
    "agent_message": "任务分解已完成，共 25 个任务...",
    "tool_name": "produce_task_breakdown",
    "document_path": "outputs/a1b2c3d4e5f6/v1/task.md"
  }
}
```

### 4.2 确认任务文档

```
POST /api/v2/task/{project_id}/confirm
```

### 4.3 获取任务文档

```
GET /api/v2/task/{project_id}/document
```

---

## 五、项目管理接口

### 5.1 启动项目管理方案

```
POST /api/v2/pm/{project_id}/start
```

**前置条件:** 任务阶段已 confirmed。

**请求体:**

```json
{
  "feedback": ""
}
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "project_id": "a1b2c3d4e5f6",
    "agent_message": "项目管理方案已生成...",
    "tool_name": "produce_project_plan",
    "document_path": "outputs/a1b2c3d4e5f6/v1/project-plan.md"
  }
}
```

### 5.2 确认项目管理方案

```
POST /api/v2/pm/{project_id}/confirm
```

### 5.3 获取管理文档

```
GET /api/v2/pm/{project_id}/document
```

---

## 六、团队方评分定级接口

团队方（供给方）的 AI 能力评估与 VibeBuild 等级定级系统。通过 AI 解析简历进行初始化定级，后续根据平台行为动态积分升降级。

### VibeBuild vc-T 序列等级体系

| 等级 | 编码 | 图标 | VibePower 积分区间 | 推荐权重 | 定位 | 首次可达 |
|------|------|------|----------|----------|------|----------|
| T1 | vc-T1 | 🌟 | 0 ~ 99 | 1.00x | 新星 — 应届生/转行新手 | Yes |
| T2 | vc-T2 | 🚀 | 100 ~ 199 | 1.05x | 起步 — 1-2年初级开发者 | Yes |
| T3 | vc-T3 | 💪 | 200 ~ 349 | 1.10x | 胜任 — 3年+，可独立交付 | Yes |
| T4 | vc-T4 | 🔥 | 350 ~ 549 | 1.20x | 骨干 — 5年+，核心开发者 | Yes |
| T5 | vc-T5 | ⭐ | 550 ~ 749 | 1.35x | 资深 — 大厂+92学历+丰富经验 | Yes (首次最高) |
| T6 | vc-T6 | 💎 | 750 ~ 949 | 1.50x | 专家 — 平台验证的高质量交付 | No |
| T7 | vc-T7 | 🏆 | 950 ~ 1199 | 1.70x | 高级专家 — 持续卓越产出 | No |
| T8 | vc-T8 | 👑 | 1200 ~ 1499 | 1.90x | 领域大师 | No |
| T9 | vc-T9 | 🌍 | 1500 ~ 1899 | 2.20x | 行业领袖 | No |
| T10 | vc-T10 | 🏛️ | 1900+ | 2.50x | 传奇架构师 — 顶尖 0.1% | No |

> **注意:** 初始化定级最高可达 vc-T5（资深），vc-T6 及以上必须通过平台实际交付表现积累获得。
> **编码格式:** `vc-T{N}`，T = 技术序列，预留其他行业序列（如 vc-D 设计）。

### AI 定级锚点

| 条件 | 预期等级 | VibePower 区间 |
|------|----------|----------------|
| 应届/在校生，无工作经验 | vc-T1 | 0 ~ 99 |
| 1-2年经验，有基础项目 | vc-T2 | 100 ~ 199 |
| 3年+经验，能独立交付 | vc-T3 | 200 ~ 349 |
| 5年+经验，核心开发角色 或 3年+大厂 | vc-T4 | 350 ~ 549 |
| 大厂背景 + 92学历 + 5年+经验 + AI工具高级 | vc-T5 | 550 ~ 749 |

### 五维度评估体系

| 维度 | 权重 | 满分(加权后) | AI 评估方式 |
|------|------|------------|------------|
| 技术深度 (tech_depth) | 30% | 225 | 核心技术栈年限 × 熟练度 |
| 项目经验 (project_exp) | 25% | 187.5 | 项目数量、复杂度、角色 |
| AI 工具熟练度 (ai_proficiency) | 20% | 150 | Cursor/Copilot/Claude 等使用经验 |
| 作品质量 (portfolio) | 15% | 112.5 | GitHub star、开源贡献 |
| 行业背景 (background) | 10% | 75 | 教育背景、大厂经历 |

> VibePower = sum(score_i × weight_i × 7.5)，满分 750，首次定级上限 749。

### 评审标签 (review_tags)

评估接口会在响应中返回 `review_tags` 字段，记录定级关键凭证：

```json
{
  "education_tier": "985",
  "education_school": "浙江大学",
  "education_degree": "学士",
  "education_major": "计算机科学",
  "is_cs_related": true,
  "major_company": true,
  "major_company_names": ["字节跳动"],
  "work_years": 6,
  "max_role_level": "senior",
  "ai_tools_used": ["Claude Code", "Cursor"],
  "ai_proficiency_level": "expert",
  "project_max_complexity": "very_high",
  "independent_projects": 2,
  "has_open_source": true,
  "github_stars": 200
}
```

---

### 6.1 AI 初始化定级 — 文件上传版（推荐）

> **Swagger 测试方式:** 打开 `/docs`，在 `v2-团队方评分定级` 分组中找到此接口，可直接上传文件。

```
POST /api/v2/rating/evaluate/file
Content-Type: multipart/form-data
```

**支持的简历文件格式:**

| 格式 | 扩展名 | 说明 |
|------|--------|------|
| PDF | `.pdf` | 使用 pdfplumber 提取文本（不支持纯扫描件） |
| Word | `.docx` | 使用 python-docx 提取段落和表格 |
| Markdown | `.md` | 原文读取 |
| 纯文本 | `.txt` | 原文读取（支持 UTF-8 / GBK 编码） |

**表单字段 (multipart/form-data):**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `resume_file` | file | 二选一 | 简历文件（PDF / Word / Markdown / 纯文本） |
| `resume_text` | string | 二选一 | 简历纯文本内容（如果不上传文件） |
| `provider_id` | string | 否 | 供给方 ID，不传则自动生成 |
| `display_name` | string | 否 | 显示名称 |
| `type` | string | 否 | `individual`（个人）/ `team`（团队），默认 individual |

> 如果同时提供文件和文本，**文件优先**。至少提供其中一个。

**curl 示例（文件上传）:**

```bash
# 上传 PDF 简历
curl -X POST http://localhost:8000/api/v2/rating/evaluate/file \
  -F "resume_file=@/path/to/resume.pdf" \
  -F "display_name=张三" \
  -F "type=individual"

# 上传 Word 简历
curl -X POST http://localhost:8000/api/v2/rating/evaluate/file \
  -F "resume_file=@/path/to/resume.docx" \
  -F "display_name=张三"

# 上传 Markdown 简历
curl -X POST http://localhost:8000/api/v2/rating/evaluate/file \
  -F "resume_file=@/path/to/resume.md" \
  -F "display_name=张三"

# 纯文本方式（不上传文件）
curl -X POST http://localhost:8000/api/v2/rating/evaluate/file \
  -F "resume_text=张三，5年全栈开发经验，熟练使用 React/Node.js/Python，使用过 Cursor 和 Claude..." \
  -F "display_name=张三"
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "provider_id": "abc123",
    "agent_message": "评估完成！根据您的简历分析...",
    "vibe_power": 420,
    "vibe_level": "vc-T4",
    "level_icon": "🔥",
    "level_weight": 1.20,
    "report": {
      "vibe_power": 420,
      "vibe_level": "vc-T4",
      "level_icon": "🔥",
      "level_weight": 1.20,
      "scores": {
        "tech_depth": 70,
        "project_exp": 65,
        "ai_proficiency": 55,
        "portfolio": 40,
        "background": 60
      },
      "score_details": [
        {
          "dimension": "技术深度",
          "score": 70,
          "weight": "30%",
          "weighted_score": 157.5,
          "reasoning": "5年全栈经验，React/Node.js 熟练度较高..."
        }
      ],
      "strengths": ["全栈开发能力强", "项目经验丰富"],
      "improvements": [
        {
          "area": "AI 工具熟练度",
          "suggestion": "建议深入学习 Cursor/Claude 等 AI 辅助开发工具",
          "potential_points": 60
        }
      ],
      "next_level": {
        "level": "vc-T5",
        "points_needed": 130,
        "tips": "提升 AI 工具使用熟练度，参与更多平台项目"
      }
    },
    "review_tags": {
      "education_tier": "普通本科",
      "education_school": "XX大学",
      "education_degree": "学士",
      "education_major": "计算机科学",
      "is_cs_related": true,
      "major_company": false,
      "major_company_names": [],
      "work_years": 5,
      "max_role_level": "mid",
      "ai_tools_used": ["Cursor", "Claude", "Copilot"],
      "ai_proficiency_level": "intermediate",
      "project_max_complexity": "high",
      "independent_projects": 1,
      "has_open_source": false,
      "github_stars": 0
    }
  }
}
```

### 6.2 AI 初始化定级 — 纯文本 JSON 版（便于 Swagger 测试）

> 此接口接受 JSON 请求体，方便在 Swagger UI 中直接粘贴简历文本测试。

```
POST /api/v2/rating/evaluate/text
Content-Type: application/json
```

**请求体:**

```json
{
  "resume_text": "张三，5年全栈开发经验。\n\n技术栈：React, Node.js, Python, Go\n\n项目经验：\n1. 电商平台全栈开发（独立负责）\n2. AI客服系统（核心开发）\n\nAI工具：Cursor(熟练), Claude(日常使用), Copilot(基础使用)\n\n教育：XX大学 计算机科学学士",
  "provider_id": null,
  "display_name": "张三",
  "type": "individual"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `resume_text` | string | 是 | 简历文本内容（至少 10 个字符） |
| `provider_id` | string | 否 | 供给方 ID，不传自动生成 |
| `display_name` | string | 否 | 显示名称 |
| `type` | string | 否 | `individual` / `team`，默认 individual |

**响应:** 同 6.1

### 6.3 AI 初始化定级 — SSE 流式（实时展示 AI 思考过程）

> 与 6.1 相同的文件上传方式，但以 SSE 流式返回，前端可实时展示解析进度。

```
POST /api/v2/rating/evaluate/stream/file
Content-Type: multipart/form-data
```

**表单字段:** 同 6.1

**SSE 事件类型:**

| event | 说明 | data 格式 |
|-------|------|-----------|
| `init` | 初始化 | `{"provider_id": "abc123"}` |
| `thinking` | AI 正在思考 | `"正在理解您的需求..."` / `"AI 思考中...（第 2 轮）"` |
| `tool_call` | 正在执行工具 | `"正在解析简历信息..."` / `"正在进行五维度能力评估..."` / `"正在生成评估报告..."` |
| `tool_result` | 工具执行结果摘要 | `"简历解析完成，已提取结构化信息。"` |
| `text` | Agent 实时文本回复 | 实时追加的评估文本 |
| `rating_result` | 最终评估结果 | `{"provider_id": "...", "vibe_power": 420, "vibe_level": "vc-T4", "report": {...}}` |
| `done` | 全部完成 | `{"messages": "ok", "duration_ms": 8230}` |
| `error` | 出错 | 错误描述文本 |

**curl 流式测试:**

```bash
curl -N -X POST http://localhost:8000/api/v2/rating/evaluate/stream/file \
  -F "resume_file=@/path/to/resume.pdf" \
  -F "display_name=张三"
```

### 6.4 查看团队方档案

获取指定团队方的完整档案，包含等级、五维度评分、技能树、统计数据、距离下一级的差距。

```
GET /api/v2/rating/{provider_id}/profile
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "id": "abc123",
    "user_id": "abc123",
    "type": "individual",
    "display_name": "张三",
    "vibe_power": 420,
    "vibe_level": "vc-T4",
    "level_weight": 1.20,
    "level_icon": "🔥",
    "skills": [
      {"name": "React", "category": "framework", "proficiency": "advanced", "years": 4},
      {"name": "Cursor", "category": "ai_tool", "proficiency": "intermediate", "years": 1}
    ],
    "experience_years": 5,
    "ai_tools": [
      {"tool_name": "Cursor", "proficiency": "intermediate", "usage_scenario": "日常开发"},
      {"tool_name": "Claude", "proficiency": "advanced", "usage_scenario": "代码生成和审查"}
    ],
    "resume_summary": "5年全栈开发经验，熟练使用 React/Node.js...",
    "score_tech_depth": 70,
    "score_project_exp": 65,
    "score_ai_proficiency": 55,
    "score_portfolio": 40,
    "score_background": 60,
    "total_projects": 0,
    "completed_projects": 0,
    "avg_rating": 0,
    "on_time_rate": 0,
    "review_tags": {
      "education_tier": "普通本科",
      "major_company": false,
      "work_years": 5,
      "ai_proficiency_level": "intermediate"
    },
    "next_level": {
      "level": "vc-T5",
      "points_needed": 130,
      "min_points": 550
    }
  }
}
```

### 6.5 查看积分变动历史

获取团队方的 VibePower 积分变动流水记录，支持分页。

```
GET /api/v2/rating/{provider_id}/history?limit=50&offset=0
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `limit` | int | 每页条数，默认 50 |
| `offset` | int | 偏移量，默认 0 |

**响应:**

```json
{
  "code": 0,
  "data": {
    "provider_id": "abc123",
    "logs": [
      {
        "id": 1,
        "provider_id": "abc123",
        "action": "initial_evaluation",
        "points": 520,
        "reason": "AI 简历解析初始化定级",
        "project_id": null,
        "created_at": "2026-03-25T10:30:00"
      },
      {
        "id": 2,
        "provider_id": "abc123",
        "action": "project_completed",
        "points": 50,
        "reason": "完成项目交付（中等复杂度）",
        "project_id": "proj-001",
        "created_at": "2026-03-26T15:00:00"
      }
    ],
    "count": 2
  }
}
```

### 6.6 积分调整（平台内部调用）

根据团队方在平台上的行为进行积分加减，系统自动计算等级升降。

```
POST /api/v2/rating/{provider_id}/adjust
Content-Type: application/json
```

**请求体:**

```json
{
  "action": "project_completed",
  "points": 50,
  "reason": "完成项目交付（中等复杂度）",
  "project_id": "proj-001"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `action` | string | 是 | 行为类型（见下表） |
| `points` | int | 是 | 正数加分，负数扣分 |
| `reason` | string | 是 | 调整原因说明 |
| `project_id` | string | 否 | 关联的项目 ID |

**加分行为:**

| action | 建议积分 | 说明 |
|--------|----------|------|
| `project_completed` | +30 ~ +100 | 完成项目交付（按复杂度） |
| `five_star_review` | +20 | 获得 5 星好评 |
| `on_time_delivery` | +15 | 准时交付 |
| `early_delivery` | +25 | 提前交付 |
| `weekly_active` | +10 | 连续活跃 1 周 |
| `repeat_client` | +30 | 需求方复购 |

**扣分行为:**

| action | 建议积分 | 说明 |
|--------|----------|------|
| `overdue` | -20 | 项目逾期 |
| `bad_review` | -30 | 1-2 星差评 |
| `project_abandoned` | -50 | 中途退出项目 |
| `inactivity_decay` | -5 | 30 天不活跃（每周衰减） |
| `complaint_upheld` | -40 | 投诉经审核成立 |

**响应:**

```json
{
  "code": 0,
  "data": {
    "provider_id": "abc123",
    "old_power": 420,
    "new_power": 470,
    "points_delta": 50,
    "old_level": "vc-T4",
    "new_level": "vc-T4",
    "level_changed": false,
    "level_weight": 1.20
  }
}
```

> 当 `level_changed` 为 `true` 时，表示发生了等级变更，前端应展示升/降级提示。

---

## 七、智能匹配接口

### 7.1 智能匹配推荐

为需求方推荐合适的团队方，基于向量检索 + 多维评分 + LLM 推荐理由。

```
POST /api/v2/match/recommend
Content-Type: application/json
```

**请求体:**

```json
{
  "demand_id": "demand-001",
  "match_type": "recommend_providers",
  "user_id": "user-001",
  "filters": {
    "min_level": "vc-T3",
    "skills": ["React", "Node.js"]
  },
  "pagination": { "page": 1, "page_size": 10 }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `demand_id` | string | 是 | 需求 ID |
| `match_type` | string | 否 | 匹配类型，默认 `recommend_providers` |
| `user_id` | string | 否 | 用户 ID |
| `filters` | object | 否 | 筛选条件 |
| `pagination` | object | 否 | 分页参数 `{page, page_size}` |

**匹配维度:**

| 维度 | 权重 | 说明 |
|------|------|------|
| 技能匹配度 | 30% | 技术栈与需求的重合度 |
| 评分/等级 | 25% | VibePower 等级和历史评分 |
| 价格匹配 | 20% | 报价与需求预算的匹配度 |
| 交付能力 | 15% | 历史准时交付率 |
| 响应速度 | 10% | 接单响应时间 |

---

## 八、对话助手接口

### 8.1 对话助手

智能对话助手，支持意图识别、多轮对话、Agent 转交。

```
POST /api/v2/chat/message
Content-Type: application/json
```

**请求体:**

```json
{
  "session_id": "chat-session-001",
  "user_id": "user-001",
  "user_role": "demand",
  "message": { "text": "我想找一个会 React 的开发者" },
  "page_context": { "page": "home" }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `session_id` | string | 是 | 会话 ID |
| `user_id` | string | 是 | 用户 ID |
| `user_role` | string | 否 | 用户角色（demand / provider），默认 unknown |
| `message` | object | 是 | 消息内容 |
| `page_context` | object | 否 | 当前页面上下文（辅助意图识别） |

**功能:**
- 意图识别 — 自动分类用户消息
- 多轮对话 — 上下文滑动窗口管理
- Agent 转交 — 需求发布转需求分析 Agent，找人转匹配 Agent
- 页面导航 — 根据意图建议跳转到相应页面

---

## 九、健康检查

```
GET /health
```

**响应:**

```json
{
  "status": "healthy",
  "service": "vibebuild-ai-agent",
  "version": "1.0.0"
}
```

---

## 十、错误码说明

| code | 含义 |
|------|------|
| 0 | 成功 |
| 40001 | 参数校验失败 / 阶段状态不满足 |
| 40002 | 文档未生成，无法确认 |
| 40401 | 项目或供给方不存在 |
| 40402 | 文档尚未生成 |
| 50001 | 需求分析 / 架构设计服务异常 |
| 50002 | 智能匹配服务异常 |
| 50003 | 任务分解 / 对话助手服务异常 |
| 50004 | 项目管理服务异常 |

---

## 十一、多轮对话前端对接指南

### 需求分析对话流程（前端伪代码）

```javascript
// Step 1: 用户输入第一条需求
const startRes = await fetch('/api/v2/requirement/start', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: userInput,
    title: '项目标题'
  })
});
const { data } = await startRes.json();
const projectId = data.project_id;

// 展示 Agent 回复
showMessage('agent', data.agent_message);

// Step 2: 多轮对话循环
while (data.sub_stage === 'clarifying') {
  const userReply = await getUserInput();

  const msgRes = await fetch(`/api/v2/requirement/${projectId}/message`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: userReply })
  });
  const msgData = (await msgRes.json()).data;

  showMessage('agent', msgData.agent_message);
  showProgress(msgData.completeness_score);  // 展示完整度进度条

  // 当 sub_stage 变为 prd_draft，提示用户确认
  if (msgData.sub_stage === 'prd_draft') {
    showConfirmButton();
    break;
  }
}

// Step 3: 用户确认 PRD
const confirmRes = await fetch(`/api/v2/requirement/${projectId}/confirm`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ feedback: null })
});
// sub_stage → tasks_ready, 需求阶段完成

// Step 4: 继续后续阶段（设计/任务/PM）...
```

### 关键字段说明

| 字段 | 前端用途 |
|------|----------|
| `agent_message` | 直接展示在聊天气泡中 |
| `completeness_score` | 展示为进度条（0-100） |
| `sub_stage` | 控制 UI 状态（显示确认按钮、进入下一阶段等） |
| `project_id` | 贯穿所有接口的唯一标识，必须持久化存储 |

---

## 十二、SSE 流式接口（实时展示思考过程）

所有长耗时操作都提供 `/stream` 后缀的 SSE 版本，前端可实时展示 AI 思考进度。

### 流式接口列表

| 原始接口 | 流式版本 | 说明 |
|----------|----------|------|
| `POST /api/v2/requirement/start` | `POST /api/v2/requirement/start/stream` | 首轮对话 |
| `POST /api/v2/requirement/{id}/message` | `POST /api/v2/requirement/{id}/message/stream` | 多轮对话 |
| `POST /api/v2/requirement/{id}/confirm` | `POST /api/v2/requirement/{id}/confirm/stream` | 确认 PRD |
| `POST /api/v2/design/{id}/start` | `POST /api/v2/design/{id}/start/stream` | 架构设计 |
| `POST /api/v2/task/{id}/start` | `POST /api/v2/task/{id}/start/stream` | 任务分解 |
| `POST /api/v2/pm/{id}/start` | `POST /api/v2/pm/{id}/start/stream` | 项目管理 |
| `POST /api/v2/rating/evaluate/file` | `POST /api/v2/rating/evaluate/stream/file` | 团队方定级（文件） |
| `POST /api/v2/rating/evaluate/text` | `POST /api/v2/rating/evaluate/stream/text` | 团队方定级（文本） |

### SSE 事件类型

| event | 说明 | data 格式 |
|-------|------|-----------|
| `init` | 初始化（仅 start 接口） | `{"project_id": "xxx", "session_id": "xxx"}` |
| `thinking` | AI 正在思考 | `"正在理解您的需求..."` / `"AI 思考中...（第 2 轮）"` |
| `tool_call` | 正在执行工具 | `"正在生成 PRD 文档..."` / `"正在拆解 EARS 任务..."` |
| `tool_result` | 工具执行结果 | `"PRD 已生成，等待用户确认。"` |
| `text` | Agent 文本回复（实时） | `"您好！我来帮您分析需求..."` |
| `stage_info` | 阶段状态更新 | `{"sub_stage": "prd_draft", "completeness_score": 85}` |
| `done` | 全部完成 | `{"messages": "ok", "duration_ms": 5230}` |
| `error` | 出错 | `"错误描述"` |

### 前端 SSE 对接示例

```javascript
// 流式确认 PRD（最耗时的操作）
async function confirmPrdStream(projectId) {
  const response = await fetch(`/api/v2/requirement/${projectId}/confirm/stream`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ feedback: null })
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop(); // 保留不完整的行

    for (const line of lines) {
      if (line.startsWith('event:')) {
        const eventType = line.slice(6).trim();
        continue;
      }
      if (line.startsWith('data:')) {
        const data = line.slice(5).trim();

        switch (currentEvent) {
          case 'thinking':
            showThinkingStatus(data);    // 展示 "AI 思考中..."
            break;
          case 'tool_call':
            showToolProgress(data);       // 展示 "正在生成 PRD..."
            break;
          case 'text':
            appendAgentMessage(data);     // 实时追加文字
            break;
          case 'stage_info':
            updateStageUI(JSON.parse(data)); // 更新进度
            break;
          case 'done':
            hideLoading();
            break;
          case 'error':
            showError(data);
            break;
        }
      }
    }
  }
}
```

### 使用 EventSource（更简单）

```javascript
// 注意：EventSource 只支持 GET，对于 POST 请求需要用 fetch + ReadableStream
// 或使用 @microsoft/fetch-event-source 库

import { fetchEventSource } from '@microsoft/fetch-event-source';

await fetchEventSource(`/api/v2/requirement/${projectId}/confirm/stream`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ feedback: null }),
  onmessage(ev) {
    switch (ev.event) {
      case 'thinking':
        showStatus(ev.data);
        break;
      case 'tool_call':
        showProgress(ev.data);
        break;
      case 'text':
        appendText(ev.data);
        break;
      case 'done':
        onComplete();
        break;
    }
  },
});
```

---

## 十三、document 接口补充说明

所有 `GET /{project_id}/document` 接口现在返回文档完整内容：

```json
{
  "code": 0,
  "data": {
    "filename": "requirement.md",
    "path": "outputs/xxx/v1/requirement.md",
    "size": 8192,
    "content": "# 需求文档\n\n## 1. 项目概述\n..."
  }
}
```

`content` 字段包含完整的 Markdown 文本，前端可直接渲染。
