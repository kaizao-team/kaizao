"""
开造 VibeBuild — ORM 模型定义
Project 表映射 Go 后端 kaizao.projects（只读/部分写）
AI 独有表统一 ai_ 前缀
"""

from datetime import datetime
from typing import Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
    Date,
    DateTime,
    DECIMAL,
    Index,
    Integer,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.mysql import JSON
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


# ============================================================
# Go 后端权威表 — AI Agent 只读/部分写
# ============================================================

class User(Base):
    """
    映射 Go 后端 kaizao.users 表 — AI Agent 只读。
    用于智能撮合时读取供给方真实数据。
    """
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    uuid: Mapped[str] = mapped_column(String(36), unique=True, nullable=False)
    nickname: Mapped[str] = mapped_column(String(50), nullable=False, default="")
    avatar_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    role: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    bio: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    city: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    hourly_rate: Mapped[Optional[float]] = mapped_column(DECIMAL(10, 2), nullable=True)
    available_status: Mapped[int] = mapped_column(SmallInteger, default=1)
    response_time_avg: Mapped[int] = mapped_column(Integer, default=0)
    credit_score: Mapped[int] = mapped_column(Integer, nullable=False, default=500)
    level: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    total_orders: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    completed_orders: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    completion_rate: Mapped[float] = mapped_column(DECIMAL(5, 2), nullable=False, default=0)
    avg_rating: Mapped[float] = mapped_column(DECIMAL(3, 2), nullable=False, default=0)
    total_earnings: Mapped[float] = mapped_column(DECIMAL(12, 2), nullable=False, default=0)
    onboarding_status: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=2)
    status: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    __table_args__ = {"extend_existing": True}


class Project(Base):
    """
    映射 Go 后端 kaizao.projects 表。
    AI Agent 只 UPDATE ai_prd / ai_estimate / confirmed_prd 等字段，
    不 INSERT 也不 DELETE 此表的行。
    """
    __tablename__ = "projects"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    uuid: Mapped[str] = mapped_column(String(36), unique=True, nullable=False)
    owner_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    provider_id: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    team_id: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    bid_id: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False, default="")
    description: Mapped[str] = mapped_column(Text, nullable=False, default="")
    category: Mapped[str] = mapped_column(String(50), nullable=False, default="")
    template_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    # AI 生成内容 — Agent 主写字段
    ai_prd: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    ai_estimate: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    confirmed_prd: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    # 预算与工期
    budget_min: Mapped[Optional[float]] = mapped_column(DECIMAL(10, 2), nullable=True)
    budget_max: Mapped[Optional[float]] = mapped_column(DECIMAL(10, 2), nullable=True)
    agreed_price: Mapped[Optional[float]] = mapped_column(DECIMAL(10, 2), nullable=True)
    deadline: Mapped[Optional[datetime]] = mapped_column(Date, nullable=True)
    agreed_days: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    start_date: Mapped[Optional[datetime]] = mapped_column(Date, nullable=True)
    actual_end_date: Mapped[Optional[datetime]] = mapped_column(Date, nullable=True)
    # 分类属性
    complexity: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    tech_requirements: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    attachments: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    # 撮合
    match_mode: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    # 进度
    progress: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    current_milestone_id: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    # 状态
    status: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    close_reason: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    # 统计
    view_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    bid_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    favorite_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    # 时间戳
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    matched_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # 告诉 SQLAlchemy 不要尝试 CREATE 这张表
    __table_args__ = {"extend_existing": True}


# ============================================================
# AI Agent 独有表 — 统一 ai_ 前缀
# ============================================================

class AIProjectStage(Base):
    """AI 流水线阶段状态表"""
    __tablename__ = "ai_project_stages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)  # Go 后端 projects.uuid
    stage_name: Mapped[str] = mapped_column(String(20))
    status: Mapped[str] = mapped_column(String(30), default="pending")
    sub_stage: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    document_path: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    __table_args__ = (
        UniqueConstraint("project_id", "stage_name", name="uq_ai_project_stage"),
    )


class AIDocument(Base):
    """AI 文档记录表"""
    __tablename__ = "ai_documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)
    stage: Mapped[str] = mapped_column(String(20))
    filename: Mapped[str] = mapped_column(String(128))
    file_path: Mapped[str] = mapped_column(String(512))
    version: Mapped[int] = mapped_column(Integer, default=1)
    size_bytes: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("project_id", "filename", "version", name="uq_ai_doc_version"),
    )


