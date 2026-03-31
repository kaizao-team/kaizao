# 前端对接完整流程指南

> 本文档面向 Flutter App 前端开发者，详细说明从用户点击"我有需求"到最终产出全套文档的**完整交互流程**。

---

## 一、全局流程概览

```
┌──────────────────────────────────────────────────────────────────────┐
│                           用户打开 APP                               │
│                               │                                      │
│                    点击 "我有需求" 按钮                                │
│                               │                                      │
│                     弹出对话式需求采集界面                              │
│                               │                                      │
│  ┌────────────────────────────▼─────────────────────────────────┐    │
│  │  阶段 1：需求分析（多轮对话）                                   │    │
│  │  ┌──────────────────────────────────────────────────────┐    │    │
│  │  │  轮 1: 用户输入一句话 → Agent 返回选择题/输入框        │    │    │
│  │  │  轮 2: 用户选择/填写  → Agent 返回下一批问题           │    │    │
│  │  │  轮 3: 用户继续补充   → Agent 生成 PRD 草稿           │    │    │
│  │  └──────────────────────────────────────────────────────┘    │    │
│  │  用户确认 PRD → Agent 自动拆解 EARS 任务                      │    │
│  │  ✅ 产出: requirement.md                                     │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                               │                                      │
│  ┌────────────────────────────▼─────────────────────────────────┐    │
│  │  阶段 2：架构设计（一键生成）                                   │    │
│  │  点击"生成架构设计" → 等待 → 展示设计文档 → 用户确认            │    │
│  │  ✅ 产出: design.md                                          │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                               │                                      │
│  ┌────────────────────────────▼─────────────────────────────────┐    │
│  │  阶段 3：任务分解（一键生成）                                   │    │
│  │  点击"生成任务分解" → 等待 → 展示任务文档 → 用户确认            │    │
│  │  ✅ 产出: task.md                                            │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                               │                                      │
│  ┌────────────────────────────▼─────────────────────────────────┐    │
│  │  阶段 4：项目管理（一键生成）                                   │    │
│  │  点击"生成项目管理方案" → 等待 → 展示管理文档 → 用户确认        │    │
│  │  ✅ 产出: project-plan.md                                    │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                               │                                      │
│                       🎉 全套文档就绪                                 │
│                      可以进入匹配造物者流程                            │
└──────────────────────────────────────────────────────────────────────┘
```

**核心要点：**
- 4 个阶段**严格顺序执行**，每阶段必须 confirm 后才能进入下一阶段
- 只有阶段 1（需求分析）是**多轮对话**，其余阶段都是**一键生成 + 确认**
- 前端需要持久化保存 `project_id`，它贯穿所有接口

---

## 二、阶段 1：需求分析（核心交互，最复杂）

### 2.1 UI 形态

建议使用**聊天式对话界面** + **卡片式问题控件**的混合模式：

```
┌──────────────────────────────────────┐
│  需求分析                    ← 返回  │
│─────────────────────────────────────│
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 🤖 Agent:                    │   │
│  │ 好的！在线教育是个很好的方向。 │   │
│  │ 为了帮您梳理清楚需求，我需要  │   │
│  │ 了解几个关键信息：            │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │   ← 结构化问题卡片
│  │ Q1 这个教育平台面向哪类用户？ │   │
│  │ ┌──────┐ ┌──────┐           │   │
│  │ │ K12  │ │ 大学生│           │   │   ← 单选卡片
│  │ └──────┘ └──────┘           │   │
│  │ ┌──────┐ ┌──────┐           │   │
│  │ │ 职场 │ │ 全年龄│           │   │
│  │ └──────┘ └──────┘           │   │
│  │ [ 其他: _____________ ]      │   │   ← allow_custom
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ Q2 需要哪些教学形式？(多选)   │   │
│  │ ☑ 直播课  ☑ 录播课           │   │   ← 多选
│  │ ☐ 1v1辅导 ☐ 题库             │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ Q3 优先开发哪个平台？         │   │
│  │ ○ 微信小程序  ○ App          │   │   ← 单选
│  │ ○ Web        ○ 多端都要      │   │
│  └──────────────────────────────┘   │
│                                      │
│  ═══════════════════════════════════ │   ← 维度进度
│  需求完整度: 12%  ████░░░░░░░░░░░░  │
│  产品定位 30% | 用户 10% | 功能 10% │
│                                      │
│  ┌──────────────────────────────┐   │
│  │         提交答案              │   │   ← 用户点击提交
│  └──────────────────────────────┘   │
│                                      │
└──────────────────────────────────────┘
```

