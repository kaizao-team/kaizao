# VibeBuild v2 API 测试报告

**测试时间**: 2026-03-24 08:34:39

**LLM 模型**: 智谱 GLM-4-FlashX

**测试结果**: 15/16 通过，1 失败

---

## 接口汇总

| # | 测试名称 | 方法 | 接口路径 | 状态 | 耗时(ms) |
|---|---------|------|---------|------|---------|
| 1 | 健康检查 | GET | `/health` | ✅ | 25.93 |
| 2 | 创建项目 | POST | `/api/v2/pipeline/start` | ✅ | 11.38 |
| 3 | 获取项目状态 | GET | `/api/v2/pipeline/16fa7c5f-f69/status` | ✅ | 4.23 |
| 4 | 需求分析-启动 | POST | `/api/v2/requirement/start` | ✅ | 2996.72 |
| 5 | 需求分析-补充信息 | POST | `/api/v2/requirement/16fa7c5f-f69/message` | ✅ | 11083.69 |
| 6 | 需求分析-确认PRD | POST | `/api/v2/requirement/16fa7c5f-f69/confirm` | ✅ | 11877.05 |
| 7 | 需求分析-获取文档 | GET | `/api/v2/requirement/16fa7c5f-f69/document` | ✅ | 14.1 |
| 8 | 架构设计-启动 | POST | `/api/v2/design/16fa7c5f-f69/start` | ✅ | 556.51 |
| 9 | 架构设计-获取文档 | GET | `/api/v2/design/16fa7c5f-f69/document` | ❌ | 8.76 |
| 10 | 架构设计-确认 | POST | `/api/v2/design/16fa7c5f-f69/confirm` | ✅ | 9.56 |
| 11 | 任务分解-启动 | POST | `/api/v2/task/16fa7c5f-f69/start` | ✅ | 664.47 |
| 12 | 任务分解-确认 | POST | `/api/v2/task/16fa7c5f-f69/confirm` | ✅ | 4.07 |
| 13 | 项目管理-启动 | POST | `/api/v2/pm/16fa7c5f-f69/start` | ✅ | 10524.81 |
| 14 | 项目管理-确认 | POST | `/api/v2/pm/16fa7c5f-f69/confirm` | ✅ | 6.28 |
| 15 | 流水线-获取所有文档 | GET | `/api/v2/pipeline/16fa7c5f-f69/documents` | ✅ | 6.54 |
| 16 | 最终状态检查 | GET | `/api/v2/pipeline/16fa7c5f-f69/status` | ✅ | 3.27 |

---

## 详细测试结果

### 1. 健康检查 ✅ 成功

- **接口**: `GET /health`
- **耗时**: 25.93 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "status": "healthy",
  "service": "vibebuild-ai-agent",
  "version": "1.0.0"
}
```

---

### 2. 创建项目 ✅ 成功

- **接口**: `POST /api/v2/pipeline/start`
- **耗时**: 11.38 ms
- **HTTP 状态码**: 200

**请求体 (Request Body)**:

```json
{
  "title": "AI 驱动的任务管理系统"
}
```

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "项目已创建",
  "data": {
    "project_id": "16fa7c5f-f69",
    "title": "AI 驱动的任务管理系统",
    "current_stage": "requirement",
    "version": 1,
    "stages": {
      "requirement": {
        "status": "pending",
        "sub_stage": null
      },
      "design": {
        "status": "pending",
        "sub_stage": null
      },
      "task": {
        "status": "pending",
        "sub_stage": null
      },
      "pm": {
        "status": "pending",
        "sub_stage": null
      }
    }
  },
  "request_id": "8f99cab2-6cfb-46"
}
```

---

### 3. 获取项目状态 ✅ 成功

