ALTER TABLE notifications
  ADD COLUMN source_role VARCHAR(20) NULL COMMENT '来源角色: demander/provider/system' AFTER user_id,
  ADD COLUMN target_uuid VARCHAR(36) NULL COMMENT '关联实体 UUID，供前端路由' AFTER target_id;
