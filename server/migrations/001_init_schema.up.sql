-- ============================================================
-- VibeBuild 开造 — 数据库初始化脚本
-- 执行顺序：按外键依赖关系排列
-- ============================================================

BEGIN;

-- 1. 用户表
CREATE TABLE IF NOT EXISTS users (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
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
    is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at         TIMESTAMPTZ,
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
    last_login_at       TIMESTAMPTZ,
    last_login_ip       VARCHAR(45),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_phone_hash ON users(phone_hash);
CREATE INDEX IF NOT EXISTS idx_users_wechat_openid ON users(wechat_openid);
CREATE INDEX IF NOT EXISTS idx_users_wechat_unionid ON users(wechat_unionid);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_level ON users(level);
CREATE INDEX IF NOT EXISTS idx_users_available_status ON users(available_status) WHERE role IN (2, 3);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- 2. 技能标签表
CREATE TABLE IF NOT EXISTS skills (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    category    VARCHAR(50) NOT NULL,
    icon_url    VARCHAR(512),
    sort_order  INT NOT NULL DEFAULT 0,
    is_hot      BOOLEAN NOT NULL DEFAULT FALSE,
    usage_count INT NOT NULL DEFAULT 0,
    status      SMALLINT NOT NULL DEFAULT 1,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_skills_category ON skills(category);
CREATE INDEX IF NOT EXISTS idx_skills_is_hot ON skills(is_hot) WHERE is_hot = TRUE;
CREATE INDEX IF NOT EXISTS idx_skills_name ON skills(name);

-- 3. 用户技能关联表
CREATE TABLE IF NOT EXISTS user_skills (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_id            BIGINT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    proficiency         SMALLINT DEFAULT 3,
    years_of_experience SMALLINT DEFAULT 0,
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    is_certified        BOOLEAN NOT NULL DEFAULT FALSE,
    certified_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, skill_id)
);

CREATE INDEX IF NOT EXISTS idx_user_skills_user ON user_skills(user_id);
CREATE INDEX IF NOT EXISTS idx_user_skills_skill ON user_skills(skill_id);
CREATE INDEX IF NOT EXISTS idx_user_skills_certified ON user_skills(is_certified) WHERE is_certified = TRUE;

-- 4. 角色标签表
CREATE TABLE IF NOT EXISTS role_tags (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    icon_url    VARCHAR(512),
    sort_order  INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. 用户角色标签关联表
CREATE TABLE IF NOT EXISTS user_role_tags (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_tag_id BIGINT NOT NULL REFERENCES role_tags(id) ON DELETE CASCADE,
    is_primary  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, role_tag_id)
);

CREATE INDEX IF NOT EXISTS idx_user_role_tags_user ON user_role_tags(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_tags_role ON user_role_tags(role_tag_id);

-- 6. 团队表
CREATE TABLE IF NOT EXISTS teams (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    name            VARCHAR(100) NOT NULL,
    leader_id       BIGINT NOT NULL REFERENCES users(id),
    avatar_url      VARCHAR(512),
    description     TEXT,
    team_type       SMALLINT NOT NULL DEFAULT 1,
    project_id      BIGINT,
    skills_coverage JSONB DEFAULT '[]',
    member_count    INT NOT NULL DEFAULT 1,
    avg_rating      DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    total_projects  INT NOT NULL DEFAULT 0,
    total_earnings  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status          SMALLINT NOT NULL DEFAULT 1,
    disbanded_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teams_leader ON teams(leader_id);
CREATE INDEX IF NOT EXISTS idx_teams_type ON teams(team_type);
CREATE INDEX IF NOT EXISTS idx_teams_status ON teams(status);
CREATE INDEX IF NOT EXISTS idx_teams_skills ON teams USING GIN(skills_coverage);

-- 7. 团队成员表
CREATE TABLE IF NOT EXISTS team_members (
    id           BIGSERIAL PRIMARY KEY,
    team_id      BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id      BIGINT NOT NULL REFERENCES users(id),
    role_in_team VARCHAR(50) NOT NULL,
    split_ratio  DECIMAL(5,2) NOT NULL,
    status       SMALLINT NOT NULL DEFAULT 1,
    joined_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    left_at      TIMESTAMPTZ,
    UNIQUE(team_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_team_members_team ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_active ON team_members(team_id) WHERE status = 1;

-- 8. 项目表
CREATE TABLE IF NOT EXISTS projects (
    id                   BIGSERIAL PRIMARY KEY,
    uuid                 UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    owner_id             BIGINT NOT NULL REFERENCES users(id),
    provider_id          BIGINT REFERENCES users(id),
    team_id              BIGINT REFERENCES teams(id),
    bid_id               BIGINT,
    title                VARCHAR(200) NOT NULL,
    description          TEXT NOT NULL,
    category             VARCHAR(50) NOT NULL,
    template_type        VARCHAR(50),
    ai_prd               JSONB,
    ai_estimate          JSONB,
    confirmed_prd        JSONB,
    budget_min           DECIMAL(10,2),
    budget_max           DECIMAL(10,2),
    agreed_price         DECIMAL(10,2),
    deadline             DATE,
    agreed_days          INT,
    start_date           DATE,
    actual_end_date      DATE,
    complexity           VARCHAR(10),
    tech_requirements    JSONB DEFAULT '[]',
    attachments          JSONB DEFAULT '[]',
    match_mode           SMALLINT NOT NULL DEFAULT 1,
    progress             SMALLINT NOT NULL DEFAULT 0,
    current_milestone_id BIGINT,
    status               SMALLINT NOT NULL DEFAULT 1,
    close_reason         VARCHAR(200),
    view_count           INT NOT NULL DEFAULT 0,
    bid_count            INT NOT NULL DEFAULT 0,
    favorite_count       INT NOT NULL DEFAULT 0,
    published_at         TIMESTAMPTZ,
    matched_at           TIMESTAMPTZ,
    started_at           TIMESTAMPTZ,
    completed_at         TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_owner ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_provider ON projects(provider_id);
CREATE INDEX IF NOT EXISTS idx_projects_team ON projects(team_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_category ON projects(category);
CREATE INDEX IF NOT EXISTS idx_projects_match_mode ON projects(match_mode);
CREATE INDEX IF NOT EXISTS idx_projects_complexity ON projects(complexity);
CREATE INDEX IF NOT EXISTS idx_projects_published_at ON projects(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_projects_tech ON projects USING GIN(tech_requirements);
CREATE INDEX IF NOT EXISTS idx_projects_budget ON projects(budget_min, budget_max);
CREATE INDEX IF NOT EXISTS idx_projects_list ON projects(status, published_at DESC) WHERE status IN (2, 3);

-- 更新 teams.project_id 外键
ALTER TABLE teams ADD CONSTRAINT fk_teams_project FOREIGN KEY (project_id) REFERENCES projects(id);

-- 9. 作品集表
CREATE TABLE IF NOT EXISTS portfolios (
    id                    BIGSERIAL PRIMARY KEY,
    uuid                  UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id               BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id            BIGINT REFERENCES projects(id),
    title                 VARCHAR(200) NOT NULL,
    description           TEXT,
    category              VARCHAR(50) NOT NULL,
    cover_url             VARCHAR(512),
    preview_url           VARCHAR(512),
    tech_stack            JSONB DEFAULT '[]',
    images                JSONB DEFAULT '[]',
    demo_video_url        VARCHAR(512),
    is_platform_certified BOOLEAN NOT NULL DEFAULT FALSE,
    certified_at          TIMESTAMPTZ,
    view_count            INT NOT NULL DEFAULT 0,
    like_count            INT NOT NULL DEFAULT 0,
    sort_order            INT NOT NULL DEFAULT 0,
    status                SMALLINT NOT NULL DEFAULT 1,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_portfolios_user ON portfolios(user_id);
CREATE INDEX IF NOT EXISTS idx_portfolios_category ON portfolios(category);
CREATE INDEX IF NOT EXISTS idx_portfolios_status ON portfolios(status);
CREATE INDEX IF NOT EXISTS idx_portfolios_tech ON portfolios USING GIN(tech_stack);

-- 10. 投标表
CREATE TABLE IF NOT EXISTS bids (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id      BIGINT NOT NULL REFERENCES projects(id),
    bidder_id       BIGINT REFERENCES users(id),
    team_id         BIGINT REFERENCES teams(id),
    price           DECIMAL(10,2) NOT NULL,
    estimated_days  INT NOT NULL,
    proposal        TEXT,
    tech_solution   TEXT,
    status          SMALLINT NOT NULL DEFAULT 1,
    reject_reason   VARCHAR(200),
    accepted_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_bids_bidder CHECK (bidder_id IS NOT NULL OR team_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_bids_project ON bids(project_id);
CREATE INDEX IF NOT EXISTS idx_bids_bidder ON bids(bidder_id);
CREATE INDEX IF NOT EXISTS idx_bids_team ON bids(team_id);
CREATE INDEX IF NOT EXISTS idx_bids_status ON bids(status);
CREATE INDEX IF NOT EXISTS idx_bids_created_at ON bids(created_at DESC);

-- 11. 里程碑表
CREATE TABLE IF NOT EXISTS milestones (
    id               BIGSERIAL PRIMARY KEY,
    uuid             UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id       BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
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
    delivered_at     TIMESTAMPTZ,
    accepted_at      TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_milestones_project ON milestones(project_id);
CREATE INDEX IF NOT EXISTS idx_milestones_status ON milestones(status);
CREATE INDEX IF NOT EXISTS idx_milestones_due_date ON milestones(due_date);

-- 12. EARS任务卡片表
CREATE TABLE IF NOT EXISTS tasks (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    milestone_id        BIGINT REFERENCES milestones(id),
    parent_task_id      BIGINT REFERENCES tasks(id),
    task_code           VARCHAR(20) NOT NULL,
    title               VARCHAR(200) NOT NULL,
    ears_type           VARCHAR(20) NOT NULL,
    ears_trigger        TEXT,
    ears_behavior       TEXT NOT NULL,
    ears_full_text      TEXT NOT NULL,
    module              VARCHAR(100),
    role_tag            VARCHAR(50),
    assignee_id         BIGINT REFERENCES users(id),
    priority            SMALLINT NOT NULL DEFAULT 2,
    estimated_hours     DECIMAL(5,1),
    actual_hours        DECIMAL(5,1),
    acceptance_criteria JSONB NOT NULL DEFAULT '[]',
    dependencies        JSONB NOT NULL DEFAULT '[]',
    blockers            JSONB NOT NULL DEFAULT '[]',
    status              SMALLINT NOT NULL DEFAULT 1,
    sort_order          INT NOT NULL DEFAULT 0,
    is_ai_generated     BOOLEAN NOT NULL DEFAULT FALSE,
    ai_confidence       DECIMAL(3,2),
    extra               JSONB DEFAULT '{}',
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_milestone ON tasks(milestone_id);
CREATE INDEX IF NOT EXISTS idx_tasks_parent ON tasks(parent_task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_ears_type ON tasks(ears_type);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_module ON tasks(module);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_board ON tasks(project_id, status, sort_order);

-- 13. 订单表
CREATE TABLE IF NOT EXISTS orders (
    id                BIGSERIAL PRIMARY KEY,
    uuid              UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    order_no          VARCHAR(32) NOT NULL UNIQUE,
    project_id        BIGINT NOT NULL REFERENCES projects(id),
    milestone_id      BIGINT REFERENCES milestones(id),
    payer_id          BIGINT NOT NULL REFERENCES users(id),
    payee_id          BIGINT REFERENCES users(id),
    payee_team_id     BIGINT REFERENCES teams(id),
    amount            DECIMAL(10,2) NOT NULL,
    platform_fee_rate DECIMAL(5,4) NOT NULL DEFAULT 0.1200,
    platform_fee      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    actual_amount     DECIMAL(10,2),
    payment_method    VARCHAR(20),
    trade_no          VARCHAR(64),
    status            SMALLINT NOT NULL DEFAULT 1,
    refund_amount     DECIMAL(10,2),
    refund_reason     VARCHAR(200),
    refund_trade_no   VARCHAR(64),
    paid_at           TIMESTAMPTZ,
    escrow_at         TIMESTAMPTZ,
    released_at       TIMESTAMPTZ,
    withdrawn_at      TIMESTAMPTZ,
    refunded_at       TIMESTAMPTZ,
    expire_at         TIMESTAMPTZ,
    auto_release_at   TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_order_no ON orders(order_no);
CREATE INDEX IF NOT EXISTS idx_orders_project ON orders(project_id);
CREATE INDEX IF NOT EXISTS idx_orders_payer ON orders(payer_id);
CREATE INDEX IF NOT EXISTS idx_orders_payee ON orders(payee_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- 14. 钱包表
CREATE TABLE IF NOT EXISTS wallets (
    id                BIGSERIAL PRIMARY KEY,
    user_id           BIGINT NOT NULL REFERENCES users(id) UNIQUE,
    available_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    frozen_balance    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_income      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_withdrawn   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. 钱包交易流水表
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id               BIGSERIAL PRIMARY KEY,
    uuid             UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    wallet_id        BIGINT NOT NULL REFERENCES wallets(id),
    user_id          BIGINT NOT NULL REFERENCES users(id),
    order_id         BIGINT REFERENCES orders(id),
    transaction_type SMALLINT NOT NULL,
    amount           DECIMAL(10,2) NOT NULL,
    balance_before   DECIMAL(12,2) NOT NULL,
    balance_after    DECIMAL(12,2) NOT NULL,
    withdraw_method  VARCHAR(20),
    withdraw_account VARCHAR(200),
    withdraw_trade_no VARCHAR(64),
    remark           VARCHAR(200),
    status           SMALLINT NOT NULL DEFAULT 1,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallet_txn_wallet ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_user ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_created ON wallet_transactions(created_at DESC);

-- 16. 分账记录表
CREATE TABLE IF NOT EXISTS split_records (
    id          BIGSERIAL PRIMARY KEY,
    uuid        UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    order_id    BIGINT NOT NULL REFERENCES orders(id),
    team_id     BIGINT NOT NULL REFERENCES teams(id),
    user_id     BIGINT NOT NULL REFERENCES users(id),
    split_ratio DECIMAL(5,2) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    status      SMALLINT NOT NULL DEFAULT 1,
    split_at    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_split_records_order ON split_records(order_id);
CREATE INDEX IF NOT EXISTS idx_split_records_user ON split_records(user_id);

-- 17. 会话表
CREATE TABLE IF NOT EXISTS conversations (
    id                   BIGSERIAL PRIMARY KEY,
    uuid                 UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id           BIGINT REFERENCES projects(id),
    conversation_type    SMALLINT NOT NULL DEFAULT 1,
    user_a_id            BIGINT REFERENCES users(id),
    user_b_id            BIGINT REFERENCES users(id),
    last_message_content VARCHAR(200),
    last_message_type    VARCHAR(20),
    last_message_at      TIMESTAMPTZ,
    last_message_user_id BIGINT,
    status               SMALLINT NOT NULL DEFAULT 1,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversations_user_a ON conversations(user_a_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user_b ON conversations(user_b_id);
CREATE INDEX IF NOT EXISTS idx_conversations_project ON conversations(project_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_msg ON conversations(last_message_at DESC);

-- 18. 会话成员表
CREATE TABLE IF NOT EXISTS conversation_members (
    id              BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES users(id),
    role            SMALLINT NOT NULL DEFAULT 1,
    unread_count    INT NOT NULL DEFAULT 0,
    last_read_msg_id BIGINT DEFAULT 0,
    is_muted        BOOLEAN NOT NULL DEFAULT FALSE,
    is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_conv_members_conv ON conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conv_members_user ON conversation_members(user_id);

-- 19. 消息表
CREATE TABLE IF NOT EXISTS messages (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    conversation_id BIGINT NOT NULL REFERENCES conversations(id),
    sender_id       BIGINT NOT NULL REFERENCES users(id),
    content_type    VARCHAR(20) NOT NULL DEFAULT 'text',
    content         TEXT,
    media_url       VARCHAR(512),
    media_name      VARCHAR(200),
    media_size      INT,
    media_duration  INT,
    thumbnail_url   VARCHAR(512),
    reply_to_msg_id BIGINT REFERENCES messages(id),
    related_task_id BIGINT REFERENCES tasks(id),
    client_seq      BIGINT,
    status          SMALLINT NOT NULL DEFAULT 1,
    recalled_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, id DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- 20. 评价表
CREATE TABLE IF NOT EXISTS reviews (
    id                     BIGSERIAL PRIMARY KEY,
    uuid                   UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id             BIGINT NOT NULL REFERENCES projects(id),
    reviewer_id            BIGINT NOT NULL REFERENCES users(id),
    reviewee_id            BIGINT NOT NULL REFERENCES users(id),
    reviewer_role          SMALLINT NOT NULL,
    overall_rating         DECIMAL(2,1) NOT NULL CHECK (overall_rating BETWEEN 1.0 AND 5.0),
    quality_rating         DECIMAL(2,1) CHECK (quality_rating BETWEEN 1.0 AND 5.0),
    communication_rating   DECIMAL(2,1) CHECK (communication_rating BETWEEN 1.0 AND 5.0),
    timeliness_rating      DECIMAL(2,1) CHECK (timeliness_rating BETWEEN 1.0 AND 5.0),
    professionalism_rating DECIMAL(2,1) CHECK (professionalism_rating BETWEEN 1.0 AND 5.0),
    requirement_clarity    DECIMAL(2,1) CHECK (requirement_clarity BETWEEN 1.0 AND 5.0),
    payment_rating         DECIMAL(2,1) CHECK (payment_rating BETWEEN 1.0 AND 5.0),
    cooperation_rating     DECIMAL(2,1) CHECK (cooperation_rating BETWEEN 1.0 AND 5.0),
    content                TEXT,
    tags                   JSONB DEFAULT '[]',
    member_ratings         JSONB DEFAULT '[]',
    is_anonymous           BOOLEAN NOT NULL DEFAULT FALSE,
    status                 SMALLINT NOT NULL DEFAULT 1,
    reply_content          TEXT,
    reply_at               TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reviews_project ON reviews(project_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON reviews(reviewee_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_unique ON reviews(project_id, reviewer_id, reviewee_id);

-- 21. 通知表
CREATE TABLE IF NOT EXISTS notifications (
    id                BIGSERIAL PRIMARY KEY,
    uuid              UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id           BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title             VARCHAR(200) NOT NULL,
    content           TEXT NOT NULL,
    notification_type SMALLINT NOT NULL,
    target_type       VARCHAR(50),
    target_id         BIGINT,
    is_read           BOOLEAN NOT NULL DEFAULT FALSE,
    is_pushed         BOOLEAN NOT NULL DEFAULT FALSE,
    push_result       VARCHAR(200),
    read_at           TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id) WHERE is_read = FALSE;

-- 22. 举报表
CREATE TABLE IF NOT EXISTS reports (
    id            BIGSERIAL PRIMARY KEY,
    uuid          UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    reporter_id   BIGINT NOT NULL REFERENCES users(id),
    target_type   VARCHAR(50) NOT NULL,
    target_id     BIGINT NOT NULL,
    reason_type   SMALLINT NOT NULL,
    reason_detail TEXT,
    evidence      JSONB DEFAULT '[]',
    status        SMALLINT NOT NULL DEFAULT 1,
    handler_id    BIGINT REFERENCES users(id),
    handle_result TEXT,
    handled_at    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_target ON reports(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);

-- 23. 仲裁表
CREATE TABLE IF NOT EXISTS arbitrations (
    id            BIGSERIAL PRIMARY KEY,
    uuid          UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id    BIGINT NOT NULL REFERENCES projects(id),
    order_id      BIGINT REFERENCES orders(id),
    applicant_id  BIGINT NOT NULL REFERENCES users(id),
    respondent_id BIGINT NOT NULL REFERENCES users(id),
    reason        TEXT NOT NULL,
    evidence      JSONB DEFAULT '[]',
    status        SMALLINT NOT NULL DEFAULT 1,
    arbiter_id    BIGINT REFERENCES users(id),
    verdict       TEXT,
    verdict_type  SMALLINT,
    refund_amount DECIMAL(10,2),
    arbitrated_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_arbitrations_project ON arbitrations(project_id);
CREATE INDEX IF NOT EXISTS idx_arbitrations_applicant ON arbitrations(applicant_id);
CREATE INDEX IF NOT EXISTS idx_arbitrations_status ON arbitrations(status);

-- 24. AI Agent 会话表
CREATE TABLE IF NOT EXISTS agent_sessions (
    id                   BIGSERIAL PRIMARY KEY,
    uuid                 UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id              BIGINT NOT NULL REFERENCES users(id),
    project_id           BIGINT REFERENCES projects(id),
    agent_type           VARCHAR(50) NOT NULL,
    status               SMALLINT NOT NULL DEFAULT 1,
    completeness_score   DECIMAL(5,2) DEFAULT 0.00,
    conversation_history JSONB NOT NULL DEFAULT '[]',
    generated_prd        JSONB,
    generated_tasks      JSONB,
    generated_estimate   JSONB,
    model_used           VARCHAR(50),
    total_tokens         INT DEFAULT 0,
    total_cost           DECIMAL(8,4) DEFAULT 0.0000,
    completed_at         TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_sessions_user ON agent_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_project ON agent_sessions(project_id);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_type ON agent_sessions(agent_type);

-- 25. 短信验证码表
CREATE TABLE IF NOT EXISTS sms_codes (
    id         BIGSERIAL PRIMARY KEY,
    phone_hash VARCHAR(64) NOT NULL,
    code       VARCHAR(6) NOT NULL,
    purpose    SMALLINT NOT NULL,
    is_used    BOOLEAN NOT NULL DEFAULT FALSE,
    expire_at  TIMESTAMPTZ NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sms_codes_phone ON sms_codes(phone_hash, purpose, created_at DESC);

-- 26. 用户设备表
CREATE TABLE IF NOT EXISTS user_devices (
    id             BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id      VARCHAR(128) NOT NULL,
    device_type    VARCHAR(20) NOT NULL,
    device_name    VARCHAR(100),
    push_token     VARCHAR(512),
    app_version    VARCHAR(20),
    os_version     VARCHAR(20),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_user_devices_user ON user_devices(user_id);

-- 27. 团队邀请表
CREATE TABLE IF NOT EXISTS team_invites (
    id           BIGSERIAL PRIMARY KEY,
    uuid         UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    team_id      BIGINT NOT NULL REFERENCES teams(id),
    inviter_id   BIGINT NOT NULL REFERENCES users(id),
    invitee_id   BIGINT NOT NULL REFERENCES users(id),
    role_in_team VARCHAR(50) NOT NULL,
    split_ratio  DECIMAL(5,2) NOT NULL,
    message      TEXT,
    status       SMALLINT NOT NULL DEFAULT 1,
    expire_at    TIMESTAMPTZ NOT NULL,
    responded_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_team_invites_team ON team_invites(team_id);
CREATE INDEX IF NOT EXISTS idx_team_invites_invitee ON team_invites(invitee_id, status);

-- 28. 组队大厅帖子表
CREATE TABLE IF NOT EXISTS team_posts (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    author_id       BIGINT NOT NULL REFERENCES users(id),
    project_id      BIGINT REFERENCES projects(id),
    title           VARCHAR(200) NOT NULL,
    description     TEXT NOT NULL,
    needed_roles    JSONB NOT NULL DEFAULT '[]',
    required_skills JSONB DEFAULT '[]',
    status          SMALLINT NOT NULL DEFAULT 1,
    view_count      INT NOT NULL DEFAULT 0,
    apply_count     INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_team_posts_author ON team_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_team_posts_status ON team_posts(status);
CREATE INDEX IF NOT EXISTS idx_team_posts_skills ON team_posts USING GIN(required_skills);
CREATE INDEX IF NOT EXISTS idx_team_posts_created ON team_posts(created_at DESC);

-- 29. 收藏表
CREATE TABLE IF NOT EXISTS favorites (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type SMALLINT NOT NULL,
    target_id   BIGINT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_target ON favorites(target_type, target_id);

-- 30. 匹配推荐记录表
CREATE TABLE IF NOT EXISTS matches (
    id             BIGSERIAL PRIMARY KEY,
    uuid           UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id     BIGINT NOT NULL REFERENCES projects(id),
    provider_id    BIGINT REFERENCES users(id),
    team_id        BIGINT REFERENCES teams(id),
    match_type     SMALLINT NOT NULL,
    match_score    DECIMAL(5,2),
    score_detail   JSONB DEFAULT '{}',
    rank_position  INT,
    status         SMALLINT NOT NULL DEFAULT 1,
    viewed_at      TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_matches_target CHECK (provider_id IS NOT NULL OR team_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_matches_project ON matches(project_id);
CREATE INDEX IF NOT EXISTS idx_matches_provider ON matches(provider_id);
CREATE INDEX IF NOT EXISTS idx_matches_score ON matches(match_score DESC);

COMMIT;