- **接口**: `GET /api/v2/pipeline/16fa7c5f-f69/status`
- **耗时**: 4.23 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "title": "AI 驱动的任务管理系统",
    "current_stage": "requirement",
    "version": 1,
    "stages": {
      "requirement": {
        "status": "pending",
        "sub_stage": null
      },
      "design": {
        "status": "pending",
        "sub_stage": null
      },
      "task": {
        "status": "pending",
        "sub_stage": null
      },
      "pm": {
        "status": "pending",
        "sub_stage": null
      }
    }
  },
  "request_id": "f0a96803-575e-46"
}
```

---

### 4. 需求分析-启动 ✅ 成功

- **接口**: `POST /api/v2/requirement/start`
- **耗时**: 2996.72 ms
- **HTTP 状态码**: 200

**请求体 (Request Body)**:

```json
{
  "message": "我想做一个类似 Trello 的任务管理工具。核心功能包括：看板视图、任务卡片拖拽、团队协作（邀请成员、权限管理）、标签分类、截止日期提醒、评论和附件。目标用户是 5-20 人的小型创业团队。技术栈用 React + Node.js + PostgreSQL。需要支持移动端响应式。MVP 先做看板和任务管理核心功能。",
  "title": "TaskFlow - 团队任务管理工具",
  "project_id": "16fa7c5f-f69"
}
```

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "session_id": "req-16fa7c5f-f69",
    "agent_message": "当前需求完整度评分：80\n\n为了更好地理解您的需求，我将向您提出一些问题：\n\n1. **范围**：您是否需要集成其他功能，例如甘特图或报告生成？ (category: scope)\n2. **用户**：团队成员是否需要使用移动端？ (category: user)\n3. **技术**：您对前端和后端的具体技术实现有什么要求吗？ (category: tech)\n4. **商业**：您希望通过这个工具实现哪些商业目标？ (category: business)\n5. **优先级**：除了看板和任务管理，您是否有其他功能的需求优先级？ (category: priority)\n\n请您根据实际情况回答这些问题，以便我更准确地为您生成需求文档。",
    "sub_stage": "clarifying",
    "completeness_score": 0,
    "tool_result": {}
  },
  "request_id": "ccfcd2fd-d78c-44"
}
```

---

### 5. 需求分析-补充信息 ✅ 成功

- **接口**: `POST /api/v2/requirement/16fa7c5f-f69/message`
- **耗时**: 11083.69 ms
- **HTTP 状态码**: 200

**请求体 (Request Body)**:

```json
{
  "message": "补充以下信息：\n1. 商业模式：免费版支持 5 人团队，Pro 版 ¥29/人/月支持更多功能\n2. 核心场景：产品团队管理开发任务、运营团队管理活动排期\n3. 非功能需求：页面加载 <2s，支持 1000 并发，数据每日备份\n4. 优先级：P0-看板+任务CRUD，P1-团队协作+权限，P2-通知+附件\n5. 部署：阿里云，Docker 容器化\n请根据这些信息生成完整的 PRD 文档。"
}
```

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "agent_message": "PRD 文档已生成，请查看以下内容：\n\n**任务管理工具 PRD**\n\n**摘要**：一个类似 Trello 的任务管理工具，适用于 5-20 人的小型创业团队。\n\n**目标用户**：\n- 产品团队：项目经理，开发人员\n- 运营团队：运营经理，活动策划\n\n**功能模块**：\n- 看板视图：看板创建、编辑、删除，列管理，卡片拖拽\n- 任务管理：任务创建、编辑、删除、状态更新、优先级更新、截止日期设置\n- 团队协作：成员邀请、权限管理、团队消息\n- 标签分类：标签创建、编辑、删除、标签关联\n- 截止日期提醒：提醒设置、提醒通知\n- 评论和附件：评论功能、附件上传\n\n**非功能需求**：\n- 性能：页面加载 <2s，支持 1000 并发\n- 数据备份：每日备份\n- 部署：阿里云，Docker 容器化\n\n**技术要求**：\n- 前端：React\n- 后端：Node.js\n- 数据库：PostgreSQL\n- 移动端响应式：支持移动端响应式\n- 商业模式：免费版支持 5 人团队，Pro 版 ¥29/人/月支持更多功能\n\n请您确认以上内容是否准确，如果有任何需要修改的地方，请告知我。",
    "sub_stage": "prd_draft",
    "completeness_score": 100,
    "tool_name": "generate_prd"
  },
  "request_id": "503b7758-6e31-46"
}
```

---

### 6. 需求分析-确认PRD ✅ 成功

- **接口**: `POST /api/v2/requirement/16fa7c5f-f69/confirm`
- **耗时**: 11877.05 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "agent_message": "EARS 拆解完成，并且已将完整的 requirement.md 文档保存至 outputs/16fa7c5f-f69/v1/requirement.md。",
    "sub_stage": "tasks_ready",
    "completeness_score": 100,
    "tool_name": "decompose_to_ears",
    "document_path": "outputs/16fa7c5f-f69/v1/requirement.md"
  },
  "request_id": "9ad04460-a930-4c"
}
```

---

### 7. 需求分析-获取文档 ✅ 成功