### 2.2 完整接口调用时序

```
前端 APP                                        后端 AI Agent
  │                                                    │
  │  ① 用户输入 "我想做一个在线教育平台"                  │
  │ ──── POST /api/v2/requirement/start ──────────────→│
  │      { message: "我想做一个在线教育平台" }            │
  │                                                    │
  │ ←───── 返回 JSON ─────────────────────────────────│
  │  {                                                 │
  │    project_id: "abc123",  ← 【必须持久化保存！】      │
  │    agent_message: "好的！...",                       │
  │    sub_stage: "clarifying",                         │
  │    completeness_score: 12,                          │
  │    questions: [ {问题1}, {问题2}, {问题3} ],          │
  │    dimension_coverage: { product_scope: 30, ... }    │
  │  }                                                 │
  │                                                    │
  │  ② 前端渲染: agent_message 气泡 + questions 卡片      │
  │     + dimension_coverage 进度条                      │
  │                                                    │
  │  ③ 用户选择/填写完毕，点击"提交"                       │
  │     前端将答案拼成自然语言:                            │
  │     "面向K12学生，需要直播课和录播课，优先微信小程序"     │
  │                                                    │
  │ ──── POST /api/v2/requirement/{abc123}/message ──→│
  │      { message: "面向K12学生..." }                   │
  │                                                    │
  │ ←───── 返回 JSON ─────────────────────────────────│
  │  {                                                 │
  │    sub_stage: "clarifying",   ← 还在澄清阶段        │
  │    completeness_score: 48,    ← 分数涨了            │
  │    questions: [ {新问题4}, {新问题5}, {新问题6} ],     │
  │    dimension_coverage: { product_scope: 80, ... }    │
  │  }                                                 │
  │                                                    │
  │  ④ 前端继续渲染新问题，用户继续回答                     │
  │     （重复 ③ 步骤 N 次，通常 2-3 轮）                 │
  │                                                    │
  │ ──── POST /api/v2/requirement/{abc123}/message ──→│
  │                                                    │
  │ ←───── 返回 JSON ─────────────────────────────────│
  │  {                                                 │
  │    sub_stage: "prd_draft",    ← 🎯 变了！PRD 已生成  │
  │    completeness_score: 85,                          │
  │    questions: [],              ← 没有问题了           │
  │    dimension_coverage: { 各维度都 >= 60 }             │
  │  }                                                 │
  │                                                    │
  │  ⑤ 前端检测到 sub_stage == "prd_draft"               │
  │     显示 PRD 预览 + "确认 PRD" 按钮                   │
  │                                                    │
  │  ⑥ 用户点击 "确认 PRD"                               │
  │ ──── POST /api/v2/requirement/{abc123}/confirm ──→│
  │      { feedback: null }                             │
  │                                                    │
  │ ←───── 返回 JSON ─────────────────────────────────│
  │  {                                                 │
  │    sub_stage: "tasks_ready",  ← EARS 拆解完成        │
  │    completeness_score: 100,                         │
  │    document_path: "outputs/abc123/v1/requirement.md" │
  │  }                                                 │
  │                                                    │
  │  ✅ 需求阶段完成！前端显示"进入架构设计"按钮            │
  │                                                    │
```

### 2.3 前端状态机

