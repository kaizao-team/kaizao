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
