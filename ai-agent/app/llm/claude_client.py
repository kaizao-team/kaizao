"""
开造 VibeBuild — Anthropic Claude SDK 封装（v2 异步版）
使用 AsyncAnthropic + tool use，返回 Message 对象
"""

from typing import Any, Optional

import anthropic
import structlog

from app.config import settings

logger = structlog.get_logger()


class ClaudeClient:
    """
    Claude API 异步客户端
    - 使用 AsyncAnthropic 原生异步
    - 支持 tool use
    - 返回 Message 对象（非字符串）
    """

    def __init__(self):
        if not settings.anthropic_api_key:
            logger.warning("Anthropic API Key 未配置，Claude 客户端将不可用")
            self._client = None
            return

        self._client = anthropic.AsyncAnthropic(
            api_key=settings.anthropic_api_key,
            timeout=settings.claude_timeout,
        )
        logger.info("Claude 异步客户端初始化完成")

    @property
    def available(self) -> bool:
        return self._client is not None

    async def create_message(
        self,
        messages: list,
        model: Optional[str] = None,
        max_tokens: int = 4096,
        temperature: float = 0.3,
        system: Optional[str] = None,
        tools: Optional[list[dict]] = None,
    ) -> anthropic.types.Message:
        """
        调用 Claude API，返回原始 Message 对象（支持 tool use）

        Args:
            messages: Anthropic 原生格式消息列表（支持多 block）
            model: 模型名称
            max_tokens: 最大输出 token
            temperature: 温度参数
            system: System Prompt
            tools: Anthropic tool 定义列表

        Returns:
            anthropic.types.Message 对象
        """
        if not self._client:
            raise RuntimeError("Claude 客户端未初始化，请检查 API Key 配置")

        model = model or settings.claude_haiku_model

        kwargs: dict[str, Any] = {
            "model": model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": messages,
        }

        if system:
            kwargs["system"] = system
        if tools:
            kwargs["tools"] = tools

        response = await self._client.messages.create(**kwargs)

        logger.info(
            "claude_api_call",
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
            stop_reason=response.stop_reason,
        )

        return response

    async def generate(
        self,
        messages: list,
        model: Optional[str] = None,
        max_tokens: int = 4096,
        temperature: float = 0.3,
        system: Optional[str] = None,
    ) -> str:
        """
        兼容旧版接口：返回纯文本字符串
        """
        # 从消息列表中分离 system prompt
        system_parts = []
        chat_messages = []
        for msg in messages:
            if msg["role"] == "system":
                system_parts.append(msg["content"])
            else:
                chat_messages.append({"role": msg["role"], "content": msg["content"]})

        final_system = system or "\n\n".join(system_parts)
        if not final_system:
            final_system = "You are a helpful assistant."

        if not chat_messages:
            chat_messages = [{"role": "user", "content": "请按照系统提示执行任务。"}]

        cleaned = self._clean_messages(chat_messages)

        response = await self.create_message(
            messages=cleaned,
            model=model,
            max_tokens=max_tokens,
            temperature=temperature,
            system=final_system,
        )

        return "".join(
            block.text for block in response.content if hasattr(block, "text")
        )

    @staticmethod
    def _clean_messages(messages: list) -> list:
        """确保消息列表符合 Claude API 要求"""
        if not messages:
            return [{"role": "user", "content": "Hello."}]

        cleaned = []
        for msg in messages:
            if not cleaned:
                if msg["role"] != "user":
                    cleaned.append({"role": "user", "content": "（对话开始）"})
                cleaned.append(msg)
            else:
                if msg["role"] == cleaned[-1]["role"]:
                    cleaned[-1]["content"] += "\n" + msg["content"]
                else:
                    cleaned.append(msg)

        if cleaned[-1]["role"] != "user":
            cleaned.append({"role": "user", "content": "请继续。"})

        return cleaned