```dart
enum RequirementState {
  initial,       // 初始状态，显示输入框让用户描述需求
  clarifying,    // 澄清中，展示 AI 问题卡片 + 进度条
  prdDraft,      // PRD 已生成，展示预览 + 确认按钮
  prdConfirmed,  // PRD 已确认，正在拆解 EARS（loading）
  tasksReady,    // 全部完成，显示"下一步"按钮
}
```

**状态转换逻辑：**

```dart
void handleResponse(Map<String, dynamic> data) {
  switch (data['sub_stage']) {
    case 'clarifying':
      state = RequirementState.clarifying;
      // 渲染 questions 卡片 + dimension_coverage 进度
      renderQuestions(data['questions']);
      renderCoverage(data['dimension_coverage']);
      break;

    case 'prd_draft':
      state = RequirementState.prdDraft;
      // 隐藏问题卡片，展示 PRD 预览 + 确认按钮
      // 可调 GET /requirement/{id}/document 获取完整 PRD
      showPrdPreview();
      showConfirmButton();
      break;

    case 'tasks_ready':
      state = RequirementState.tasksReady;
      // 展示完成状态 + "进入架构设计"按钮
      showNextStageButton('架构设计');
      break;
  }
}
```

### 2.4 questions 渲染逻辑

```dart
Widget buildQuestion(Map<String, dynamic> q) {
  switch (q['input_type']) {
    case 'single_choice':
      return SingleChoiceCard(
        question: q['question'],
        options: q['options'],         // [{label, value, description?}]
        allowCustom: q['allow_custom'] ?? true,
        required: q['required'] ?? true,
      );

    case 'multi_choice':
      return MultiChoiceCard(
        question: q['question'],
        options: q['options'],
        allowCustom: q['allow_custom'] ?? true,
        required: q['required'] ?? true,
      );

    case 'text':
      return TextInputCard(
        question: q['question'],
        placeholder: q['placeholder'] ?? '',
        required: q['required'] ?? true,
      );

    case 'number':
      return NumberInputCard(
        question: q['question'],
        placeholder: q['placeholder'] ?? '',
        required: q['required'] ?? true,
      );
  }
}
```

### 2.5 答案提交格式

用户选择/填写完毕后，前端将所有答案**拼成一段自然语言**，作为 message 发送：

```dart
String formatAnswers(List<Map> questions, Map<String, dynamic> answers) {
  final parts = <String>[];

  for (final q in questions) {
    final qId = q['id'];
    final answer = answers[qId];
    if (answer == null) continue;

    switch (q['input_type']) {
      case 'single_choice':
        // answer 是选中的 label
        parts.add('${q['question']}：$answer');
        break;

      case 'multi_choice':
        // answer 是选中的 label 列表
        final labels = (answer as List).join('、');
        parts.add('${q['question']}：$labels');
        break;

      case 'text':
      case 'number':
        parts.add('${q['question']}：$answer');
        break;
    }
  }

  return parts.join('\n');
}

// 示例输出:
// "这个教育平台面向哪类用户？：K12 学生（小初高）
//  需要哪些教学形式？：直播课、录播课、题库/在线作业
//  优先开发哪个平台？：微信小程序"
```

---

## 三、阶段 2/3/4：一键生成 + 确认

阶段 2（架构设计）、3（任务分解）、4（项目管理）的交互模式完全一致，比需求分析简单得多：

### 3.1 通用流程

```
前端 APP                                        后端 AI Agent
  │                                                    │
  │  ① 用户点击 "生成架构设计"                            │
  │ ──── POST /api/v2/design/{id}/start ─────────────→│
  │      { feedback: "" }    ← 可选的额外要求             │
  │                                                    │
  │     【此处等待 10-30 秒，展示 loading 动画】           │
  │                                                    │
  │ ←───── 返回 JSON ─────────────────────────────────│
  │  {                                                 │
  │    agent_message: "架构设计已完成...",                 │
  │    document_path: "outputs/abc123/v1/design.md"     │
  │  }                                                 │
  │                                                    │
  │  ② 前端展示文档预览 + "确认"按钮                      │
  │     可调 GET /design/{id}/document 获取完整内容       │
  │                                                    │
  │  ③ 用户点击 "确认"                                   │
  │ ──── POST /api/v2/design/{id}/confirm ───────────→│
  │                                                    │
  │ ←───── 返回 JSON ─────────────────────────────────│
  │  { message: "阶段 design 已确认，可以开始 task 阶段" } │
  │                                                    │
  │  ✅ 前端显示"下一步：任务分解"按钮                      │
```

