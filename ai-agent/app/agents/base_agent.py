"""
开造 VibeBuild — Agent 基类
提供统一的调用接口、错误处理、重试逻辑、日志记录
"""

import time
import uuid
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

import structlog
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
)

from app.config import settings
from app.llm.router import LLMRouter

logger = structlog.get_logger()


class AgentError(Exception):
    """Agent 统一异常"""

    def __init__(self, message: str, error_code: int = 50000, details: Optional[Dict] = None):
        super().__init__(message)
        self.error_code = error_code
        self.details = details or {}


class BaseAgent(ABC):
    """
    Agent 基类
    所有 Agent 继承此基类，实现 _execute 方法即可。
    基类统一处理：日志埋点、耗时统计、错误处理、重试逻辑。
    """

    def __init__(self, agent_name: str, llm_router: LLMRouter):
        self.agent_name = agent_name
        self.llm_router = llm_router
        self.logger = structlog.get_logger().bind(agent=agent_name)

    async def process(self, **kwargs) -> Dict[str, Any]:
        """
        Agent 统一入口：包装 _execute 方法，增加日志和耗时统计
        """
        request_id = str(uuid.uuid4())[:16]
        start_time = time.time()

        self.logger.info(
            "agent_process_start",
            request_id=request_id,
            params={k: str(v)[:200] for k, v in kwargs.items()},
        )

        try:
            result = await self._execute(request_id=request_id, **kwargs)
            duration_ms = round((time.time() - start_time) * 1000, 2)

            self.logger.info(
                "agent_process_success",
                request_id=request_id,
                duration_ms=duration_ms,
            )
            return result

        except AgentError:
            raise
        except Exception as e:
            duration_ms = round((time.time() - start_time) * 1000, 2)
            self.logger.error(
                "agent_process_error",
                request_id=request_id,
                error=str(e),
                duration_ms=duration_ms,
            )
            raise AgentError(
                message=f"{self.agent_name} 处理失败: {str(e)}",
                error_code=50000,
                details={"original_error": str(e)},
            )

    @abstractmethod
    async def _execute(self, request_id: str, **kwargs) -> Dict[str, Any]:
        """
        子类实现具体的 Agent 逻辑
        """
        raise NotImplementedError

    @retry(
        stop=stop_after_attempt(2),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        retry=retry_if_exception_type((TimeoutError, ConnectionError)),
        reraise=True,
    )
    async def call_llm(
        self,
        messages: list,
        model_tier: str = "default",
        max_tokens: int = 4096,
        temperature: float = 0.3,
        response_format: Optional[str] = None,
    ) -> str:
        """
        调用 LLM 的统一方法，内置重试和降级逻辑

        Args:
            messages: 消息列表，格式为 [{"role": "system", "content": "..."}]
            model_tier: 模型级别 "high" / "default" / "low"
            max_tokens: 最大输出 token 数
            temperature: 温度参数
            response_format: 响应格式 "json" / None

        Returns:
            LLM 输出的文本内容
        """
        start_time = time.time()

        try:
            result = await self.llm_router.generate(
                messages=messages,
                model_tier=model_tier,
                max_tokens=max_tokens,
                temperature=temperature,
                response_format=response_format,
            )

            duration_ms = round((time.time() - start_time) * 1000, 2)
            self.logger.info(
                "llm_call_success",
                model_tier=model_tier,
                duration_ms=duration_ms,
                output_length=len(result),
            )
            return result

        except Exception as e:
            duration_ms = round((time.time() - start_time) * 1000, 2)
            self.logger.error(
                "llm_call_error",
                model_tier=model_tier,
                duration_ms=duration_ms,
                error=str(e),
            )
            raise

    def _build_messages(
        self,
        system_prompt: str,
        user_message: str,
        conversation_history: Optional[list] = None,
        injected_context: Optional[str] = None,
    ) -> list:
        """
        构建发送给 LLM 的消息列表

        Args:
            system_prompt: System Prompt 文本
            user_message: 当前用户消息
            conversation_history: 历史对话列表
            injected_context: 注入的额外上下文（RAG 检索结果等）

        Returns:
            格式化的消息列表
        """
        messages = [{"role": "system", "content": system_prompt}]

        # 注入额外上下文（RAG 检索结果、用户实体信息等）
        if injected_context:
            messages.append({"role": "system", "content": injected_context})

        # 注入历史对话
        if conversation_history:
            for turn in conversation_history:
                messages.append({"role": "user", "content": turn.get("user_message", "")})
                messages.append({"role": "assistant", "content": turn.get("assistant_message", "")})

        # 当前用户消息
        messages.append({"role": "user", "content": user_message})

        return messages

    @staticmethod
    def _estimate_tokens(text: str) -> int:
        """粗略估算文本 token 数（中文约 1.5 字/token）"""
        return int(len(text) / 1.5)
