ALTER TABLE projects
  ADD COLUMN owner_aligned    TINYINT(1) NOT NULL DEFAULT 0 COMMENT '项目方已确认需求对齐' AFTER status,
  ADD COLUMN provider_aligned TINYINT(1) NOT NULL DEFAULT 0 COMMENT '团队方已确认需求对齐' AFTER owner_aligned;