### 3.2 三个阶段的接口映射

| 阶段 | 生成 | 确认 | 查看文档 |
|------|------|------|----------|
| 架构设计 | `POST /api/v2/design/{id}/start` | `POST /api/v2/design/{id}/confirm` | `GET /api/v2/design/{id}/document` |
| 任务分解 | `POST /api/v2/task/{id}/start` | `POST /api/v2/task/{id}/confirm` | `GET /api/v2/task/{id}/document` |
| 项目管理 | `POST /api/v2/pm/{id}/start` | `POST /api/v2/pm/{id}/confirm` | `GET /api/v2/pm/{id}/document` |

### 3.3 生成阶段的 UI

由于生成耗时较长（10-60 秒），有两种方案：

**方案 A：普通接口 + Loading（简单）**
```
用户点击 → 全屏 Loading "正在生成架构设计..." → 返回后展示
```

**方案 B：SSE 流式接口（体验更好，推荐）**
```
用户点击 → 实时展示 AI 思考过程:
  "正在理解需求文档..."
  "正在设计系统架构..."
  "正在规划 API 接口..."
  → 最终展示完整文档
```

SSE 接口：在原接口路径后加 `/stream`（如 `POST /api/v2/design/{id}/start/stream`）

---

## 四、全局状态查询

任何时候都可以查询项目当前进度：

```
GET /api/v2/pipeline/{project_id}/status
```

返回示例：
```json
{
  "project_id": "abc123",
  "title": "在线教育平台",
  "current_stage": "design",
  "stages": {
    "requirement": { "status": "confirmed",  "sub_stage": "tasks_ready" },
    "design":      { "status": "running",    "sub_stage": null },
    "task":        { "status": "pending",    "sub_stage": null },
    "pm":          { "status": "pending",    "sub_stage": null }
  }
}
```

**前端用途：**
- APP 再次打开时，根据 `current_stage` 和各 `status` 恢复到正确的 UI 界面
- 展示顶部进度条（4 步中的第几步）

---

## 五、完整的前端页面/路由规划建议

```
/demand                           ← 首页点击"我有需求"
  └── /demand/create              ← 需求采集对话界面（阶段 1）
        ├── 初始态: 输入框 + "描述你的需求"
        ├── 对话态: 消息列表 + 问题卡片 + 进度条
        ├── PRD 预览态: Markdown 渲染 + 确认按钮
        └── 完成态: 成功提示 + "下一步"按钮
  └── /demand/{id}/pipeline       ← 项目流水线总览
        ├── Step 1: 需求分析 ✅
        ├── Step 2: 架构设计 [当前] → 点击进入
        ├── Step 3: 任务分解 🔒
        └── Step 4: 项目管理 🔒
  └── /demand/{id}/design         ← 架构设计（阶段 2）
  └── /demand/{id}/task           ← 任务分解（阶段 3）
  └── /demand/{id}/pm             ← 项目管理（阶段 4）
  └── /demand/{id}/document/{stage} ← 文档详情查看
```

---

## 六、关键注意事项

### 6.1 project_id 持久化
```dart
// 第一次调用 /requirement/start 后拿到 project_id
// 必须保存到本地（SharedPreferences / SQLite）
// 后续所有接口都靠它
await prefs.setString('current_project_id', data['project_id']);
```

