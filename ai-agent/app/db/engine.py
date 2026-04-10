"""
开造 VibeBuild — 异步 MySQL 引擎
AsyncEngine + async_session 工厂
"""

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import settings

# 异步引擎（延迟创建，由 init_db() 初始化）
_engine = None
_async_session_factory = None


def get_engine():
    """获取全局 AsyncEngine（必须先调用 init_db）"""
    if _engine is None:
        raise RuntimeError("数据库尚未初始化，请先调用 init_db()")
    return _engine


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    """获取 async_session 工厂"""
    if _async_session_factory is None:
        raise RuntimeError("数据库尚未初始化，请先调用 init_db()")
    return _async_session_factory


async def init_db(auto_create_tables: bool = False):
    """
    初始化数据库引擎和 session 工厂

    Args:
        auto_create_tables: 开发模式下自动建表
    """
    global _engine, _async_session_factory

    _engine = create_async_engine(
        settings.mysql_url,
        echo=settings.debug,
        pool_size=10,
        max_overflow=20,
        pool_recycle=3600,
        pool_pre_ping=True,
    )

    _async_session_factory = async_sessionmaker(
        _engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    if auto_create_tables:
        from app.db.models import (
            AIProjectStage, AIDocument, AIConversationMessage,
            AIProviderProfile, AIVibePowerLog,
            AIMatchResult, AIPrdItem, AIProjectOverview,
        )
        # 只建 AI 独有表，不动 Go 后端的 projects/tasks/milestones 表
        ai_tables = [
            AIProjectStage.__table__,
            AIDocument.__table__,
            AIConversationMessage.__table__,
            AIProviderProfile.__table__,
            AIVibePowerLog.__table__,
            AIMatchResult.__table__,
            AIPrdItem.__table__,
            AIProjectOverview.__table__,
        ]
        from app.db.models import Base
        async with _engine.begin() as conn:
            await conn.run_sync(
                lambda sync_conn: Base.metadata.create_all(sync_conn, tables=ai_tables)
            )


async def close_db():
    """关闭数据库引擎"""
    global _engine, _async_session_factory
    if _engine:
        await _engine.dispose()
        _engine = None
        _async_session_factory = None
