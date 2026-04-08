## 13. 管理后台 — 邀请码与团队/入驻审核

> 路由组：`/api/v1/admin/*`，需 **JWT** 且数据库用户 **`role=9` 管理员**（中间件以库中角色为准）。

邀请码为**全局码**（不绑定团队），由管理端批量创建，每码仅用一次。用户在 `POST /api/v1/teams` 创建团队时传入有效邀请码可跳过审核，邀请码同时被核销。

### 13.1 POST `/api/v1/admin/invite-codes` — 批量创建邀请码

**Body**:
```json
{
  "count": 10,
  "note": "首批专家",
  "expires_at": "2027-12-31T23:59:59Z"
}
```
- `count`：创建数量，默认 10，最大 200。
- `note`：备注（可选）。
- `expires_at`：过期时间 RFC3339（可选，不填则永不过期）。
- 创建新码**不会**禁用已有的旧码。
- **响应** `data`：
```json
{
  "codes": ["KZ-ABCD1234", "KZ-EFGH5678", "..."],
  "count": 10
}
```

### 13.2 GET `/api/v1/admin/invite-codes` — 邀请码列表

- **Query**: `page`, `page_size`
- **响应**: 列表项含 `uuid`、`team_id`（核销后回填的团队 ID）、`code_hint`、`code_plain`（未核销时返回明文；已核销为 null）、`used_count`/`max_uses`、`expires_at`、`note`、`disabled_at`、`created_at`。

### 13.3 PUT `/api/v1/admin/teams/:uuid/approval` — 审核团队

**Body**:
```json
{
  "status": "approved",
  "reason": "可选，拒绝时建议填写"
}
```
- `status`：`approved` 或 `rejected`。
- **响应**: `{ "code": 0, "message": "已更新" }`
- 仅对 `approval_status=1`（待审核）的团队有意义；已通过/已拒绝的团队也可重新审核。

### 13.4 PUT `/api/v1/admin/users/:uuid/onboarding` — 审核入驻（材料通道）

**Body**: `{ "status": "approved" | "rejected", "reason": "可选，拒绝时建议填写" }`

**响应**: `{ "code": 0, "message": "已更新" }`

### 相关错误码（节选）

| code | 说明 |
|------|------|
| 10013 | 邀请码无效或已过期 |
| 10014 | 邀请码使用次数已用尽 |
| 11012 | 团队不存在 |
| 11023 | 团队审核中，请等待管理员审核 |
| 11024 | 团队审核未通过 |
