## 13. 管理后台 — 团队邀请码与入驻审核

> 路由组：`/api/v1/admin/*`，需 **JWT** 且数据库用户 **`role=9` 管理员**（中间件以库中角色为准）。

邀请码**绑定团队**（`team_id`），每条有效码默认 **仅用一次**；专家在 **2.4** 兑换后旧码作废，系统**自动为该团队生成新码**（新码明文写入新行，供列表与「当前码」接口查看）。

### 13.1 POST `/api/v1/admin/invite-codes` — 为团队创建/刷新邀请码

**Body**:
```json
{
  "team_uuid": "团队UUID",
  "note": "首批专家",
  "expires_at": "2027-12-31T23:59:59Z"
}
```
- 若该团队已有**未使用且未禁用**的码，会先全部作废再插入新码。
- **响应** `data`：`code_plain`、`uuid`、`team_id`、`max_uses`（固定为 1）、`expires_at`、`note`。

### 13.2 GET `/api/v1/admin/invite-codes` — 邀请码列表

- **Query**: `page`, `page_size`, `team_uuid`（可选，按团队筛选）
- **响应**: 列表项含 `team_id`、`code_hint`、`code_plain`（当前行若曾存明文则返回；已核销的历史行通常无明文）、`used_count`/`max_uses`、`expires_at`、`note`、`disabled_at`、`created_at`。

### 13.3 GET `/api/v1/admin/teams/:uuid/current-invite-code` — 查看团队当前有效邀请码

- **响应**：无有效码时 `data.has_active=false`；有则 `has_active=true` 且含 `code_plain`、`uuid`、`expires_at`、`note` 等。

### 13.4 PUT `/api/v1/admin/users/:uuid/onboarding` — 审核入驻（材料通道）

**Body**: `{ "status": "approved" | "rejected", "reason": "可选，拒绝时建议填写" }`

**响应**: `{ "code": 0, "message": "已更新" }`

### 相关错误码（节选）

| code | 说明 |
|------|------|
| 10013 | 邀请码无效或已过期 |
| 10014 | 邀请码使用次数已用尽 |
| 10016 | 注册申请未通过审核（历史文案，仍可用于业务提示） |
| 10017 | 请先完成注册后再登录 |
| 10018 | 已完成入驻审核 |
| 10019 | 仅专家角色可提交入驻或兑换团队邀请码 |
| 11011 | 请至少提供简历链接或有效作品集 |
| 11012 | 团队不存在 |