class AIConversationMessage(Base):
    """AI 对话消息表"""
    __tablename__ = "ai_conversation_messages"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    session_id: Mapped[str] = mapped_column(String(64))
    project_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    role: Mapped[str] = mapped_column(String(20))
    content: Mapped[str] = mapped_column(Text)
    message_index: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        Index("idx_ai_session", "session_id", "message_index"),
    )


class AIProviderProfile(Base):
    """AI 供给方档案表"""
    __tablename__ = "ai_provider_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    type: Mapped[str] = mapped_column(String(10), default="individual")
    display_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    vibe_power: Mapped[int] = mapped_column(Integer, default=0)
    vibe_level: Mapped[str] = mapped_column(String(20), default="vc-T1")
    level_weight: Mapped[float] = mapped_column(DECIMAL(3, 2), default=1.00)
    review_tags: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    skills: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    experience_years: Mapped[int] = mapped_column(Integer, default=0)
    ai_tools: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    resume_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    score_tech_depth: Mapped[int] = mapped_column(Integer, default=0)
    score_project_exp: Mapped[int] = mapped_column(Integer, default=0)
    score_ai_proficiency: Mapped[int] = mapped_column(Integer, default=0)
    score_portfolio: Mapped[int] = mapped_column(Integer, default=0)
    score_background: Mapped[int] = mapped_column(Integer, default=0)
    total_projects: Mapped[int] = mapped_column(Integer, default=0)
    completed_projects: Mapped[int] = mapped_column(Integer, default=0)
    avg_rating: Mapped[float] = mapped_column(DECIMAL(3, 2), default=0)
    on_time_rate: Mapped[float] = mapped_column(DECIMAL(5, 2), default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (
        Index("idx_ai_user", "user_id"),
        Index("idx_ai_level", "vibe_level", "vibe_power"),
    )


class AIVibePowerLog(Base):
    """AI 积分变动记录表"""
    __tablename__ = "ai_vibe_power_logs"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    provider_id: Mapped[str] = mapped_column(String(36), nullable=False)
    action: Mapped[str] = mapped_column(String(50))
    points: Mapped[int] = mapped_column(Integer)
    reason: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    project_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        Index("idx_ai_provider", "provider_id", "created_at"),
    )


class AIMatchResult(Base):
    """AI 撮合推荐结果"""
    __tablename__ = "ai_match_results"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)
    provider_user_uuid: Mapped[str] = mapped_column(String(36))
    rank: Mapped[int] = mapped_column(Integer)
    match_score: Mapped[float] = mapped_column(DECIMAL(6, 2))
    dimension_scores: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    recommendation_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    highlight_skills: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    match_type: Mapped[str] = mapped_column(String(50), default="recommend_providers")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        Index("idx_ai_match_project", "project_id", "created_at"),
    )


class AIPrdItem(Base):
    """AI PRD 需求条目（Feature Items）"""
    __tablename__ = "ai_prd_items"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)
    item_id: Mapped[str] = mapped_column(String(20))  # e.g. F-1.1
    module_name: Mapped[str] = mapped_column(String(100), default="")
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    priority: Mapped[str] = mapped_column(String(10), default="P1")  # P0/P1/P2
    acceptance_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("project_id", "item_id", "version", name="uq_ai_prd_item"),
    )


class AIEarsTask(Base):
    """AI EARS 原子任务卡片"""
    __tablename__ = "ai_ears_tasks"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)
    task_id: Mapped[str] = mapped_column(String(20))  # e.g. T-001
    feature_item_id: Mapped[str] = mapped_column(String(20))  # links to ai_prd_items.item_id
    ears_type: Mapped[str] = mapped_column(String(20))
    ears_statement: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    module: Mapped[str] = mapped_column(String(100), default="")
    role_tag: Mapped[str] = mapped_column(String(20), default="fullstack")
    priority: Mapped[int] = mapped_column(Integer, default=3)  # 1-5
    estimated_hours: Mapped[Optional[float]] = mapped_column(DECIMAL(6, 1), nullable=True)
    acceptance_criteria: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    dependencies: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    adjustment_count: Mapped[int] = mapped_column(Integer, default=0)
    version: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("project_id", "task_id", "version", name="uq_ai_ears_task"),
    )


class AIMilestone(Base):
    """AI 项目里程碑"""
    __tablename__ = "ai_milestones"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)
    milestone_index: Mapped[int] = mapped_column(Integer)
    title: Mapped[str] = mapped_column(String(200))
    duration_days: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    payment_ratio: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2), nullable=True)
    deliverables: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending/in_progress/delivered/accepted
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("project_id", "milestone_index", name="uq_ai_milestone"),
    )
