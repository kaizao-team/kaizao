-- ============================================================
-- 开造 VibeBuild — MySQL 数据库初始化脚本
-- 数据库版本: MySQL 8.0+
-- ============================================================

-- 1. 用户表
CREATE TABLE IF NOT EXISTS users (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                VARCHAR(36) NOT NULL UNIQUE,
    phone               VARCHAR(20) UNIQUE,
    phone_hash          VARCHAR(64),
    password_hash       VARCHAR(255),
    wechat_openid       VARCHAR(128) UNIQUE,
    wechat_unionid      VARCHAR(128),
    nickname            VARCHAR(50) NOT NULL,
    avatar_url          VARCHAR(512),
    role                SMALLINT NOT NULL DEFAULT 0,
    gender              SMALLINT DEFAULT 0,
    bio                 TEXT,
    city                VARCHAR(50),
    real_name           VARCHAR(50),
    id_card_no          VARCHAR(255),
    is_verified         TINYINT(1) NOT NULL DEFAULT 0,
    verified_at         DATETIME,
    hourly_rate         DECIMAL(10,2),
    available_status    SMALLINT DEFAULT 1,
    response_time_avg   INT DEFAULT 0,
    credit_score        INT NOT NULL DEFAULT 500,
    level               SMALLINT NOT NULL DEFAULT 1,
    total_orders        INT NOT NULL DEFAULT 0,
    completed_orders    INT NOT NULL DEFAULT 0,
    completion_rate     DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    avg_rating          DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    total_earnings      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status              SMALLINT NOT NULL DEFAULT 1,
    freeze_reason       VARCHAR(200),
    last_login_at       DATETIME,
    last_login_ip       VARCHAR(45),
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_phone_hash (phone_hash),
    INDEX idx_users_wechat_unionid (wechat_unionid),
    INDEX idx_users_role (role),
    INDEX idx_users_status (status),
    INDEX idx_users_level (level),
    INDEX idx_users_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 技能标签表
CREATE TABLE IF NOT EXISTS skills (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    category    VARCHAR(50) NOT NULL,
    icon_url    VARCHAR(512),
    sort_order  INT NOT NULL DEFAULT 0,
    is_hot      TINYINT(1) NOT NULL DEFAULT 0,
    usage_count INT NOT NULL DEFAULT 0,
    status      SMALLINT NOT NULL DEFAULT 1,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_skills_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 用户技能关联表
CREATE TABLE IF NOT EXISTS user_skills (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id             BIGINT NOT NULL,
    skill_id            BIGINT NOT NULL,
    proficiency         SMALLINT DEFAULT 3,
    years_of_experience SMALLINT DEFAULT 0,
    is_primary          TINYINT(1) NOT NULL DEFAULT 0,
    is_certified        TINYINT(1) NOT NULL DEFAULT 0,
    certified_at        DATETIME,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_user_skill (user_id, skill_id),
    INDEX idx_user_skills_user_id (user_id),
    INDEX idx_user_skills_skill_id (skill_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 角色标签表
CREATE TABLE IF NOT EXISTS role_tags (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    icon_url    VARCHAR(512),
    sort_order  INT NOT NULL DEFAULT 0,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 用户角色标签关联表
CREATE TABLE IF NOT EXISTS user_role_tags (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    role_tag_id BIGINT NOT NULL,
    is_primary  TINYINT(1) NOT NULL DEFAULT 0,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_user_role_tag (user_id, role_tag_id),
    INDEX idx_user_role_tags_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 作品集表
CREATE TABLE IF NOT EXISTS portfolios (
    id                    BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                  VARCHAR(36) NOT NULL UNIQUE,
    user_id               BIGINT NOT NULL,
    project_id            BIGINT,
    title                 VARCHAR(200) NOT NULL,
    description           TEXT,
    category              VARCHAR(50) NOT NULL,
    cover_url             VARCHAR(512),
    preview_url           VARCHAR(512),
    tech_stack            JSON,
    images                JSON,
    demo_video_url        VARCHAR(512),
    is_platform_certified TINYINT(1) NOT NULL DEFAULT 0,
    certified_at          DATETIME,
    view_count            INT NOT NULL DEFAULT 0,
    like_count            INT NOT NULL DEFAULT 0,
    sort_order            INT NOT NULL DEFAULT 0,
    status                SMALLINT NOT NULL DEFAULT 1,
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_portfolios_user_id (user_id),
    INDEX idx_portfolios_category (category),
    INDEX idx_portfolios_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. 短信验证码表
CREATE TABLE IF NOT EXISTS sms_codes (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone_hash VARCHAR(64) NOT NULL,
    code       VARCHAR(6) NOT NULL,
    purpose    SMALLINT NOT NULL,
    is_used    TINYINT(1) NOT NULL DEFAULT 0,
    expire_at  DATETIME NOT NULL,
    ip_address VARCHAR(45),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sms_codes_phone_hash (phone_hash),
    INDEX idx_sms_codes_expire_at (expire_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. 用户设备表
CREATE TABLE IF NOT EXISTS user_devices (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id        BIGINT NOT NULL,
    device_id      VARCHAR(128) NOT NULL,
    device_type    VARCHAR(20) NOT NULL,
    device_name    VARCHAR(100),
    push_token     VARCHAR(512),
    app_version    VARCHAR(20),
    os_version     VARCHAR(20),
    is_active      TINYINT(1) NOT NULL DEFAULT 1,
    last_active_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_user_device (user_id, device_id),
    INDEX idx_user_devices_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. 团队表
CREATE TABLE IF NOT EXISTS teams (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid            VARCHAR(36) NOT NULL UNIQUE,
    name            VARCHAR(100) NOT NULL,
    leader_id       BIGINT NOT NULL,
    avatar_url      VARCHAR(512),
    description     TEXT,
    team_type       SMALLINT NOT NULL DEFAULT 1,
    project_id      BIGINT,
    skills_coverage JSON,
    member_count    INT NOT NULL DEFAULT 1,
    avg_rating      DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    total_projects  INT NOT NULL DEFAULT 0,
    total_earnings  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status          SMALLINT NOT NULL DEFAULT 1,
    disbanded_at    DATETIME,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_teams_leader_id (leader_id),
    INDEX idx_teams_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. 团队成员表
CREATE TABLE IF NOT EXISTS team_members (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    team_id     BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    role_in_team VARCHAR(50) NOT NULL,
    split_ratio DECIMAL(5,2) NOT NULL,
    status      SMALLINT NOT NULL DEFAULT 1,
    joined_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    left_at     DATETIME,
    UNIQUE KEY idx_team_user (team_id, user_id),
    INDEX idx_team_members_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. 团队邀请表
CREATE TABLE IF NOT EXISTS team_invites (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid         VARCHAR(36) NOT NULL UNIQUE,
    team_id      BIGINT NOT NULL,
    inviter_id   BIGINT NOT NULL,
    invitee_id   BIGINT NOT NULL,
    role_in_team VARCHAR(50) NOT NULL,
    split_ratio  DECIMAL(5,2) NOT NULL,
    message      TEXT,
    status       SMALLINT NOT NULL DEFAULT 1,
    expire_at    DATETIME NOT NULL,
    responded_at DATETIME,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_team_invites_invitee_id (invitee_id),
    INDEX idx_team_invites_team_id (team_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. 组队大厅帖子表
CREATE TABLE IF NOT EXISTS team_posts (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid            VARCHAR(36) NOT NULL UNIQUE,
    author_id       BIGINT NOT NULL,
    project_id      BIGINT,
    title           VARCHAR(200) NOT NULL,
    description     TEXT NOT NULL,
    needed_roles    JSON,
    required_skills JSON,
    status          SMALLINT NOT NULL DEFAULT 1,
    view_count      INT NOT NULL DEFAULT 0,
    apply_count     INT NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_team_posts_author_id (author_id),
    INDEX idx_team_posts_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. 项目表
CREATE TABLE IF NOT EXISTS projects (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                 VARCHAR(36) NOT NULL UNIQUE,
    owner_id             BIGINT NOT NULL,
    provider_id          BIGINT,
    team_id              BIGINT,
    bid_id               BIGINT,
    title                VARCHAR(200) NOT NULL,
    description          TEXT NOT NULL,
    category             VARCHAR(50) NOT NULL,
    template_type        VARCHAR(50),
    ai_prd               JSON,
    ai_estimate          JSON,
    confirmed_prd        JSON,
    budget_min           DECIMAL(10,2),
    budget_max           DECIMAL(10,2),
    agreed_price         DECIMAL(10,2),
    deadline             DATE,
    agreed_days          INT,
    start_date           DATE,
    actual_end_date      DATE,
    complexity           VARCHAR(10),
    tech_requirements    JSON,
    attachments          JSON,
    match_mode           SMALLINT NOT NULL DEFAULT 1,
    progress             SMALLINT NOT NULL DEFAULT 0,
    current_milestone_id BIGINT,
    status               SMALLINT NOT NULL DEFAULT 1,
    close_reason         VARCHAR(200),
    view_count           INT NOT NULL DEFAULT 0,
    bid_count            INT NOT NULL DEFAULT 0,
    favorite_count       INT NOT NULL DEFAULT 0,
    published_at         DATETIME,
    matched_at           DATETIME,
    started_at           DATETIME,
    completed_at         DATETIME,
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_projects_owner_id (owner_id),
    INDEX idx_projects_provider_id (provider_id),
    INDEX idx_projects_category (category),
    INDEX idx_projects_status (status),
    INDEX idx_projects_match_mode (match_mode),
    INDEX idx_projects_published_at (published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. 里程碑表
CREATE TABLE IF NOT EXISTS milestones (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid             VARCHAR(36) NOT NULL UNIQUE,
    project_id       BIGINT NOT NULL,
    title            VARCHAR(200) NOT NULL,
    description      TEXT,
    sort_order       INT NOT NULL,
    payment_ratio    DECIMAL(5,2),
    payment_amount   DECIMAL(10,2),
    due_date         DATE,
    status           SMALLINT NOT NULL DEFAULT 1,
    delivery_note    TEXT,
    preview_url      VARCHAR(512),
    rejection_reason TEXT,
    delivered_at     DATETIME,
    accepted_at      DATETIME,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_milestones_project_id (project_id),
    INDEX idx_milestones_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. EARS任务卡片表
CREATE TABLE IF NOT EXISTS tasks (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                VARCHAR(36) NOT NULL UNIQUE,
    project_id          BIGINT NOT NULL,
    milestone_id        BIGINT,
    parent_task_id      BIGINT,
    task_code           VARCHAR(20) NOT NULL,
    title               VARCHAR(200) NOT NULL,
    ears_type           VARCHAR(20) NOT NULL,
    ears_trigger        TEXT,
    ears_behavior       TEXT NOT NULL,
    ears_full_text      TEXT NOT NULL,
    module              VARCHAR(100),
    role_tag            VARCHAR(50),
    assignee_id         BIGINT,
    priority            SMALLINT NOT NULL DEFAULT 2,
    estimated_hours     DECIMAL(5,1),
    actual_hours        DECIMAL(5,1),
    acceptance_criteria JSON,
    dependencies        JSON,
    blockers            JSON,
    status              SMALLINT NOT NULL DEFAULT 1,
    sort_order          INT NOT NULL DEFAULT 0,
    is_ai_generated     TINYINT(1) NOT NULL DEFAULT 0,
    ai_confidence       DECIMAL(3,2),
    extra               JSON,
    started_at          DATETIME,
    completed_at        DATETIME,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tasks_project_id (project_id),
    INDEX idx_tasks_milestone_id (milestone_id),
    INDEX idx_tasks_assignee_id (assignee_id),
    INDEX idx_tasks_status (status),
    INDEX idx_tasks_ears_type (ears_type),
    INDEX idx_tasks_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. 投标表
CREATE TABLE IF NOT EXISTS bids (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid           VARCHAR(36) NOT NULL UNIQUE,
    project_id     BIGINT NOT NULL,
    bidder_id      BIGINT,
    team_id        BIGINT,
    price          DECIMAL(10,2) NOT NULL,
    estimated_days INT NOT NULL,
    proposal       TEXT,
    tech_solution  TEXT,
    status         SMALLINT NOT NULL DEFAULT 1,
    reject_reason  VARCHAR(200),
    accepted_at    DATETIME,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_bids_project_id (project_id),
    INDEX idx_bids_bidder_id (bidder_id),
    INDEX idx_bids_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. 订单表
CREATE TABLE IF NOT EXISTS orders (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid             VARCHAR(36) NOT NULL UNIQUE,
    order_no         VARCHAR(32) NOT NULL UNIQUE,
    project_id       BIGINT NOT NULL,
    milestone_id     BIGINT,
    payer_id         BIGINT NOT NULL,
    payee_id         BIGINT,
    payee_team_id    BIGINT,
    amount           DECIMAL(10,2) NOT NULL,
    platform_fee_rate DECIMAL(5,4) NOT NULL DEFAULT 0.1200,
    platform_fee     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    actual_amount    DECIMAL(10,2),
    payment_method   VARCHAR(20),
    trade_no         VARCHAR(64),
    status           SMALLINT NOT NULL DEFAULT 1,
    refund_amount    DECIMAL(10,2),
    refund_reason    VARCHAR(200),
    refund_trade_no  VARCHAR(64),
    paid_at          DATETIME,
    escrow_at        DATETIME,
    released_at      DATETIME,
    withdrawn_at     DATETIME,
    refunded_at      DATETIME,
    expire_at        DATETIME,
    auto_release_at  DATETIME,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_orders_project_id (project_id),
    INDEX idx_orders_payer_id (payer_id),
    INDEX idx_orders_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. 分账记录表
CREATE TABLE IF NOT EXISTS split_records (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid        VARCHAR(36) NOT NULL UNIQUE,
    order_id    BIGINT NOT NULL,
    team_id     BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    split_ratio DECIMAL(5,2) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    status      SMALLINT NOT NULL DEFAULT 1,
    split_at    DATETIME,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_split_records_order_id (order_id),
    INDEX idx_split_records_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. 钱包表
CREATE TABLE IF NOT EXISTS wallets (
    id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id           BIGINT NOT NULL UNIQUE,
    available_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    frozen_balance    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_income      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_withdrawn   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 20. 钱包交易流水表
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid             VARCHAR(36) NOT NULL UNIQUE,
    wallet_id        BIGINT NOT NULL,
    user_id          BIGINT NOT NULL,
    order_id         BIGINT,
    transaction_type SMALLINT NOT NULL,
    amount           DECIMAL(10,2) NOT NULL,
    balance_before   DECIMAL(12,2) NOT NULL,
    balance_after    DECIMAL(12,2) NOT NULL,
    withdraw_method  VARCHAR(20),
    withdraw_account VARCHAR(200),
    withdraw_trade_no VARCHAR(64),
    remark           VARCHAR(200),
    status           SMALLINT NOT NULL DEFAULT 1,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_wallet_transactions_wallet_id (wallet_id),
    INDEX idx_wallet_transactions_user_id (user_id),
    INDEX idx_wallet_transactions_type (transaction_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 21. 会话表
CREATE TABLE IF NOT EXISTS conversations (
    id                    BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                  VARCHAR(36) NOT NULL UNIQUE,
    project_id            BIGINT,
    conversation_type     SMALLINT NOT NULL DEFAULT 1,
    user_a_id             BIGINT,
    user_b_id             BIGINT,
    last_message_content  VARCHAR(200),
    last_message_type     VARCHAR(20),
    last_message_at       DATETIME,
    last_message_user_id  BIGINT,
    status                SMALLINT NOT NULL DEFAULT 1,
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_conversations_user_a_id (user_a_id),
    INDEX idx_conversations_user_b_id (user_b_id),
    INDEX idx_conversations_project_id (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 22. 会话成员表
CREATE TABLE IF NOT EXISTS conversation_members (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    user_id         BIGINT NOT NULL,
    role            SMALLINT NOT NULL DEFAULT 1,
    unread_count    INT NOT NULL DEFAULT 0,
    last_read_msg_id BIGINT DEFAULT 0,
    is_muted        TINYINT(1) NOT NULL DEFAULT 0,
    is_pinned       TINYINT(1) NOT NULL DEFAULT 0,
    joined_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_conv_member (conversation_id, user_id),
    INDEX idx_conversation_members_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 23. 消息表
CREATE TABLE IF NOT EXISTS messages (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid            VARCHAR(36) NOT NULL UNIQUE,
    conversation_id BIGINT NOT NULL,
    sender_id       BIGINT NOT NULL,
    content_type    VARCHAR(20) NOT NULL DEFAULT 'text',
    content         TEXT,
    media_url       VARCHAR(512),
    media_name      VARCHAR(200),
    media_size      INT,
    media_duration  INT,
    thumbnail_url   VARCHAR(512),
    reply_to_msg_id BIGINT,
    related_task_id BIGINT,
    client_seq      BIGINT,
    status          SMALLINT NOT NULL DEFAULT 1,
    recalled_at     DATETIME,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_messages_conversation_id (conversation_id),
    INDEX idx_messages_sender_id (sender_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 24. 评价表
CREATE TABLE IF NOT EXISTS reviews (
    id                     BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                   VARCHAR(36) NOT NULL UNIQUE,
    project_id             BIGINT NOT NULL,
    reviewer_id            BIGINT NOT NULL,
    reviewee_id            BIGINT NOT NULL,
    reviewer_role          SMALLINT NOT NULL,
    overall_rating         DECIMAL(2,1) NOT NULL,
    quality_rating         DECIMAL(2,1),
    communication_rating   DECIMAL(2,1),
    timeliness_rating      DECIMAL(2,1),
    professionalism_rating DECIMAL(2,1),
    requirement_clarity    DECIMAL(2,1),
    payment_rating         DECIMAL(2,1),
    cooperation_rating     DECIMAL(2,1),
    content                TEXT,
    tags                   JSON,
    member_ratings         JSON,
    is_anonymous           TINYINT(1) NOT NULL DEFAULT 0,
    status                 SMALLINT NOT NULL DEFAULT 1,
    reply_content          TEXT,
    reply_at               DATETIME,
    created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_reviews_project_id (project_id),
    INDEX idx_reviews_reviewer_id (reviewer_id),
    INDEX idx_reviews_reviewee_id (reviewee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 25. 通知表
CREATE TABLE IF NOT EXISTS notifications (
    id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid              VARCHAR(36) NOT NULL UNIQUE,
    user_id           BIGINT NOT NULL,
    title             VARCHAR(200) NOT NULL,
    content           TEXT NOT NULL,
    notification_type SMALLINT NOT NULL,
    target_type       VARCHAR(50),
    target_id         BIGINT,
    is_read           TINYINT(1) NOT NULL DEFAULT 0,
    is_pushed         TINYINT(1) NOT NULL DEFAULT 0,
    push_result       VARCHAR(200),
    read_at           DATETIME,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notifications_user_id (user_id),
    INDEX idx_notifications_type (notification_type),
    INDEX idx_notifications_is_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 26. 举报表
CREATE TABLE IF NOT EXISTS reports (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid          VARCHAR(36) NOT NULL UNIQUE,
    reporter_id   BIGINT NOT NULL,
    target_type   VARCHAR(50) NOT NULL,
    target_id     BIGINT NOT NULL,
    reason_type   SMALLINT NOT NULL,
    reason_detail TEXT,
    evidence      JSON,
    status        SMALLINT NOT NULL DEFAULT 1,
    handler_id    BIGINT,
    handle_result TEXT,
    handled_at    DATETIME,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_reports_reporter_id (reporter_id),
    INDEX idx_reports_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 27. 仲裁表
CREATE TABLE IF NOT EXISTS arbitrations (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid          VARCHAR(36) NOT NULL UNIQUE,
    project_id    BIGINT NOT NULL,
    order_id      BIGINT,
    applicant_id  BIGINT NOT NULL,
    respondent_id BIGINT NOT NULL,
    reason        TEXT NOT NULL,
    evidence      JSON,
    status        SMALLINT NOT NULL DEFAULT 1,
    arbiter_id    BIGINT,
    verdict       TEXT,
    verdict_type  SMALLINT,
    refund_amount DECIMAL(10,2),
    arbitrated_at DATETIME,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_arbitrations_project_id (project_id),
    INDEX idx_arbitrations_applicant_id (applicant_id),
    INDEX idx_arbitrations_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 28. AI Agent 会话表
CREATE TABLE IF NOT EXISTS agent_sessions (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                 VARCHAR(36) NOT NULL UNIQUE,
    user_id              BIGINT NOT NULL,
    project_id           BIGINT,
    agent_type           VARCHAR(50) NOT NULL,
    status               SMALLINT NOT NULL DEFAULT 1,
    completeness_score   DECIMAL(5,2) DEFAULT 0.00,
    conversation_history JSON,
    generated_prd        JSON,
    generated_tasks      JSON,
    generated_estimate   JSON,
    model_used           VARCHAR(50),
    total_tokens         INT DEFAULT 0,
    total_cost           DECIMAL(8,4) DEFAULT 0.0000,
    completed_at         DATETIME,
    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_agent_sessions_user_id (user_id),
    INDEX idx_agent_sessions_project_id (project_id),
    INDEX idx_agent_sessions_type (agent_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 29. 匹配记录表
CREATE TABLE IF NOT EXISTS matches (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid            VARCHAR(36) NOT NULL UNIQUE,
    project_id      BIGINT NOT NULL,
    expert_id       BIGINT,
    team_id         BIGINT,
    match_score     DECIMAL(5,2),
    match_reason    JSON,
    is_ai_matched   TINYINT(1) NOT NULL DEFAULT 0,
    status          SMALLINT NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_matches_project_id (project_id),
    INDEX idx_matches_expert_id (expert_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
