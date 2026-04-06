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
