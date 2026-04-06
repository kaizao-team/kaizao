## 12. 通知模块

**前缀**：`/api/v1/notifications`，均需 **Bearer**。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/notifications` | 列表；Query：`page`、`page_size`、`type`（可选，通知类型 int） |
| GET | `/notifications/unread-count` | `data.unread_count` |
| PUT | `/notifications/read-all` | 全部标记已读 |
| PUT | `/notifications/:uuid/read` | 单条已读 |

**列表项 `data[]` 常用字段**：`id`/`uuid`、`title`、`content`、`type` 与 `notification_type`（并存便于兼容）、`target_type`、`target_id`、`is_read`、`read_at`、`created_at`。分页见 `meta`。

---
