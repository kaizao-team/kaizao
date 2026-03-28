-- 团队静态文件元数据（实体文件在 MinIO / S3 兼容存储）
CREATE TABLE IF NOT EXISTS team_static_assets (
    id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid               VARCHAR(36) NOT NULL UNIQUE,
    team_id            BIGINT NOT NULL,
    uploaded_by_user_id BIGINT NOT NULL,
    bucket             VARCHAR(128) NOT NULL COMMENT '对象存储桶名',
    object_key         VARCHAR(512) NOT NULL COMMENT '对象键（MinIO 路径）',
    original_name      VARCHAR(255) NOT NULL DEFAULT '',
    content_type       VARCHAR(128) NOT NULL DEFAULT 'application/octet-stream',
    size_bytes         BIGINT NOT NULL DEFAULT 0,
    purpose            VARCHAR(64) NOT NULL DEFAULT 'content' COMMENT '业务用途：content/avatar/doc 等',
    storage            VARCHAR(32) NOT NULL DEFAULT 'minio',
    created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_team_static_assets_team_id (team_id),
    INDEX idx_team_static_assets_uploader (uploaded_by_user_id),
    INDEX idx_team_static_assets_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
