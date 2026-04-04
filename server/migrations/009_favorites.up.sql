-- 用户收藏（项目 / 专家）
CREATE TABLE IF NOT EXISTS favorites (
    id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uuid         VARCHAR(36) NOT NULL COMMENT '收藏记录 UUID',
    user_id      BIGINT NOT NULL COMMENT '收藏人用户 ID',
    target_type  VARCHAR(20) NOT NULL COMMENT 'project / expert',
    target_id    VARCHAR(36) NOT NULL COMMENT '目标 UUID（项目或用户）',
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_favorites_uuid (uuid),
    UNIQUE KEY uk_favorites_user_target (user_id, target_type, target_id),
    KEY idx_favorites_user_id (user_id),
    KEY idx_favorites_target (target_type, target_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户收藏';
