-- ============================================================
-- AI Agent 独有表 — 在 kaizao 库中创建
-- 执行: mysql -u root -p kaizao < 001_create_ai_tables.sql
-- ============================================================

-- 1. AI 流水线阶段状态表
CREATE TABLE IF NOT EXISTS ai_project_stages (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    project_id      VARCHAR(36) NOT NULL COMMENT 'Go 后端 projects.uuid',
    stage_name      VARCHAR(20) NOT NULL,
    status          VARCHAR(30) NOT NULL DEFAULT 'pending',
    sub_stage       VARCHAR(30) DEFAULT NULL,
    document_path   VARCHAR(512) DEFAULT NULL,
    error_message   TEXT DEFAULT NULL,
    started_at      DATETIME DEFAULT NULL,
    completed_at    DATETIME DEFAULT NULL,
    UNIQUE KEY uq_ai_project_stage (project_id, stage_name),
    INDEX idx_ai_project_id (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI 流水线阶段状态';

-- 2. AI 文档记录表
CREATE TABLE IF NOT EXISTS ai_documents (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    project_id      VARCHAR(36) NOT NULL,
    stage           VARCHAR(20) NOT NULL,
    filename        VARCHAR(128) NOT NULL,
    file_path       VARCHAR(512) NOT NULL,
    version         INT NOT NULL DEFAULT 1,
    size_bytes      INT NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_ai_doc_version (project_id, filename, version),
    INDEX idx_ai_doc_project (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI 生成文档记录';

-- 3. AI 对话消息表
CREATE TABLE IF NOT EXISTS ai_conversation_messages (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    session_id      VARCHAR(64) NOT NULL,
    project_id      VARCHAR(36) DEFAULT NULL,
    role            VARCHAR(20) NOT NULL,
    content         TEXT NOT NULL,
    message_index   INT NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ai_session (session_id, message_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI 对话消息';

-- 4. AI 供给方档案表
CREATE TABLE IF NOT EXISTS ai_provider_profiles (
    id                  VARCHAR(36) PRIMARY KEY,
    user_id             VARCHAR(36) NOT NULL,
    type                VARCHAR(10) NOT NULL DEFAULT 'individual',
    display_name        VARCHAR(128) DEFAULT NULL,
    vibe_power          INT NOT NULL DEFAULT 0,
    vibe_level          VARCHAR(20) NOT NULL DEFAULT 'vc-T1',
    level_weight        DECIMAL(3,2) NOT NULL DEFAULT 1.00,
    review_tags         JSON DEFAULT NULL,
    skills              JSON DEFAULT NULL,
    experience_years    INT NOT NULL DEFAULT 0,
    ai_tools            JSON DEFAULT NULL,
    resume_summary      TEXT DEFAULT NULL,
    score_tech_depth    INT NOT NULL DEFAULT 0,
    score_project_exp   INT NOT NULL DEFAULT 0,
    score_ai_proficiency INT NOT NULL DEFAULT 0,
    score_portfolio     INT NOT NULL DEFAULT 0,
    score_background    INT NOT NULL DEFAULT 0,
    total_projects      INT NOT NULL DEFAULT 0,
    completed_projects  INT NOT NULL DEFAULT 0,
    avg_rating          DECIMAL(3,2) NOT NULL DEFAULT 0,
    on_time_rate        DECIMAL(5,2) NOT NULL DEFAULT 0,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ai_user (user_id),
    INDEX idx_ai_level (vibe_level, vibe_power)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI 造物者档案';

-- 5. AI 积分变动记录表
CREATE TABLE IF NOT EXISTS ai_vibe_power_logs (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    provider_id     VARCHAR(36) NOT NULL,
    action          VARCHAR(50) NOT NULL,
    points          INT NOT NULL,
    reason          VARCHAR(255) DEFAULT NULL,
    project_id      VARCHAR(36) DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ai_provider (provider_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI 积分变动记录';
