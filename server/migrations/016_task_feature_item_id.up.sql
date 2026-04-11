ALTER TABLE tasks ADD COLUMN feature_item_id VARCHAR(20) DEFAULT '' COMMENT '关联 PRD 需求条目 item_id (如 F-1.1)' AFTER task_code;
