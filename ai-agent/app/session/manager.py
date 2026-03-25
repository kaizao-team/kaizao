"""
开造 VibeBuild — 异步会话管理（Redis 缓存 + MySQL 持久化）
写入时双写 Redis + MySQL；读取时先查 Redis，miss 则查 MySQL 并回填 Redis
"""

import json
from typing import Any, Optional

import structlog

from app.config import settings

logger = structlog.get_logger()

# Key TTL 常量
PROJECT_STATE_TTL = 7 * 24 * 3600   # 7 天
SESSION_HISTORY_TTL = 24 * 3600      # 24 小时


def _get_repo():
    """延迟获取 Repository，避免循环导入和未初始化问题"""
    try:
        from app.db.repository import ProjectRepository
        return ProjectRepository()
    except Exception:
        return None


class SessionManager:
    """
    异步会话管理器（Redis 缓存 + MySQL 持久化）
    - project:{id}:state  → ProjectState JSON（Redis 缓存 7天 TTL + MySQL 持久化）
    - session:{id}:history → 对话历史（Redis 缓存 24h TTL + MySQL 持久化）
    """

    def __init__(self):
        self._redis = None
        self._memory_store = {}  # 内存回退

    async def connect(self):
        try:
            import redis.asyncio as aioredis
            self._redis = aioredis.from_url(
                settings.redis_url,
                decode_responses=True,
                socket_timeout=3,
                socket_connect_timeout=3,
            )
            await self._redis.ping()
            logger.info("异步 Redis 会话管理器连接成功")
        except Exception as e:
            logger.warning(f"Redis 连接失败，使用内存存储: {e}")
            self._redis = None

    async def disconnect(self):
        if self._redis:
            await self._redis.aclose()
            logger.info("异步 Redis 会话管理器已断开")

    # ---- 项目状态 ----

    async def save_project_state(self, project_id: str, state: dict) -> None:
        """双写：Redis 缓存 + MySQL 持久化"""
        key = f"project:{project_id}:state"
        data = json.dumps(state, ensure_ascii=False, default=str)

        # 写 Redis 缓存
        if self._redis:
            await self._redis.setex(key, PROJECT_STATE_TTL, data)
        else:
            self._memory_store[key] = data

        # 写 MySQL 持久化
        repo = _get_repo()
        if repo:
            try:
                await repo.save_project(project_id, state)
            except Exception as e:
                logger.warning(f"MySQL 写入项目状态失败（缓存已写入）: {e}")

    async def get_project_state(self, project_id: str) -> Optional[dict]:
        """先查 Redis，miss 则查 MySQL 并回填 Redis"""
        key = f"project:{project_id}:state"

        # 先查 Redis
        if self._redis:
            raw = await self._redis.get(key)
        else:
            raw = self._memory_store.get(key)

        if raw:
            return json.loads(raw)

        # Redis miss → 查 MySQL
        repo = _get_repo()
        if repo:
            try:
                state = await repo.get_project(project_id)
                if state:
                    # 回填 Redis
                    data = json.dumps(state, ensure_ascii=False, default=str)
                    if self._redis:
                        await self._redis.setex(key, PROJECT_STATE_TTL, data)
                    else:
                        self._memory_store[key] = data
                    logger.info("project_state_restored_from_mysql", project_id=project_id)
                    return state
            except Exception as e:
                logger.warning(f"MySQL 读取项目状态失败: {e}")

        return None

    async def delete_project_state(self, project_id: str) -> None:
        key = f"project:{project_id}:state"
        if self._redis:
            await self._redis.delete(key)
        else:
            self._memory_store.pop(key, None)

        repo = _get_repo()
        if repo:
            try:
                await repo.delete_project(project_id)
            except Exception as e:
                logger.warning(f"MySQL 删除项目状态失败: {e}")

    # ---- 对话历史 ----

    async def save_history(self, session_id: str, messages: list[dict], project_id: Optional[str] = None) -> None:
        """双写：Redis 缓存 + MySQL 持久化"""
        key = f"session:{session_id}:history"
        data = json.dumps(messages, ensure_ascii=False, default=str)

        if self._redis:
            await self._redis.setex(key, SESSION_HISTORY_TTL, data)
        else:
            self._memory_store[key] = data

        # 写 MySQL
        repo = _get_repo()
        if repo:
            try:
                await repo.save_messages(session_id, messages, project_id=project_id)
            except Exception as e:
                logger.warning(f"MySQL 写入对话历史失败: {e}")

    async def get_history(self, session_id: str) -> list[dict]:
        """先查 Redis，miss 则查 MySQL 并回填"""
        key = f"session:{session_id}:history"

        if self._redis:
            raw = await self._redis.get(key)
        else:
            raw = self._memory_store.get(key)

        if raw:
            return json.loads(raw)

        # Redis miss → 查 MySQL
        repo = _get_repo()
        if repo:
            try:
                messages = await repo.get_messages(session_id)
                if messages:
                    data = json.dumps(messages, ensure_ascii=False, default=str)
                    if self._redis:
                        await self._redis.setex(key, SESSION_HISTORY_TTL, data)
                    else:
                        self._memory_store[key] = data
                    logger.info("history_restored_from_mysql", session_id=session_id)
                    return messages
            except Exception as e:
                logger.warning(f"MySQL 读取对话历史失败: {e}")

        return []

    async def append_to_history(self, session_id: str, new_messages: list[dict]) -> list[dict]:
        """追加消息到历史并返回完整历史"""
        history = await self.get_history(session_id)
        history.extend(new_messages)
        await self.save_history(session_id, history)
        return history

    async def delete_history(self, session_id: str) -> None:
        key = f"session:{session_id}:history"
        if self._redis:
            await self._redis.delete(key)
        else:
            self._memory_store.pop(key, None)

    # ---- 通用 KV ----

    async def set(self, key: str, value: Any, ttl: int = 3600) -> None:
        data = json.dumps(value, ensure_ascii=False, default=str)
        if self._redis:
            await self._redis.setex(key, ttl, data)
        else:
            self._memory_store[key] = data

    async def get(self, key: str) -> Optional[Any]:
        if self._redis:
            raw = await self._redis.get(key)
        else:
            raw = self._memory_store.get(key)
        return json.loads(raw) if raw else None
