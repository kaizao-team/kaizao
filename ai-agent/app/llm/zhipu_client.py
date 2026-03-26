"""
开造 VibeBuild — 智谱 GLM 客户端
使用 OpenAI 兼容 SDK 连接智谱 API，支持 tool use
返回与 Anthropic Message 格式兼容的对象
"""

import json
from typing import Any, Optional

import structlog
from openai import AsyncOpenAI

from app.config import settings

logger = structlog.get_logger()


class ZhipuClient:
    """
    智谱 GLM 异步客户端
    - 使用 OpenAI 兼容 API
    - 支持 function calling (tool use)
    - 返回兼容 Anthropic Message 格式的对象
    """

    def __init__(self):
        if not settings.zhipu_api_key:
            logger.warning("智谱 API Key 未配置")
            self._client = None
            return

        self._client = AsyncOpenAI(
            api_key=settings.zhipu_api_key,
            base_url="https://open.bigmodel.cn/api/paas/v4/",
        )
        logger.info("智谱 GLM 客户端初始化完成")

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
        调用智谱 API，返回兼容 Anthropic Message 格式的对象

        Args:
            messages: Anthropic 原生格式消息（需转换为 OpenAI 格式）
            model: 模型名称
            max_tokens: 最大输出 token
            temperature: 温度
            system: System prompt
            tools: Anthropic 格式 tool 定义（需转换为 OpenAI 格式）
        """
        if not self._client:
            raise RuntimeError("智谱客户端未初始化")

        model = model or settings.zhipu_model

        # 转换消息格式：Anthropic → OpenAI
        openai_messages = self._convert_messages(messages, system)

        # 转换 tool 定义：Anthropic → OpenAI function calling
        openai_tools = self._convert_tools(tools) if tools else None

        kwargs: dict[str, Any] = {
            "model": model,
            "messages": openai_messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        if openai_tools:
            kwargs["tools"] = openai_tools

        response = await self._client.chat.completions.create(**kwargs)

        logger.info(
            "zhipu_api_call",
            model=model,
            usage=str(response.usage) if response.usage else "N/A",
            finish_reason=response.choices[0].finish_reason if response.choices else "N/A",
        )

        # 转换响应：OpenAI → Anthropic Message 格式
        return self._convert_response(response)

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
                # 处理多 block 消息（tool_result 等）
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
                            # assistant 的 tool_use 需要特殊处理
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

    def _convert_response(self, response) -> Any:
        """将 OpenAI 响应转换为 Anthropic Message 兼容格式"""
        choice = response.choices[0] if response.choices else None
        if not choice:
            return _FakeMessage(text="", stop_reason="end_turn", usage=response.usage)

        message = choice.message
        content_blocks = []

        # 文本内容
        if message.content:
            content_blocks.append(_FakeTextBlock(message.content))

        # Tool calls
        if message.tool_calls:
            for tc in message.tool_calls:
                try:
                    args = json.loads(tc.function.arguments) if tc.function.arguments else {}
                except json.JSONDecodeError:
                    args = {"raw": tc.function.arguments}
                content_blocks.append(_FakeToolUseBlock(
                    id=tc.id,
                    name=tc.function.name,
                    input=args,
                ))

        stop_reason = "end_turn"
        if choice.finish_reason == "tool_calls":
            stop_reason = "tool_use"

        return _FakeMessage(
            content=content_blocks,
            stop_reason=stop_reason,
            usage=response.usage,
        )


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
        self.model = "glm-5"