### 6.2 断点续传
用户可能中途退出 APP，再次进入时：
1. 读本地 `project_id`
2. 调 `GET /api/v2/pipeline/{id}/status` 获取当前进度
3. 根据 `current_stage` + `status` 跳转到对应页面
4. 如果在需求对话中途退出，历史消息已保存在服务端，调 `/message` 可以继续

### 6.3 sub_stage 判断逻辑（阶段 1 专用）

| sub_stage | 前端应该做什么 |
|-----------|--------------|
| `clarifying` | 展示 `questions` 问题卡片，等用户回答 |
| `prd_draft` | 展示 PRD 预览 + "确认"/"修改意见" 按钮 |
| `prd_confirmed` | Loading 态，EARS 正在拆解中 |
| `tasks_ready` | 需求阶段完成，展示"进入架构设计"按钮 |

### 6.4 错误处理

| code | 含义 | 前端处理 |
|------|------|----------|
| 0 | 成功 | 正常流程 |
| 40001 | 前置阶段未完成 | Toast: "请先完成上一阶段" |
| 40002 | 文档未生成 | Toast: "文档尚未生成，请先执行" |
| 40401 | 项目不存在 | 跳回首页 |
| 50001 | AI 服务异常 | Toast + 重试按钮 |

### 6.5 SSE vs JSON 选择

| 场景 | 推荐 | 原因 |
|------|------|------|
| 需求分析对话 | JSON | 响应快（2-5秒），多轮交互用 JSON 更简单 |
| 确认 PRD（EARS 拆解） | SSE | 耗时长（15-30秒），流式展示体验好 |
| 架构设计/任务分解/项目管理 | SSE | 耗时长（10-60秒），流式展示过程 |

---

## 七、一个完整 session 的接口调用序列

以用户"我想做一个在线教育平台"为例：

```
# ====== 阶段 1：需求分析 ======

# 1. 首轮对话（创建项目 + 第一轮提问）
POST /api/v2/requirement/start
  → project_id="abc123", sub_stage="clarifying", questions=[3个]

# 2. 第二轮对话
POST /api/v2/requirement/abc123/message
  body: { message: "面向K12学生，需要直播课和录播课，微信小程序" }
  → sub_stage="clarifying", completeness_score=48, questions=[3个新问题]

# 3. 第三轮对话
POST /api/v2/requirement/abc123/message
  body: { message: "想做付费课程，月度订阅，先做核心课程功能，预算5万" }
  → sub_stage="prd_draft", completeness_score=85, questions=[]

# 4. 用户确认 PRD → 自动 EARS 拆解
POST /api/v2/requirement/abc123/confirm
  body: { feedback: null }
  → sub_stage="tasks_ready", document_path="outputs/abc123/v1/requirement.md"

# ====== 阶段 2：架构设计 ======

# 5. 一键生成
POST /api/v2/design/abc123/start
  body: { feedback: "" }
  → document_path="outputs/abc123/v1/design.md"

# 6. 确认
POST /api/v2/design/abc123/confirm
  → message: "阶段 design 已确认，可以开始 task 阶段"

# ====== 阶段 3：任务分解 ======

# 7. 一键生成
POST /api/v2/task/abc123/start
  body: { feedback: "" }
  → document_path="outputs/abc123/v1/task.md"

# 8. 确认
POST /api/v2/task/abc123/confirm

# ====== 阶段 4：项目管理 ======

# 9. 一键生成
POST /api/v2/pm/abc123/start
  body: { feedback: "" }
  → document_path="outputs/abc123/v1/project-plan.md"

# 10. 确认
POST /api/v2/pm/abc123/confirm

# ====== 🎉 全部完成 ======

# 随时可查看任意文档
GET /api/v2/requirement/abc123/document
GET /api/v2/design/abc123/document
GET /api/v2/task/abc123/document
GET /api/v2/pm/abc123/document

# 随时可查看整体进度
GET /api/v2/pipeline/abc123/status
```

共计 **10 次核心接口调用**（最少情况），完成从一句话到四份文档的全流程。
