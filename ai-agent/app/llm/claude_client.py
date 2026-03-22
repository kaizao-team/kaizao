"""
开造 VibeBuild — Anthropic Claude SDK 封装
提供统一的 Claude API 调用接口，支持超时控制
"""

import asyncio
from typing import Optional

import anthropic
import structlog

from app.config import settings

logger = structlog.get_logger()


class ClaudeClient:
    """
    Claude API 客户端封装
    - 使用 Anthropic 官方 SDK
    - 支持同步/异步调用
    - 内置超时控制
    """

    def __init__(self):
        if not settings.anthropic_api_key:
            logger.warning("Anthropic API Key 未配置，Claude 客户端将不可用")
            self._client = None
            return

        self._client = anthropic.Anthropic(
            api_key=settings.anthropic_api_key,
            timeout=settings.claude_timeout,
        )
        logger.info("Claude 客户端初始化完成")

    async def generate(
        self,
        messages: list,
        model: Optional[str] = None,
        max_tokens: int = 4096,
        temperature: float = 0.3,
        system: Optional[str] = None,
    ) -> str:
        """
        调用 Claude API 生成文本

        Args:
            messages: 消息列表，格式为 [{"role": "user/assistant/system", "content": "..."}]
            model: 模型名称，默认使用配置中的 Haiku 模型
            max_tokens: 最大输出 token 数
            temperature: 温度参数
            system: System Prompt（如果 messages 中包含 system 消息则自动提取）

        Returns:
            模型生成的文本内容
        """
        if not self._client:
            raise RuntimeError("Claude 客户端未初始化，请检查 API Key 配置")

        model = model or settings.claude_haiku_model

        # 从消息列表中分离 system prompt 和对话消息
        system_parts = []
        chat_messages = []
        for msg in messages:
            if msg["role"] == "system":
                system_parts.append(msg["content"])
            else:
                chat_messages.append({"role": msg["role"], "content": msg["content"]})

        # 合�� system prompt
        final_system = system or "\n\n".join(system_parts)

        # 确保消息列表不为空，且第一条消息是 user
        if not chat_messages:
            chat_messages = [{"role": "user", "content": "请按照系统提示执行任务。"}]

        # 确保消息列表中 user/assistant 交替出现
        cleaned_messages = self._clean_messages(chat_messages)

        # 在独立线程中执行同步 API 调用
        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(
            None,
            lambda: self._client.messages.create(
                model=model,
                max_tokens=max_tokens,
                temperature=temperature,
                system=final_system if final_system else "You are a helpful assistant.",
                messages=cleaned_messages,
            ),
        )

        # 提取文本内容
        result_text = ""
        for block in response.content:
            if hasattr(block, "text"):
                result_text += block.text

        logger.info(
            "claude_api_call",
            model=model,
            input_tokens=response.usage.input_tokens,
            output_tokens=response.usage.output_tokens,
        )

        return result_text

    @staticmethod
    def _clean_messages(messages: list) -> list:
        """
        清理消息列表，确保符合 Claude API 要求：
        1. 第一条消息必须是 user
        2. user 和 assistant 必须交替出现
        3. 合并连续的同角色消息
        """
        if not messages:
            return [{"role": "user", "content": "Hello."}]

        cleaned = []
        for msg in messages:
            if not cleaned:
                # 确保第一条是 user
                if msg["role"] != "user":
                    cleaned.append({"role": "user", "content": "（对话开始）"})
                cleaned.append(msg)
            else:
                # 如果和上一条角色相同，合并内容
                if msg["role"] == cleaned[-1]["role"]:
                    cleaned[-1]["content"] += "\n" + msg["content"]
                else:
                    cleaned.append(msg)

        # 确保最后一条是 user（Claude API 要求）
        if cleaned[-1]["role"] != "user":
            cleaned.append({"role": "user", "content": "请继续。"})

        return cleaned
