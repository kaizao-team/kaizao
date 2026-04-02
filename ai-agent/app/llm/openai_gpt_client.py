"""
开造 VibeBuild — OpenAI GPT 客户端（通过 Codex-for.me 代理）
使用 OpenAI 兼容 SDK，支持 GPT-5.4 等模型
返回与 Anthropic Message 格式兼容的对象（复用 zhipu_client 的转换层）
"""

import json
from typing import Any, Optional

import structlog
from openai import AsyncOpenAI

from app.config import settings

logger = structlog.get_logger()


class OpenAIGPTClient:
    """
    OpenAI GPT 异步客户端（通过 codex-for.me 代理访问）
    - 使用 AsyncOpenAI SDK
    - 支持 function calling (tool use)
    - 返回兼容 Anthropic Message 格式的对象
    """

    def __init__(self):
        if not settings.openai_api_key:
            logger.warning("OpenAI API Key 未配置，GPT 客户端不可用")
            self._client = None
            return

        self._client = AsyncOpenAI(
            api_key=settings.openai_api_key,
            base_url=settings.openai_base_url,
            timeout=settings.openai_timeout,
        )
        logger.info(
            "OpenAI GPT 客户端初始化完成",
            base_url=settings.openai_base_url,
            model=settings.openai_model,
        )

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
    ) -> Any:
        """
        调用 GPT API，返回兼容 Anthropic Message 格式的对象

        Args:
            messages: Anthropic 原生格式消息（自动转换为 OpenAI 格式）
            model: 模型名称，默认使用配置中的 openai_model
            max_tokens: 最大输出 token
            temperature: 温度
            system: System prompt
            tools: Anthropic 格式 tool 定义（自动转换为 OpenAI 格式）
        """
        if not self._client:
            raise RuntimeError("GPT 客户端未初始化")

        model = model or settings.openai_model

        # 转换消息格式：Anthropic → OpenAI
        openai_messages = self._convert_messages(messages, system)

        # 转换 tool 定义：Anthropic → OpenAI function calling
        openai_tools = self._convert_tools(tools) if tools else None

        kwargs: dict[str, Any] = {
            "model": model,
            "messages": openai_messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stream": True,
        }
        if openai_tools:
            kwargs["tools"] = openai_tools

        # codex-for.me 代理要求 stream=True，收集 chunk 后组装完整响应
        # 用 asyncio.wait_for 包裹整个 stream 过程，防止代理不可达时无限挂起
        import asyncio

        async def _stream_and_collect():
            stream = await self._client.chat.completions.create(**kwargs)
            content = ""
            tool_calls: dict[int, dict] = {}
            fin_reason = None

            async for chunk in stream:
                if not chunk.choices:
                    continue
                delta = chunk.choices[0].delta
                if chunk.choices[0].finish_reason:
                    fin_reason = chunk.choices[0].finish_reason
                if delta.content:
                    content += delta.content
                if delta.tool_calls:
                    for tc in delta.tool_calls:
                        idx = tc.index
                        if idx not in tool_calls:
                            tool_calls[idx] = {"id": tc.id or "", "name": "", "arguments": ""}
                        if tc.id:
                            tool_calls[idx]["id"] = tc.id
                        if tc.function:
                            if tc.function.name:
                                tool_calls[idx]["name"] = tc.function.name
                            if tc.function.arguments:
                                tool_calls[idx]["arguments"] += tc.function.arguments

            return content, tool_calls, fin_reason

        timeout = settings.openai_timeout
        collected_content, collected_tool_calls, finish_reason = await asyncio.wait_for(
            _stream_and_collect(), timeout=timeout,
        )

        logger.info(
            "openai_gpt_api_call",
            model=model,
            finish_reason=finish_reason or "N/A",
            content_len=len(collected_content),
            tool_calls=len(collected_tool_calls),
        )

        return self._build_response_from_stream(collected_content, collected_tool_calls, finish_reason)

    def _convert_messages(self, messages: list, system: Optional[str] = None) -> list:
        """将 Anthropic 格式消息转换为 OpenAI 格式"""
        result = []

        if system:
            result.append({"role": "system", "content": system})

        for msg in messages:
            role = msg.get("role", "user")
            content = msg.get("content", "")

            if isinstance(content, str):
                result.append({"role": role, "content": content})
            elif isinstance(content, list):
                for block in content:
                    if isinstance(block, dict):
                        if block.get("type") == "tool_result":
                            result.append({
                                "role": "tool",
                                "tool_call_id": block.get("tool_use_id", ""),
                                "content": block.get("content", ""),
                            })
                        elif block.get("type") == "text":
                            result.append({"role": role, "content": block.get("text", "")})
                        elif block.get("type") == "tool_use":
                            result.append({
                                "role": "assistant",
                                "content": None,
                                "tool_calls": [{
                                    "id": block.get("id", ""),
                                    "type": "function",
                                    "function": {
                                        "name": block.get("name", ""),
                                        "arguments": json.dumps(block.get("input", {}), ensure_ascii=False),
                                    },
                                }],
                            })
                    else:
                        result.append({"role": role, "content": str(block)})

        # 合并连续的同角色消息
        merged = []
        for msg in result:
            if merged and msg["role"] == merged[-1]["role"] and msg["role"] != "tool":
                if isinstance(merged[-1].get("content"), str) and isinstance(msg.get("content"), str):
                    merged[-1]["content"] += "\n" + msg["content"]
                    continue
            merged.append(msg)

        return merged

    def _convert_tools(self, anthropic_tools: list[dict]) -> list[dict]:
        """将 Anthropic tool 格式转换为 OpenAI function calling 格式"""
        result = []
        for tool in anthropic_tools:
            result.append({
                "type": "function",
                "function": {
                    "name": tool["name"],
                    "description": tool.get("description", ""),
                    "parameters": tool.get("input_schema", {"type": "object", "properties": {}}),
                },
            })
        return result

    def _build_response_from_stream(
        self, content: str, tool_calls: dict[int, dict], finish_reason: str | None
    ) -> Any:
        """将流式收集的结果组装为 Anthropic Message 兼容格式"""
        content_blocks = []

        if content:
            content_blocks.append(_FakeTextBlock(content))

        for _idx in sorted(tool_calls.keys()):
            tc = tool_calls[_idx]
            try:
                args = json.loads(tc["arguments"]) if tc["arguments"] else {}
            except json.JSONDecodeError:
                args = {"raw": tc["arguments"]}
            content_blocks.append(_FakeToolUseBlock(
                id=tc["id"],
                name=tc["name"],
                input=args,
            ))

        stop_reason = "end_turn"
        if finish_reason == "tool_calls":
            stop_reason = "tool_use"

        return _FakeMessage(content=content_blocks, stop_reason=stop_reason)


# ---- 兼容 Anthropic Message 格式的假对象 ----

class _FakeTextBlock:
    type = "text"
    def __init__(self, text: str):
        self.text = text


class _FakeToolUseBlock:
    type = "tool_use"
    def __init__(self, id: str, name: str, input: dict):
        self.id = id
        self.name = name
        self.input = input


class _FakeUsage:
    def __init__(self, usage=None):
        self.input_tokens = getattr(usage, 'prompt_tokens', 0) if usage else 0
        self.output_tokens = getattr(usage, 'completion_tokens', 0) if usage else 0


class _FakeMessage:
    def __init__(self, text: str = "", content=None, stop_reason="end_turn", usage=None):
        if content is not None:
            self.content = content
        else:
            self.content = [_FakeTextBlock(text)] if text else []
        self.stop_reason = stop_reason
        self.usage = _FakeUsage(usage)
        self.model = "gpt-5.4"