- **接口**: `GET /api/v2/requirement/16fa7c5f-f69/document`
- **耗时**: 14.1 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "filename": "requirement.md",
    "path": "outputs/16fa7c5f-f69/v1/requirement.md",
    "size": 55
  },
  "request_id": "bbd99914-7445-4a"
}
```

---

### 8. 架构设计-启动 ✅ 成功

- **接口**: `POST /api/v2/design/16fa7c5f-f69/start`
- **耗时**: 556.51 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "agent_message": "好的，为了生成架构设计方案，我需要先分析需求文档。请提供需求文档的内容。",
    "tool_name": "",
    "document_path": "outputs/16fa7c5f-f69/v1/design.md"
  },
  "request_id": "70d1bad7-8088-47"
}
```

---

### 9. 架构设计-获取文档 ❌ 失败

- **接口**: `GET /api/v2/design/16fa7c5f-f69/document`
- **耗时**: 8.76 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 40402,
  "message": "文档尚未生成",
  "data": null,
  "request_id": "0e95a807-2d45-4d"
}
```

---

### 10. 架构设计-确认 ✅ 成功

- **接口**: `POST /api/v2/design/16fa7c5f-f69/confirm`
- **耗时**: 9.56 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "阶段 design 已确认，可以开始 task 阶段",
  "data": {
    "project_id": "16fa7c5f-f69",
    "title": "TaskFlow - 团队任务管理工具",
    "current_stage": "task",
    "version": 1,
    "stages": {
      "requirement": {
        "status": "confirmed",
        "sub_stage": "tasks_ready"
      },
      "design": {
        "status": "confirmed",
        "sub_stage": null
      },
      "task": {
        "status": "pending",
        "sub_stage": null
      },
      "pm": {
        "status": "pending",
        "sub_stage": null
      }
    }
  },
  "request_id": "7e0a18fd-f786-46"
}
```

---

### 11. 任务分解-启动 ✅ 成功

- **接口**: `POST /api/v2/task/16fa7c5f-f69/start`
- **耗时**: 664.47 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "agent_message": "好的，为了生成任务分解方案，我需要先获取需求文档和架构设计文档的内容。请提供这两个文档的内容。",
    "tool_name": "",
    "document_path": "outputs/16fa7c5f-f69/v1/task.md"
  },
  "request_id": "189fcd4c-95a1-48"
}
```

---

### 12. 任务分解-确认 ✅ 成功

- **接口**: `POST /api/v2/task/16fa7c5f-f69/confirm`
- **耗时**: 4.07 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "阶段 task 已确认，可以开始 pm 阶段",
  "data": {
    "project_id": "16fa7c5f-f69",
    "title": "TaskFlow - 团队任务管理工具",
    "current_stage": "pm",
    "version": 1,
    "stages": {
      "requirement": {
        "status": "confirmed",
        "sub_stage": "tasks_ready"
      },
      "design": {
        "status": "confirmed",
        "sub_stage": null
      },
      "task": {
        "status": "confirmed",
        "sub_stage": null
      },
      "pm": {
        "status": "pending",
        "sub_stage": null
      }
    }
  },
  "request_id": "2a4f9bed-1707-49"
}
```

---

### 13. 项目管理-启动 ✅ 成功

- **接口**: `POST /api/v2/pm/16fa7c5f-f69/start`
- **耗时**: 10524.81 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "agent_message": "",
    "tool_name": "",
    "document_path": "outputs/16fa7c5f-f69/v1/project-plan.md"
  },
  "request_id": "a8c0e549-e164-45"
}
```

---

### 14. 项目管理-确认 ✅ 成功

- **接口**: `POST /api/v2/pm/16fa7c5f-f69/confirm`
- **耗时**: 6.28 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "阶段 pm 已确认，所有阶段已完成",
  "data": {
    "project_id": "16fa7c5f-f69",
    "title": "TaskFlow - 团队任务管理工具",
    "current_stage": "pm",
    "version": 1,
    "stages": {
      "requirement": {
        "status": "confirmed",
        "sub_stage": "tasks_ready"
      },
      "design": {
        "status": "confirmed",
        "sub_stage": null
      },
      "task": {
        "status": "confirmed",
        "sub_stage": null
      },
      "pm": {
        "status": "confirmed",
        "sub_stage": null
      }
    }
  },
  "request_id": "733853dc-8e77-42"
}
```

---

### 15. 流水线-获取所有文档 ✅ 成功

