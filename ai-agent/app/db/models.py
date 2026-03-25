"""
开造 VibeBuild — ORM 模型定义
4 张表：projects / project_stages / documents / conversation_messages
"""

from datetime import datetime
from typing import Optional

from sqlalchemy import (
    BigInteger,
    DateTime,
    DECIMAL,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.mysql import JSON
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Project(Base):
    """项目主表"""
    __tablename__ = "projects"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    title: Mapped[str] = mapped_column(String(255), default="")
    current_stage: Mapped[str] = mapped_column(String(20), default="requirement")
    version: Mapped[int] = mapped_column(Integer, default=1)
    session_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )


class ProjectStage(Base):
    """阶段状态表"""
    __tablename__ = "project_stages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)
    stage_name: Mapped[str] = mapped_column(String(20))
    status: Mapped[str] = mapped_column(String(30), default="pending")
    sub_stage: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    document_path: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    __table_args__ = (
        UniqueConstraint("project_id", "stage_name", name="uq_project_stage"),
    )


class Document(Base):
    """文档记录表"""
    __tablename__ = "documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    project_id: Mapped[str] = mapped_column(String(36), index=True)
    stage: Mapped[str] = mapped_column(String(20))
    filename: Mapped[str] = mapped_column(String(128))
    file_path: Mapped[str] = mapped_column(String(512))
    version: Mapped[int] = mapped_column(Integer, default=1)
    size_bytes: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("project_id", "filename", "version", name="uq_doc_version"),
    )


class ConversationMessage(Base):
    """对话消息表"""
    __tablename__ = "conversation_messages"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    session_id: Mapped[str] = mapped_column(String(64))
    project_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    role: Mapped[str] = mapped_column(String(20))
    content: Mapped[str] = mapped_column(Text)
    message_index: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        Index("idx_session", "session_id", "message_index"),
    )


class ProviderProfile(Base):
    """供给方档案表"""
    __tablename__ = "provider_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    type: Mapped[str] = mapped_column(String(10), default="individual")
    display_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    vibe_power: Mapped[int] = mapped_column(Integer, default=0)
    vibe_level: Mapped[str] = mapped_column(String(20), default="vc-T1")
    level_weight: Mapped[float] = mapped_column(DECIMAL(3, 2), default=1.00)
    # 评审标签 JSON（学历层次、大厂经历、工作年限等定级凭证）
    review_tags: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    # AI 解析结构化数据
    skills: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    experience_years: Mapped[int] = mapped_column(Integer, default=0)
    ai_tools: Mapped[Optional[str]] = mapped_column(JSON, nullable=True)
    resume_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    # 五维度初始评分
    score_tech_depth: Mapped[int] = mapped_column(Integer, default=0)
    score_project_exp: Mapped[int] = mapped_column(Integer, default=0)
    score_ai_proficiency: Mapped[int] = mapped_column(Integer, default=0)
    score_portfolio: Mapped[int] = mapped_column(Integer, default=0)
    score_background: Mapped[int] = mapped_column(Integer, default=0)
    # 统计数据
    total_projects: Mapped[int] = mapped_column(Integer, default=0)
    completed_projects: Mapped[int] = mapped_column(Integer, default=0)
    avg_rating: Mapped[float] = mapped_column(DECIMAL(3, 2), default=0)
    on_time_rate: Mapped[float] = mapped_column(DECIMAL(5, 2), default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (
        Index("idx_user", "user_id"),
        Index("idx_level", "vibe_level", "vibe_power"),
    )


class VibePowerLog(Base):
    """积分变动记录表"""
    __tablename__ = "vibe_power_logs"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    provider_id: Mapped[str] = mapped_column(String(36), nullable=False)
    action: Mapped[str] = mapped_column(String(50))
    points: Mapped[int] = mapped_column(Integer)
    reason: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    project_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        Index("idx_provider", "provider_id", "created_at"),
    )
