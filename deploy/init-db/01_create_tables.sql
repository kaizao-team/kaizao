-- =============================================================================
-- 开造 VCC - 数据库初始化脚本
-- PostgreSQL 16
-- 执行顺序：按表依赖关系排列，确保外键约束正确
-- =============================================================================

-- 启用扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. 用户表 (无外键依赖，最先创建)
-- =============================================================================
CREATE TABLE users (
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
    -- 实名认证
    real_name           VARCHAR(50),
    id_card_no          VARCHAR(255),
    is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at         TIMESTAMPTZ,
    -- 供给方扩展
    hourly_rate         DECIMAL(10,2),
    available_status    SMALLINT DEFAULT 1,
    response_time_avg   INT DEFAULT 0,
    -- 统计冗余
    credit_score        INT NOT NULL DEFAULT 500,
    level               SMALLINT NOT NULL DEFAULT 1,
    total_orders        INT NOT NULL DEFAULT 0,
    completed_orders    INT NOT NULL DEFAULT 0,
    completion_rate     DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    avg_rating          DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    total_earnings      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    -- 状态
    status              SMALLINT NOT NULL DEFAULT 1,
    freeze_reason       VARCHAR(200),
    last_login_at       TIMESTAMPTZ,
    last_login_ip       VARCHAR(45),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE users IS '用户表';
COMMENT ON COLUMN users.role IS '角色：0=未选择 1=需求方 2=供给方 3=双重身份 9=管理员';
COMMENT ON COLUMN users.status IS '状态：1=正常 2=冻结 3=注销';
COMMENT ON COLUMN users.credit_score IS '信用积分 0-1000，初始500';
COMMENT ON COLUMN users.level IS '等级：1=新手 2=成长 3=专业 4=精英 5=大师';

CREATE INDEX idx_users_phone_hash ON users(phone_hash);
CREATE INDEX idx_users_wechat_openid ON users(wechat_openid);
CREATE INDEX idx_users_wechat_unionid ON users(wechat_unionid);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_level ON users(level);
CREATE INDEX idx_users_available_status ON users(available_status) WHERE role IN (2, 3);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- =============================================================================
-- 2. 技能标签表 (无外键依赖)
-- =============================================================================
CREATE TABLE skills (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(50) NOT NULL UNIQUE,
    category            VARCHAR(50) NOT NULL,
    icon_url            VARCHAR(512),
    sort_order          INT NOT NULL DEFAULT 0,
    is_hot              BOOLEAN NOT NULL DEFAULT FALSE,
    usage_count         INT NOT NULL DEFAULT 0,
    status              SMALLINT NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE skills IS '技能标签字典表';

CREATE INDEX idx_skills_category ON skills(category);
CREATE INDEX idx_skills_is_hot ON skills(is_hot) WHERE is_hot = TRUE;
CREATE INDEX idx_skills_name ON skills(name);

-- =============================================================================
-- 3. 用户技能关联表 (依赖 users, skills)
-- =============================================================================
CREATE TABLE user_skills (
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

COMMENT ON TABLE user_skills IS '用户技能关联表';

CREATE INDEX idx_user_skills_user ON user_skills(user_id);
CREATE INDEX idx_user_skills_skill ON user_skills(skill_id);
CREATE INDEX idx_user_skills_certified ON user_skills(is_certified) WHERE is_certified = TRUE;

-- =============================================================================
-- 4. 角色标签表 (无外键依赖)
-- =============================================================================
CREATE TABLE role_tags (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(50) NOT NULL UNIQUE,
    description         VARCHAR(200),
    icon_url            VARCHAR(512),
    sort_order          INT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE role_tags IS '供给方角色标签表';

-- =============================================================================
-- 5. 用户角色标签关联表 (依赖 users, role_tags)
-- =============================================================================
CREATE TABLE user_role_tags (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_tag_id         BIGINT NOT NULL REFERENCES role_tags(id) ON DELETE CASCADE,
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, role_tag_id)
);

CREATE INDEX idx_user_role_tags_user ON user_role_tags(user_id);
CREATE INDEX idx_user_role_tags_role ON user_role_tags(role_tag_id);

-- =============================================================================
-- 6. 团队表 (依赖 users; projects外键延迟添加)
-- =============================================================================
CREATE TABLE teams (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    name                VARCHAR(100) NOT NULL,
    leader_id           BIGINT NOT NULL REFERENCES users(id),
    avatar_url          VARCHAR(512),
    description         TEXT,
    team_type           SMALLINT NOT NULL DEFAULT 1,
    project_id          BIGINT,  -- 延迟添加外键
    skills_coverage     JSONB DEFAULT '[]',
    member_count        INT NOT NULL DEFAULT 1,
    avg_rating          DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    total_projects      INT NOT NULL DEFAULT 0,
    total_earnings      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status              SMALLINT NOT NULL DEFAULT 1,
    disbanded_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE teams IS '团队表';

CREATE INDEX idx_teams_leader ON teams(leader_id);
CREATE INDEX idx_teams_type ON teams(team_type);
CREATE INDEX idx_teams_status ON teams(status);
CREATE INDEX idx_teams_skills ON teams USING GIN(skills_coverage);

-- =============================================================================
-- 7. 团队成员表 (依赖 teams, users)
-- =============================================================================
CREATE TABLE team_members (
    id                  BIGSERIAL PRIMARY KEY,
    team_id             BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES users(id),
    role_in_team        VARCHAR(50) NOT NULL,
    split_ratio         DECIMAL(5,2) NOT NULL,
    status              SMALLINT NOT NULL DEFAULT 1,
    joined_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    left_at             TIMESTAMPTZ,
    UNIQUE(team_id, user_id)
);

COMMENT ON TABLE team_members IS '团队成员表';

CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_team_members_active ON team_members(team_id) WHERE status = 1;

-- =============================================================================
-- 8. 团队邀请表 (依赖 teams, users)
-- =============================================================================
CREATE TABLE team_invites (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    team_id             BIGINT NOT NULL REFERENCES teams(id),
    inviter_id          BIGINT NOT NULL REFERENCES users(id),
    invitee_id          BIGINT NOT NULL REFERENCES users(id),
    role_in_team        VARCHAR(50) NOT NULL,
    split_ratio         DECIMAL(5,2) NOT NULL,
    message             TEXT,
    status              SMALLINT NOT NULL DEFAULT 1,
    expire_at           TIMESTAMPTZ NOT NULL,
    responded_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE team_invites IS '团队邀请表';

CREATE INDEX idx_team_invites_team ON team_invites(team_id);
CREATE INDEX idx_team_invites_invitee ON team_invites(invitee_id, status);
CREATE INDEX idx_team_invites_expire ON team_invites(expire_at) WHERE status = 1;

-- =============================================================================
-- 9. 项目表 (依赖 users, teams)
-- =============================================================================
CREATE TABLE projects (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    owner_id            BIGINT NOT NULL REFERENCES users(id),
    provider_id         BIGINT REFERENCES users(id),
    team_id             BIGINT REFERENCES teams(id),
    bid_id              BIGINT,
    -- 基本信息
    title               VARCHAR(200) NOT NULL,
    description         TEXT NOT NULL,
    category            VARCHAR(50) NOT NULL,
    template_type       VARCHAR(50),
    -- AI生成内容
    ai_prd              JSONB,
    ai_estimate         JSONB,
    confirmed_prd       JSONB,
    -- 预算与工期
    budget_min          DECIMAL(10,2),
    budget_max          DECIMAL(10,2),
    agreed_price        DECIMAL(10,2),
    deadline            DATE,
    agreed_days         INT,
    start_date          DATE,
    actual_end_date     DATE,
    -- 分类属性
    complexity          VARCHAR(10),
    tech_requirements   JSONB DEFAULT '[]',
    attachments         JSONB DEFAULT '[]',
    -- 撮合
    match_mode          SMALLINT NOT NULL DEFAULT 1,
    -- 进度
    progress            SMALLINT NOT NULL DEFAULT 0,
    current_milestone_id BIGINT,
    -- 状态: 1=草稿 2=已发布 3=匹配中 4=已匹配 5=进行中 6=验收中 7=已完成 8=已关闭 9=争议中
    status              SMALLINT NOT NULL DEFAULT 1,
    close_reason        VARCHAR(200),
    -- 统计
    view_count          INT NOT NULL DEFAULT 0,
    bid_count           INT NOT NULL DEFAULT 0,
    favorite_count      INT NOT NULL DEFAULT 0,
    -- 时间戳
    published_at        TIMESTAMPTZ,
    matched_at          TIMESTAMPTZ,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE projects IS '项目/需求表';
COMMENT ON COLUMN projects.status IS '1=草稿 2=已发布 3=匹配中 4=已匹配 5=进行中 6=验收中 7=已完成 8=已关闭 9=争议中';

CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_provider ON projects(provider_id);
CREATE INDEX idx_projects_team ON projects(team_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_category ON projects(category);
CREATE INDEX idx_projects_match_mode ON projects(match_mode);
CREATE INDEX idx_projects_complexity ON projects(complexity);
CREATE INDEX idx_projects_published_at ON projects(published_at DESC);
CREATE INDEX idx_projects_created_at ON projects(created_at DESC);
CREATE INDEX idx_projects_tech ON projects USING GIN(tech_requirements);
CREATE INDEX idx_projects_budget ON projects(budget_min, budget_max);
CREATE INDEX idx_projects_list ON projects(status, published_at DESC) WHERE status IN (2, 3);

-- 添加teams表中延迟的projects外键
ALTER TABLE teams ADD CONSTRAINT fk_teams_project FOREIGN KEY (project_id) REFERENCES projects(id);
CREATE INDEX idx_teams_project ON teams(project_id);

-- =============================================================================
-- 10. 作品集表 (依赖 users, projects)
-- =============================================================================
CREATE TABLE portfolios (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id             BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id          BIGINT REFERENCES projects(id),
    title               VARCHAR(200) NOT NULL,
    description         TEXT,
    category            VARCHAR(50) NOT NULL,
    cover_url           VARCHAR(512),
    preview_url         VARCHAR(512),
    tech_stack          JSONB DEFAULT '[]',
    images              JSONB DEFAULT '[]',
    demo_video_url      VARCHAR(512),
    is_platform_certified BOOLEAN NOT NULL DEFAULT FALSE,
    certified_at        TIMESTAMPTZ,
    view_count          INT NOT NULL DEFAULT 0,
    like_count          INT NOT NULL DEFAULT 0,
    sort_order          INT NOT NULL DEFAULT 0,
    status              SMALLINT NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE portfolios IS '供给方作品集表';

CREATE INDEX idx_portfolios_user ON portfolios(user_id);
CREATE INDEX idx_portfolios_category ON portfolios(category);
CREATE INDEX idx_portfolios_status ON portfolios(status);
CREATE INDEX idx_portfolios_tech ON portfolios USING GIN(tech_stack);
CREATE INDEX idx_portfolios_certified ON portfolios(is_platform_certified) WHERE is_platform_certified = TRUE;

-- =============================================================================
-- 11. 投标表 (依赖 projects, users, teams)
-- =============================================================================
CREATE TABLE bids (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id),
    bidder_id           BIGINT REFERENCES users(id),
    team_id             BIGINT REFERENCES teams(id),
    price               DECIMAL(10,2) NOT NULL,
    estimated_days      INT NOT NULL,
    proposal            TEXT,
    tech_solution       TEXT,
    status              SMALLINT NOT NULL DEFAULT 1,
    reject_reason       VARCHAR(200),
    accepted_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_bids_bidder CHECK (bidder_id IS NOT NULL OR team_id IS NOT NULL)
);

COMMENT ON TABLE bids IS '投标表';

CREATE INDEX idx_bids_project ON bids(project_id);
CREATE INDEX idx_bids_bidder ON bids(bidder_id);
CREATE INDEX idx_bids_team ON bids(team_id);
CREATE INDEX idx_bids_status ON bids(status);
CREATE INDEX idx_bids_created_at ON bids(created_at DESC);
CREATE UNIQUE INDEX idx_bids_unique_personal ON bids(project_id, bidder_id) WHERE bidder_id IS NOT NULL AND status NOT IN (4, 5);
CREATE UNIQUE INDEX idx_bids_unique_team ON bids(project_id, team_id) WHERE team_id IS NOT NULL AND status NOT IN (4, 5);

-- =============================================================================
-- 12. 里程碑表 (依赖 projects)
-- =============================================================================
CREATE TABLE milestones (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title               VARCHAR(200) NOT NULL,
    description         TEXT,
    sort_order          INT NOT NULL,
    payment_ratio       DECIMAL(5,2),
    payment_amount      DECIMAL(10,2),
    due_date            DATE,
    status              SMALLINT NOT NULL DEFAULT 1,
    delivery_note       TEXT,
    preview_url         VARCHAR(512),
    rejection_reason    TEXT,
    delivered_at        TIMESTAMPTZ,
    accepted_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE milestones IS '项目里程碑表';

CREATE INDEX idx_milestones_project ON milestones(project_id);
CREATE INDEX idx_milestones_status ON milestones(status);
CREATE INDEX idx_milestones_due_date ON milestones(due_date);

-- =============================================================================
-- 13. EARS任务卡片表 (依赖 projects, milestones, users, tasks自引用)
-- =============================================================================
CREATE TABLE tasks (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    milestone_id        BIGINT REFERENCES milestones(id),
    parent_task_id      BIGINT REFERENCES tasks(id),
    task_code           VARCHAR(20) NOT NULL,
    title               VARCHAR(200) NOT NULL,
    -- EARS核心字段
    ears_type           VARCHAR(20) NOT NULL,
    ears_trigger        TEXT,
    ears_behavior       TEXT NOT NULL,
    ears_full_text      TEXT NOT NULL,
    -- 任务属性
    module              VARCHAR(100),
    role_tag            VARCHAR(50),
    assignee_id         BIGINT REFERENCES users(id),
    priority            SMALLINT NOT NULL DEFAULT 2,
    estimated_hours     DECIMAL(5,1),
    actual_hours        DECIMAL(5,1),
    -- 验收标准
    acceptance_criteria JSONB NOT NULL DEFAULT '[]',
    -- 依赖关系
    dependencies        JSONB NOT NULL DEFAULT '[]',
    blockers            JSONB NOT NULL DEFAULT '[]',
    -- 状态
    status              SMALLINT NOT NULL DEFAULT 1,
    sort_order          INT NOT NULL DEFAULT 0,
    -- AI生成标识
    is_ai_generated     BOOLEAN NOT NULL DEFAULT FALSE,
    ai_confidence       DECIMAL(3,2),
    -- 扩展属性
    extra               JSONB DEFAULT '{}',
    -- 时间戳
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE tasks IS 'EARS任务卡片表';
COMMENT ON COLUMN tasks.ears_type IS 'EARS类型：ubiquitous=始终/event=事件/state=状态/optional=可选/unwanted=异常';
COMMENT ON COLUMN tasks.status IS '1=待办 2=进行中 3=已完成 4=已验收 5=已关闭';

CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_milestone ON tasks(milestone_id);
CREATE INDEX idx_tasks_parent ON tasks(parent_task_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_ears_type ON tasks(ears_type);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_module ON tasks(module);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_board ON tasks(project_id, status, sort_order);
CREATE INDEX idx_tasks_overview ON tasks(project_id, module, sort_order);
CREATE INDEX idx_tasks_personal ON tasks(assignee_id, status) WHERE assignee_id IS NOT NULL;

-- =============================================================================
-- 14. 匹配推荐记录表 (依赖 projects, users, teams)
-- =============================================================================
CREATE TABLE matches (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id),
    provider_id         BIGINT REFERENCES users(id),
    team_id             BIGINT REFERENCES teams(id),
    match_type          SMALLINT NOT NULL,
    match_score         DECIMAL(5,2),
    score_detail        JSONB DEFAULT '{}',
    rank_position       INT,
    status              SMALLINT NOT NULL DEFAULT 1,
    viewed_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_matches_target CHECK (provider_id IS NOT NULL OR team_id IS NOT NULL)
);

COMMENT ON TABLE matches IS '匹配推荐记录表';

CREATE INDEX idx_matches_project ON matches(project_id);
CREATE INDEX idx_matches_provider ON matches(provider_id);
CREATE INDEX idx_matches_team ON matches(team_id);
CREATE INDEX idx_matches_type ON matches(match_type);
CREATE INDEX idx_matches_score ON matches(match_score DESC);
CREATE INDEX idx_matches_created_at ON matches(created_at DESC);

-- =============================================================================
-- 15. 收藏表 (依赖 users)
-- =============================================================================
CREATE TABLE favorites (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type         SMALLINT NOT NULL,
    target_id           BIGINT NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id)
);

COMMENT ON TABLE favorites IS '用户收藏表';

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_target ON favorites(target_type, target_id);

-- =============================================================================
-- 16. 会话表 (依赖 projects, users)
-- =============================================================================
CREATE TABLE conversations (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT REFERENCES projects(id),
    conversation_type   SMALLINT NOT NULL DEFAULT 1,
    user_a_id           BIGINT REFERENCES users(id),
    user_b_id           BIGINT REFERENCES users(id),
    last_message_content VARCHAR(200),
    last_message_type   VARCHAR(20),
    last_message_at     TIMESTAMPTZ,
    last_message_user_id BIGINT,
    status              SMALLINT NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE conversations IS '会话表';

CREATE INDEX idx_conversations_user_a ON conversations(user_a_id);
CREATE INDEX idx_conversations_user_b ON conversations(user_b_id);
CREATE INDEX idx_conversations_project ON conversations(project_id);
CREATE INDEX idx_conversations_last_msg ON conversations(last_message_at DESC);
CREATE UNIQUE INDEX idx_conversations_private ON conversations(user_a_id, user_b_id) WHERE conversation_type = 1;

-- =============================================================================
-- 17. 会话成员表 (依赖 conversations, users)
-- =============================================================================
CREATE TABLE conversation_members (
    id                  BIGSERIAL PRIMARY KEY,
    conversation_id     BIGINT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES users(id),
    role                SMALLINT NOT NULL DEFAULT 1,
    unread_count        INT NOT NULL DEFAULT 0,
    last_read_msg_id    BIGINT DEFAULT 0,
    is_muted            BOOLEAN NOT NULL DEFAULT FALSE,
    is_pinned           BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_conv_members_conv ON conversation_members(conversation_id);
CREATE INDEX idx_conv_members_user ON conversation_members(user_id);

-- =============================================================================
-- 18. 消息表 (依赖 conversations, users, tasks)
-- =============================================================================
CREATE TABLE messages (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    conversation_id     BIGINT NOT NULL REFERENCES conversations(id),
    sender_id           BIGINT NOT NULL REFERENCES users(id),
    content_type        VARCHAR(20) NOT NULL DEFAULT 'text',
    content             TEXT,
    media_url           VARCHAR(512),
    media_name          VARCHAR(200),
    media_size          INT,
    media_duration      INT,
    thumbnail_url       VARCHAR(512),
    reply_to_msg_id     BIGINT REFERENCES messages(id),
    related_task_id     BIGINT REFERENCES tasks(id),
    client_seq          BIGINT,
    status              SMALLINT NOT NULL DEFAULT 1,
    recalled_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE messages IS '聊天消息表';

CREATE INDEX idx_messages_conversation ON messages(conversation_id, id DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_messages_related_task ON messages(related_task_id) WHERE related_task_id IS NOT NULL;
CREATE UNIQUE INDEX idx_messages_dedup ON messages(conversation_id, sender_id, client_seq) WHERE client_seq IS NOT NULL;

-- =============================================================================
-- 19. 评价表 (依赖 projects, users)
-- =============================================================================
CREATE TABLE reviews (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id),
    reviewer_id         BIGINT NOT NULL REFERENCES users(id),
    reviewee_id         BIGINT NOT NULL REFERENCES users(id),
    reviewer_role       SMALLINT NOT NULL,
    overall_rating      DECIMAL(2,1) NOT NULL CHECK (overall_rating BETWEEN 1.0 AND 5.0),
    quality_rating      DECIMAL(2,1) CHECK (quality_rating BETWEEN 1.0 AND 5.0),
    communication_rating DECIMAL(2,1) CHECK (communication_rating BETWEEN 1.0 AND 5.0),
    timeliness_rating   DECIMAL(2,1) CHECK (timeliness_rating BETWEEN 1.0 AND 5.0),
    professionalism_rating DECIMAL(2,1) CHECK (professionalism_rating BETWEEN 1.0 AND 5.0),
    requirement_clarity DECIMAL(2,1) CHECK (requirement_clarity BETWEEN 1.0 AND 5.0),
    payment_rating      DECIMAL(2,1) CHECK (payment_rating BETWEEN 1.0 AND 5.0),
    cooperation_rating  DECIMAL(2,1) CHECK (cooperation_rating BETWEEN 1.0 AND 5.0),
    content             TEXT,
    tags                JSONB DEFAULT '[]',
    member_ratings      JSONB DEFAULT '[]',
    is_anonymous        BOOLEAN NOT NULL DEFAULT FALSE,
    status              SMALLINT NOT NULL DEFAULT 1,
    reply_content       TEXT,
    reply_at            TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE reviews IS '双向评价表';

CREATE INDEX idx_reviews_project ON reviews(project_id);
CREATE INDEX idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewee ON reviews(reviewee_id);
CREATE INDEX idx_reviews_role ON reviews(reviewer_role);
CREATE INDEX idx_reviews_rating ON reviews(overall_rating DESC);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);
CREATE UNIQUE INDEX idx_reviews_unique ON reviews(project_id, reviewer_id, reviewee_id);

-- =============================================================================
-- 20. 通知表 (依赖 users)
-- =============================================================================
CREATE TABLE notifications (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id             BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title               VARCHAR(200) NOT NULL,
    content             TEXT NOT NULL,
    notification_type   SMALLINT NOT NULL,
    target_type         VARCHAR(50),
    target_id           BIGINT,
    is_read             BOOLEAN NOT NULL DEFAULT FALSE,
    is_pushed           BOOLEAN NOT NULL DEFAULT FALSE,
    push_result         VARCHAR(200),
    read_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE notifications IS '通知表';

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = FALSE;

-- =============================================================================
-- 21. 订单表 (依赖 projects, milestones, users, teams)
-- =============================================================================
CREATE TABLE orders (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    order_no            VARCHAR(32) NOT NULL UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id),
    milestone_id        BIGINT REFERENCES milestones(id),
    payer_id            BIGINT NOT NULL REFERENCES users(id),
    payee_id            BIGINT REFERENCES users(id),
    payee_team_id       BIGINT REFERENCES teams(id),
    amount              DECIMAL(10,2) NOT NULL,
    platform_fee_rate   DECIMAL(5,4) NOT NULL DEFAULT 0.1200,
    platform_fee        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    actual_amount       DECIMAL(10,2),
    payment_method      VARCHAR(20),
    trade_no            VARCHAR(64),
    -- 状态: 1=待支付 2=担保中 3=已释放 4=已到账 5=退款中 6=已退款 7=已取消 8=争议冻结
    status              SMALLINT NOT NULL DEFAULT 1,
    refund_amount       DECIMAL(10,2),
    refund_reason       VARCHAR(200),
    refund_trade_no     VARCHAR(64),
    paid_at             TIMESTAMPTZ,
    escrow_at           TIMESTAMPTZ,
    released_at         TIMESTAMPTZ,
    withdrawn_at        TIMESTAMPTZ,
    refunded_at         TIMESTAMPTZ,
    expire_at           TIMESTAMPTZ,
    auto_release_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE orders IS '支付订单表';
COMMENT ON COLUMN orders.status IS '1=待支付 2=担保中 3=已释放 4=已到账 5=退款中 6=已退款 7=已取消 8=争议冻结';

CREATE INDEX idx_orders_order_no ON orders(order_no);
CREATE INDEX idx_orders_project ON orders(project_id);
CREATE INDEX idx_orders_milestone ON orders(milestone_id);
CREATE INDEX idx_orders_payer ON orders(payer_id);
CREATE INDEX idx_orders_payee ON orders(payee_id);
CREATE INDEX idx_orders_payee_team ON orders(payee_team_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_trade_no ON orders(trade_no) WHERE trade_no IS NOT NULL;
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_auto_release ON orders(auto_release_at) WHERE status = 2 AND auto_release_at IS NOT NULL;
CREATE INDEX idx_orders_expire ON orders(expire_at) WHERE status = 1;

-- =============================================================================
-- 22. 钱包表 (依赖 users)
-- =============================================================================
CREATE TABLE wallets (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(id) UNIQUE,
    available_balance   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    frozen_balance      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_income        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_withdrawn     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE wallets IS '用户钱包表';

-- =============================================================================
-- 23. 钱包交易流水表 (依赖 wallets, users, orders)
-- =============================================================================
CREATE TABLE wallet_transactions (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    wallet_id           BIGINT NOT NULL REFERENCES wallets(id),
    user_id             BIGINT NOT NULL REFERENCES users(id),
    order_id            BIGINT REFERENCES orders(id),
    transaction_type    SMALLINT NOT NULL,
    amount              DECIMAL(10,2) NOT NULL,
    balance_before      DECIMAL(12,2) NOT NULL,
    balance_after       DECIMAL(12,2) NOT NULL,
    withdraw_method     VARCHAR(20),
    withdraw_account    VARCHAR(200),
    withdraw_trade_no   VARCHAR(64),
    remark              VARCHAR(200),
    status              SMALLINT NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE wallet_transactions IS '钱包交易流水表';

CREATE INDEX idx_wallet_txn_wallet ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_txn_user ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_txn_order ON wallet_transactions(order_id);
CREATE INDEX idx_wallet_txn_type ON wallet_transactions(transaction_type);
CREATE INDEX idx_wallet_txn_created ON wallet_transactions(created_at DESC);

-- =============================================================================
-- 24. 分账记录表 (依赖 orders, teams, users)
-- =============================================================================
CREATE TABLE split_records (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    order_id            BIGINT NOT NULL REFERENCES orders(id),
    team_id             BIGINT NOT NULL REFERENCES teams(id),
    user_id             BIGINT NOT NULL REFERENCES users(id),
    split_ratio         DECIMAL(5,2) NOT NULL,
    amount              DECIMAL(10,2) NOT NULL,
    status              SMALLINT NOT NULL DEFAULT 1,
    split_at            TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE split_records IS '团队分账记录表';

CREATE INDEX idx_split_records_order ON split_records(order_id);
CREATE INDEX idx_split_records_team ON split_records(team_id);
CREATE INDEX idx_split_records_user ON split_records(user_id);
CREATE INDEX idx_split_records_status ON split_records(status);

-- =============================================================================
-- 25. 举报表 (依赖 users)
-- =============================================================================
CREATE TABLE reports (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    reporter_id         BIGINT NOT NULL REFERENCES users(id),
    target_type         VARCHAR(50) NOT NULL,
    target_id           BIGINT NOT NULL,
    reason_type         SMALLINT NOT NULL,
    reason_detail       TEXT,
    evidence            JSONB DEFAULT '[]',
    status              SMALLINT NOT NULL DEFAULT 1,
    handler_id          BIGINT REFERENCES users(id),
    handle_result       TEXT,
    handled_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE reports IS '举报表';

CREATE INDEX idx_reports_reporter ON reports(reporter_id);
CREATE INDEX idx_reports_target ON reports(target_type, target_id);
CREATE INDEX idx_reports_status ON reports(status);

-- =============================================================================
-- 26. 仲裁表 (依赖 projects, orders, users)
-- =============================================================================
CREATE TABLE arbitrations (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    project_id          BIGINT NOT NULL REFERENCES projects(id),
    order_id            BIGINT REFERENCES orders(id),
    applicant_id        BIGINT NOT NULL REFERENCES users(id),
    respondent_id       BIGINT NOT NULL REFERENCES users(id),
    reason              TEXT NOT NULL,
    evidence            JSONB DEFAULT '[]',
    status              SMALLINT NOT NULL DEFAULT 1,
    arbiter_id          BIGINT REFERENCES users(id),
    verdict             TEXT,
    verdict_type        SMALLINT,
    refund_amount       DECIMAL(10,2),
    arbitrated_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE arbitrations IS '仲裁表';

CREATE INDEX idx_arbitrations_project ON arbitrations(project_id);
CREATE INDEX idx_arbitrations_applicant ON arbitrations(applicant_id);
CREATE INDEX idx_arbitrations_status ON arbitrations(status);

-- =============================================================================
-- 27. AI Agent会话表 (依赖 users, projects)
-- =============================================================================
CREATE TABLE agent_sessions (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id             BIGINT NOT NULL REFERENCES users(id),
    project_id          BIGINT REFERENCES projects(id),
    agent_type          VARCHAR(50) NOT NULL,
    status              SMALLINT NOT NULL DEFAULT 1,
    completeness_score  DECIMAL(5,2) DEFAULT 0.00,
    conversation_history JSONB NOT NULL DEFAULT '[]',
    generated_prd       JSONB,
    generated_tasks     JSONB,
    generated_estimate  JSONB,
    model_used          VARCHAR(50),
    total_tokens        INT DEFAULT 0,
    total_cost          DECIMAL(8,4) DEFAULT 0.0000,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE agent_sessions IS 'AI Agent会话表';

CREATE INDEX idx_agent_sessions_user ON agent_sessions(user_id);
CREATE INDEX idx_agent_sessions_project ON agent_sessions(project_id);
CREATE INDEX idx_agent_sessions_type ON agent_sessions(agent_type);
CREATE INDEX idx_agent_sessions_status ON agent_sessions(status);

-- =============================================================================
-- 28. 组队大厅帖子表 (依赖 users, projects)
-- =============================================================================
CREATE TABLE team_posts (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    author_id           BIGINT NOT NULL REFERENCES users(id),
    project_id          BIGINT REFERENCES projects(id),
    title               VARCHAR(200) NOT NULL,
    description         TEXT NOT NULL,
    needed_roles        JSONB NOT NULL DEFAULT '[]',
    required_skills     JSONB DEFAULT '[]',
    status              SMALLINT NOT NULL DEFAULT 1,
    view_count          INT NOT NULL DEFAULT 0,
    apply_count         INT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE team_posts IS '组队大厅帖子表';

CREATE INDEX idx_team_posts_author ON team_posts(author_id);
CREATE INDEX idx_team_posts_project ON team_posts(project_id);
CREATE INDEX idx_team_posts_status ON team_posts(status);
CREATE INDEX idx_team_posts_skills ON team_posts USING GIN(required_skills);
CREATE INDEX idx_team_posts_created ON team_posts(created_at DESC);

-- =============================================================================
-- 29. 辅助表
-- =============================================================================

-- 短信验证码表
CREATE TABLE sms_codes (
    id                  BIGSERIAL PRIMARY KEY,
    phone_hash          VARCHAR(64) NOT NULL,
    code                VARCHAR(6) NOT NULL,
    purpose             SMALLINT NOT NULL,
    is_used             BOOLEAN NOT NULL DEFAULT FALSE,
    expire_at           TIMESTAMPTZ NOT NULL,
    ip_address          VARCHAR(45),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sms_codes_phone ON sms_codes(phone_hash, purpose, created_at DESC);
CREATE INDEX idx_sms_codes_expire ON sms_codes(expire_at) WHERE is_used = FALSE;

-- 用户设备表
CREATE TABLE user_devices (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id           VARCHAR(128) NOT NULL,
    device_type         VARCHAR(20) NOT NULL,
    device_name         VARCHAR(100),
    push_token          VARCHAR(512),
    app_version         VARCHAR(20),
    os_version          VARCHAR(20),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    last_active_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_user_devices_user ON user_devices(user_id);
CREATE INDEX idx_user_devices_push ON user_devices(push_token) WHERE push_token IS NOT NULL;

-- 操作日志表
CREATE TABLE admin_operation_logs (
    id                  BIGSERIAL PRIMARY KEY,
    admin_id            BIGINT NOT NULL REFERENCES users(id),
    action              VARCHAR(100) NOT NULL,
    target_type         VARCHAR(50) NOT NULL,
    target_id           BIGINT NOT NULL,
    detail              JSONB,
    ip_address          VARCHAR(45),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_admin_logs_admin ON admin_operation_logs(admin_id);
CREATE INDEX idx_admin_logs_target ON admin_operation_logs(target_type, target_id);
CREATE INDEX idx_admin_logs_created ON admin_operation_logs(created_at DESC);

-- 优惠券表
CREATE TABLE coupons (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    code                VARCHAR(20) NOT NULL UNIQUE,
    name                VARCHAR(100) NOT NULL,
    coupon_type         SMALLINT NOT NULL,
    discount_value      DECIMAL(10,2) NOT NULL,
    min_order_amount    DECIMAL(10,2) DEFAULT 0.00,
    max_discount        DECIMAL(10,2),
    total_count         INT NOT NULL,
    used_count          INT NOT NULL DEFAULT 0,
    start_at            TIMESTAMPTZ NOT NULL,
    expire_at           TIMESTAMPTZ NOT NULL,
    status              SMALLINT NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 用户优惠券关联表
CREATE TABLE user_coupons (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(id),
    coupon_id           BIGINT NOT NULL REFERENCES coupons(id),
    order_id            BIGINT REFERENCES orders(id),
    status              SMALLINT NOT NULL DEFAULT 1,
    used_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_coupons_user ON user_coupons(user_id, status);
CREATE INDEX idx_user_coupons_coupon ON user_coupons(coupon_id);

-- =============================================================================
-- 30. 物化视图
-- =============================================================================

-- 项目概览物化视图
CREATE MATERIALIZED VIEW mv_project_overview AS
SELECT
    t.project_id,
    t.module,
    COUNT(*) AS total_tasks,
    COUNT(*) FILTER (WHERE t.status >= 3) AS completed_tasks,
    COUNT(*) FILTER (WHERE t.status = 2) AS in_progress_tasks,
    COUNT(*) FILTER (WHERE t.status = 1) AS pending_tasks,
    COALESCE(SUM(t.estimated_hours), 0) AS total_estimated_hours,
    COALESCE(SUM(t.actual_hours), 0) AS total_actual_hours,
    ROUND(COUNT(*) FILTER (WHERE t.status >= 3) * 100.0 / NULLIF(COUNT(*), 0), 1) AS completion_rate
FROM tasks t
GROUP BY t.project_id, t.module;

CREATE UNIQUE INDEX idx_mv_project_overview ON mv_project_overview(project_id, module);

-- 供给方统计物化视图
CREATE MATERIALIZED VIEW mv_provider_stats AS
SELECT
    u.id AS user_id,
    u.uuid,
    u.nickname,
    u.avatar_url,
    u.credit_score,
    u.level,
    u.avg_rating,
    u.completion_rate,
    u.total_orders,
    u.available_status,
    u.hourly_rate,
    u.response_time_avg
FROM users u
WHERE u.role IN (2, 3) AND u.status = 1;

CREATE UNIQUE INDEX idx_mv_provider_stats ON mv_provider_stats(user_id);

-- =============================================================================
-- 31. 通用触发器: updated_at 自动更新
-- =============================================================================
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为所有含 updated_at 字段的表创建触发器
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name FROM information_schema.columns
        WHERE column_name = 'updated_at'
        AND table_schema = 'public'
        AND table_name NOT LIKE 'mv_%'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at()',
            t
        );
    END LOOP;
END;
$$;

-- =============================================================================
-- 32. 种子数据 (Seed Data)
-- =============================================================================

-- 技能标签
INSERT INTO skills (name, category, sort_order, is_hot) VALUES
-- 编程语言
('Go', 'language', 1, TRUE),
('Python', 'language', 2, TRUE),
('Java', 'language', 3, TRUE),
('JavaScript', 'language', 4, TRUE),
('TypeScript', 'language', 5, TRUE),
('Dart', 'language', 6, TRUE),
('Swift', 'language', 7, FALSE),
('Kotlin', 'language', 8, FALSE),
('Rust', 'language', 9, FALSE),
('C++', 'language', 10, FALSE),
('PHP', 'language', 11, FALSE),
('Ruby', 'language', 12, FALSE),
('C#', 'language', 13, FALSE),
-- 前端框架
('React', 'framework', 20, TRUE),
('Vue.js', 'framework', 21, TRUE),
('Next.js', 'framework', 22, TRUE),
('Flutter', 'framework', 23, TRUE),
('React Native', 'framework', 24, FALSE),
('Angular', 'framework', 25, FALSE),
('Svelte', 'framework', 26, FALSE),
('uni-app', 'framework', 27, FALSE),
('Taro', 'framework', 28, FALSE),
-- 后端框架
('Spring Boot', 'framework', 30, TRUE),
('Django', 'framework', 31, FALSE),
('FastAPI', 'framework', 32, FALSE),
('Express.js', 'framework', 33, FALSE),
('Gin', 'framework', 34, TRUE),
('Fiber', 'framework', 35, FALSE),
('NestJS', 'framework', 36, FALSE),
('Laravel', 'framework', 37, FALSE),
-- 数据库
('MySQL', 'tool', 40, TRUE),
('PostgreSQL', 'tool', 41, TRUE),
('MongoDB', 'tool', 42, FALSE),
('Redis', 'tool', 43, TRUE),
('Elasticsearch', 'tool', 44, FALSE),
('SQLite', 'tool', 45, FALSE),
-- AI/ML
('PyTorch', 'tool', 50, FALSE),
('TensorFlow', 'tool', 51, FALSE),
('LangChain', 'tool', 52, TRUE),
('LlamaIndex', 'tool', 53, FALSE),
('OpenAI API', 'tool', 54, TRUE),
('Stable Diffusion', 'tool', 55, FALSE),
-- DevOps/Cloud
('Docker', 'tool', 60, TRUE),
('Kubernetes', 'tool', 61, FALSE),
('AWS', 'tool', 62, FALSE),
('阿里云', 'tool', 63, TRUE),
('腾讯云', 'tool', 64, FALSE),
('Nginx', 'tool', 65, FALSE),
('CI/CD', 'tool', 66, FALSE),
-- 设计工具
('Figma', 'design', 70, TRUE),
('Sketch', 'design', 71, FALSE),
('Adobe XD', 'design', 72, FALSE),
('Photoshop', 'design', 73, FALSE),
('Illustrator', 'design', 74, FALSE),
('After Effects', 'design', 75, FALSE),
('Blender', 'design', 76, FALSE),
('Principle', 'design', 77, FALSE),
-- 其他
('微信小程序', 'other', 80, TRUE),
('支付宝小程序', 'other', 81, FALSE),
('微信支付', 'other', 82, FALSE),
('数据分析', 'other', 83, FALSE),
('爬虫', 'other', 84, FALSE),
('区块链', 'other', 85, FALSE),
('游戏开发', 'other', 86, FALSE),
('Unity', 'other', 87, FALSE),
('Unreal Engine', 'other', 88, FALSE);

-- 角色标签
INSERT INTO role_tags (name, description, sort_order) VALUES
('后端开发', '服务端API、数据库、微服务开发', 1),
('前端开发', 'Web前端、H5页面开发', 2),
('移动端开发', 'iOS/Android/Flutter APP开发', 3),
('全栈开发', '前后端一体化开发', 4),
('UI设计', '界面设计、视觉设计', 5),
('UX设计', '用户体验设计、交互设计', 6),
('产品经理', '需求分析、产品规划', 7),
('项目经理', '项目管理、进度管控', 8),
('AI工程师', '机器学习、NLP、LLM应用开发', 9),
('数据工程师', '数据分析、ETL、数据可视化', 10),
('测试工程师', '质量保证、自动化测试', 11),
('DevOps工程师', '运维、部署、CI/CD', 12),
('架构师', '系统架构设计、技术选型', 13),
('安全工程师', '安全审计、渗透测试', 14),
('小程序开发', '微信/支付宝小程序开发', 15),
('游戏开发', '游戏客户端/服务端开发', 16),
('区块链开发', '智能合约、DApp开发', 17),
('技术顾问', '技术咨询、代码审查', 18);

-- 插入管理员账号 (密码需要后续通过应用层设置)
INSERT INTO users (uuid, nickname, role, status, credit_score, level) VALUES
('00000000-0000-0000-0000-000000000001', '系统管理员', 9, 1, 1000, 5);

RAISE NOTICE 'Database initialization completed successfully.';
