"""
开造 VibeBuild — Redis 会话缓存
提供会话存储、读取、过期管理等操作
"""

import json
from typing import Any, Dict, Optional

import structlog

from app.config import settings

logger = structlog.get_logger()


class RedisStore:
    """
    Redis 存储客户端
    - 会话状态缓存（TTL=24小时）
    - Agent 中间结果缓存
    - 高频问答缓存
    """

    def __init__(self):
        self._client = None
        self._connected = False

    def connect(self):
        """连接到 Redis"""
        import redis

        self._client = redis.from_url(
            settings.redis_url,
            decode_responses=True,
            socket_timeout=2,
            socket_connect_timeout=2,
        )
        # 验证连接
        self._client.ping()
        self._connected = True
        logger.info("Redis 连接成功", url=settings.redis_url)

    def disconnect(self):
        """断开 Redis 连接"""
        if self._client:
            self._client.close()
            self._connected = False
            logger.info("Redis 连接已断开")

    def save_session(self, session_id: str, data: Dict[str, Any], ttl: Optional[int] = None) -> bool:
        """
        保存会话数据

        Args:
            session_id: 会话 ID
            data: 会话数据字典
            ttl: 过期时间（秒），默认使用配置中的 redis_session_ttl

        Returns:
            是否保存成功
        """
        if not self._client:
            logger.warning("Redis 未连接，无法保存会话")
            return False

        key = f"session:{session_id}"
        ttl = ttl or settings.redis_session_ttl

        try:
            serialized = json.dumps(data, ensure_ascii=False, default=str)
            self._client.setex(key, ttl, serialized)
            logger.info("session_saved", session_id=session_id, ttl=ttl)
            return True
        except Exception as e:
            logger.error("session_save_failed", session_id=session_id, error=str(e))
            return False

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """
        获取会话数据

        Args:
            session_id: 会话 ID

        Returns:
            会话数据字典，不存在则返回 None
        """
        if not self._client:
            logger.warning("Redis 未连接，无法读取会话")
            return None

        key = f"session:{session_id}"

        try:
            raw = self._client.get(key)
            if raw is None:
                return None
            return json.loads(raw)
        except Exception as e:
            logger.error("session_get_failed", session_id=session_id, error=str(e))
            return None

    def delete_session(self, session_id: str) -> bool:
        """
        删除会话数据

        Args:
            session_id: 会话 ID

        Returns:
            是否删除成功
        """
        if not self._client:
            return False

        key = f"session:{session_id}"
        try:
            self._client.delete(key)
            logger.info("session_deleted", session_id=session_id)
            return True
        except Exception as e:
            logger.error("session_delete_failed", session_id=session_id, error=str(e))
            return False

    def extend_session_ttl(self, session_id: str, ttl: Optional[int] = None) -> bool:
        """
        延长会话过期时间

        Args:
            session_id: 会话 ID
            ttl: 新的过期时间（秒）

        Returns:
            是否成功
        """
        if not self._client:
            return False

        key = f"session:{session_id}"
        ttl = ttl or settings.redis_session_ttl

        try:
            return bool(self._client.expire(key, ttl))
        except Exception as e:
            logger.error("session_ttl_extend_failed", session_id=session_id, error=str(e))
            return False

    def cache_set(self, key: str, value: Any, ttl: int = 300) -> bool:
        """
        设置通用缓存

        Args:
            key: 缓存键
            value: 缓存值（将被 JSON 序列化）
            ttl: 过期时间（秒），默认 5 分钟

        Returns:
            是否设置成功
        """
        if not self._client:
            return False

        cache_key = f"cache:{key}"
        try:
            serialized = json.dumps(value, ensure_ascii=False, default=str)
            self._client.setex(cache_key, ttl, serialized)
            return True
        except Exception as e:
            logger.error("cache_set_failed", key=key, error=str(e))
            return False

    def cache_get(self, key: str) -> Optional[Any]:
        """
        获取通用缓存

        Args:
            key: 缓存键

        Returns:
            缓存值，不存在则返回 None
        """
        if not self._client:
            return None

        cache_key = f"cache:{key}"
        try:
            raw = self._client.get(cache_key)
            if raw is None:
                return None
            return json.loads(raw)
        except Exception as e:
            logger.error("cache_get_failed", key=key, error=str(e))
            return None
