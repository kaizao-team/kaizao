-- 邀请码与入驻审核
CREATE TABLE IF NOT EXISTS invite_codes (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                VARCHAR(36) NOT NULL UNIQUE,
    code_hash           VARCHAR(64) NOT NULL UNIQUE,
    code_hint           VARCHAR(20) NOT NULL DEFAULT '',
    note                VARCHAR(200) DEFAULT '',
    max_uses            INT NOT NULL DEFAULT 1,
    used_count          INT NOT NULL DEFAULT 0,
    expires_at          DATETIME NULL,
    allowed_roles       JSON NULL COMMENT '[] 或 null 表示不限制注册角色',
    disabled_at         DATETIME NULL,
    created_by_user_id  BIGINT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_invite_codes_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE users
    ADD COLUMN onboarding_status SMALLINT NOT NULL DEFAULT 2 COMMENT '1待审 2通过 3拒绝' AFTER status,
    ADD COLUMN invite_code_id BIGINT NULL AFTER onboarding_status,
    ADD COLUMN onboarding_reject_reason VARCHAR(500) NULL,
    ADD COLUMN onboarding_reviewed_at DATETIME NULL,
    ADD COLUMN onboarding_reviewer_id BIGINT NULL,
    ADD INDEX idx_users_onboarding_status (onboarding_status);
