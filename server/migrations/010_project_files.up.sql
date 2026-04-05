-- 项目共享文件元数据（二进制在 MinIO / S3 兼容存储）
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS project_files (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                 VARCHAR(36) NOT NULL UNIQUE,
    project_id           BIGINT NOT NULL COMMENT 'projects.id',
    uploaded_by_user_id  BIGINT NOT NULL,
    milestone_id         BIGINT NULL COMMENT 'milestones.id，可选，阶段性文件',
    bucket               VARCHAR(128) NOT NULL COMMENT '对象存储桶名',
    object_key           VARCHAR(512) NOT NULL COMMENT '对象键（MinIO 路径）',
    original_name        VARCHAR(255) NOT NULL DEFAULT '',
    content_type         VARCHAR(128) NOT NULL DEFAULT 'application/octet-stream',
    size_bytes           BIGINT NOT NULL DEFAULT 0,
    file_kind            VARCHAR(32) NOT NULL DEFAULT 'process' COMMENT 'reference=参考资料 process=过程文件 deliverable=交付物',
    storage              VARCHAR(32) NOT NULL DEFAULT 'minio',
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_project_files_project_id (project_id),
    INDEX idx_project_files_uploader (uploaded_by_user_id),
    INDEX idx_project_files_milestone_id (milestone_id),
    INDEX idx_project_files_kind (project_id, file_kind),
    INDEX idx_project_files_created (created_at),
    CONSTRAINT fk_project_files_project FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
    CONSTRAINT fk_project_files_milestone FOREIGN KEY (milestone_id) REFERENCES milestones (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