- **接口**: `GET /api/v2/pipeline/16fa7c5f-f69/documents`
- **耗时**: 6.54 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "documents": [
      {
        "stage": "requirement",
        "filename": "requirement.md",
        "path": "outputs/16fa7c5f-f69/v1/requirement.md",
        "size": 55,
        "status": "confirmed"
      }
    ]
  },
  "request_id": "afa3e711-d032-42"
}
```

---

### 16. 最终状态检查 ✅ 成功

- **接口**: `GET /api/v2/pipeline/16fa7c5f-f69/status`
- **耗时**: 3.27 ms
- **HTTP 状态码**: 200

**响应体 (Response Body)**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "project_id": "16fa7c5f-f69",
    "title": "TaskFlow - 团队任务管理工具",
    "current_stage": "pm",
    "version": 1,
    "stages": {
      "requirement": {
        "status": "confirmed",
        "sub_stage": "tasks_ready"
      },
      "design": {
        "status": "confirmed",
        "sub_stage": null
      },
      "task": {
        "status": "confirmed",
        "sub_stage": null
      },
      "pm": {
        "status": "confirmed",
        "sub_stage": null
      }
    }
  },
  "request_id": "08cfcca8-e560-41"
}
```

---

## 接口规格文档


### 1. 流水线管理

#### `POST /api/v2/pipeline/start` — 创建项目

**入参**:
```json
{
  "title": "string (必填，项目标题)",
  "project_id": "string (选填，不传则自动生成)"
}
```

**出参**:
```json
{
  "code": 0,
  "message": "项目已创建",
  "data": {
    "project_id": "string",
    "title": "string",
    "current_stage": "requirement",
    "version": 1,
    "stages": {
      "requirement": {"status": "pending", "sub_stage": null},
      "design": {"status": "pending", "sub_stage": null},
      "task": {"status": "pending", "sub_stage": null},
      "pm": {"status": "pending", "sub_stage": null}
    }
  }
}
```

#### `GET /api/v2/pipeline/{project_id}/status` — 获取项目进度

**入参**: 无（路径参数 project_id）

**出参**: 同创建项目的 data 结构

#### `GET /api/v2/pipeline/{project_id}/documents` — 获取所有文档

**入参**: 无

**出参**:
```json
{
  "code": 0,
  "data": {
    "documents": [
      {
        "stage": "requirement",
        "filename": "requirement.md",
        "path": "outputs/{project_id}/v1/requirement.md",
        "content": "Markdown 内容",
        "status": "confirmed"
      }
    ]
  }
}
```

---

### 2. 需求分析

#### `POST /api/v2/requirement/start` — 创建项目 + 首轮对话

**入参**:
```json
{
  "message": "string (必填，用户需求描述)",
  "title": "string (选填，项目标题)",
  "project_id": "string (选填)"
}
```

**出参**:
```json
{
  "code": 0,
  "data": {
    "project_id": "string",
    "session_id": "string",
    "agent_message": "string (Agent 回复文本)",
    "sub_stage": "clarifying | prd_draft | prd_confirmed | tasks_ready",
    "completeness_score": 0-100,
    "tool_result": {
      "tool_name": "ask_clarification | generate_prd",
      "agent_message": "string",
      "completeness_score": 35,
      "questions": [{"question": "...", "category": "scope|user|tech|business|priority"}]
    }
  }
}
```

#### `POST /api/v2/requirement/{project_id}/message` — 多轮对话

**入参**:
```json
{
  "message": "string (必填，用户回复)"
}
```

**出参**: 同 start 的 data 结构

#### `POST /api/v2/requirement/{project_id}/confirm` — 确认 PRD

**入参**:
```json
{
  "feedback": "string (选填，修改意见)"
}
```

**出参**: 同 start 的 data 结构（sub_stage 变为 tasks_ready）

#### `GET /api/v2/requirement/{project_id}/document` — 获取文档

**出参**:
```json
{
  "code": 0,
  "data": {
    "content": "Markdown 文档内容",
    "filename": "requirement.md"
  }
}
```

---

### 3. 架构设计 / 任务分解 / 项目管理（模式一致）

#### `POST /api/v2/{design|task|pm}/{project_id}/start` — 启动生成

**入参**:
```json
{
  "feedback": "string (选填，修改意见)"
}
```

**出参**:
```json
{
  "code": 0,
  "data": {
    "project_id": "string",
    "agent_message": "string (Agent 回复)",
    "tool_result": { ... }
  }
}
```

#### `POST /api/v2/{design|task|pm}/{project_id}/confirm` — 确认

**入参**: 无

**出参**:
```json
{
  "code": 0,
  "message": "阶段 design 已确认，可以开始 task 阶段",
  "data": { "project_id": "...", "stages": { ... } }
}
```

#### `GET /api/v2/{design|task|pm}/{project_id}/document` — 获取文档

**出参**:
```json
{
  "code": 0,
  "data": {
    "content": "Markdown 文档内容",
    "filename": "design.md | task.md | project-plan.md"
  }
}
```
