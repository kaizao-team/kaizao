"""
开造 VibeBuild — LLM 模型路由（v2 异步版）
降级链：GPT-5.4 → 智谱 GLM → 通义千问
"""

from typing import Any, Optional

import structlog

from app.config import settings
from app.llm.claude_client import ClaudeClient

logger = structlog.get_logger()


class LLMRouter:
    """
    LLM 模型路由器
    - 按 model_tier 选择合适的模型
    - create_message() 返回 Message 对象（支持 tool use）
    - generate() 返回字符串（兼容旧接口）
    - 降级链：GPT-5.4 → 智谱 GLM → 通义千问
    """

    def __init__(self):
        self.claude_client = ClaudeClient()
        self._openai_gpt_client = None
        self._zhipu_client = None
        self._dashscope_available = bool(settings.dashscope_api_key)

        # 初始化 GPT-5.4 客户端（主力）
        if settings.openai_api_key:
            try:
                from app.llm.openai_gpt_client import OpenAIGPTClient
                self._openai_gpt_client = OpenAIGPTClient()
            except Exception as e:
                logger.warning(f"GPT 客户端初始化失败: {e}")

        # 初始化智谱客户端（降级）
        if settings.zhipu_api_key:
            try:
                from app.llm.zhipu_client import ZhipuClient
                self._zhipu_client = ZhipuClient()
            except Exception as e:
                logger.warning(f"智谱客户端初始化失败: {e}")

        logger.info(
            "LLMRouter 初始化完成",
            gpt_available=self._openai_gpt_client is not None and self._openai_gpt_client.available,
            claude_available=self.claude_client.available,
            zhipu_available=self._zhipu_client is not None and self._zhipu_client.available,
            dashscope_available=self._dashscope_available,
        )

    def _resolve_model(self, model_tier: str) -> str:
        if model_tier == "high":
            return settings.claude_sonnet_model
        return settings.claude_haiku_model

    async def create_message(
        self,
        messages: list,
        model_tier: str = "default",
        max_tokens: int = 4096,
        temperature: float = 0.3,
        system: Optional[str] = None,
        tools: Optional[list[dict]] = None,
    ) -> Any:
        """
        返回 Message 对象（支持 tool use）

        降级链：GPT-5.4 → 智谱 GLM → 通义千问
        """
        # 主力：GPT-5.4
        if self._openai_gpt_client and self._openai_gpt_client.available:
            try:
                return await self._openai_gpt_client.create_message(
                    messages=messages,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system=system,
                    tools=tools,
                )
            except Exception as e:
                logger.warning("GPT-5.4 调用失败，尝试降级到智谱 GLM", error=str(e))

        # 降级1：智谱 GLM（原生支持 tool use）
        if self._zhipu_client and self._zhipu_client.available:
            try:
                return await self._zhipu_client.create_message(
                    messages=messages,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system=system,
                    tools=tools,
                )
            except Exception as e:
                logger.warning("智谱 GLM 调用失败，尝试降级到 Qwen", error=str(e))

        # 降级2：Claude（如果有 key）
        if self.claude_client.available:
            model = self._resolve_model(model_tier)
            try:
                return await self.claude_client.create_message(
                    messages=messages,
                    model=model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system=system,
                    tools=tools,
                )
            except Exception as e:
                logger.warning("Claude 调用失败，尝试降级到 Qwen", error=str(e))

        # 降级3：通义千问（tools 嵌入 system prompt）
        if self._dashscope_available:
            fallback_model = (
                settings.qwen_max_model if model_tier == "high" else settings.qwen_turbo_model
            )
            fallback_system = system or ""
            if tools:
                import json
                fallback_system += "\n\n[可用工具定义（请在回复中模拟 tool_use 格式）]:\n"
                for t in tools:
                    fallback_system += f"- {t.get('name', 'unknown')}: {json.dumps(t, ensure_ascii=False)}\n"

            try:
                text = await self._call_dashscope(
                    messages=messages,
                    model=fallback_model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system_override=fallback_system if fallback_system else None,
                )
                return self._text_to_fake_message(text)
            except Exception as e:
                logger.error("Qwen 降级也失败", model=fallback_model, error=str(e))
                raise

        raise RuntimeError("所有 LLM 提供商均不可用，请检查 API 配置")

    async def generate(
        self,
        messages: list,
        model_tier: str = "default",
        max_tokens: int = 4096,
        temperature: float = 0.3,
        response_format: Optional[str] = None,
    ) -> str:
        """兼容旧版：返回纯文本字符串"""
        # 主力：GPT-5.4
        if self._openai_gpt_client and self._openai_gpt_client.available:
            try:
                resp = await self._openai_gpt_client.create_message(
                    messages=messages,
                    max_tokens=max_tokens,
                    temperature=temperature,
                )
                return "".join(b.text for b in resp.content if hasattr(b, "text"))
            except Exception as e:
                logger.warning("GPT-5.4 调用失败，尝试降级", error=str(e))

        # 降级1：智谱 GLM
        if self._zhipu_client and self._zhipu_client.available:
            try:
                resp = await self._zhipu_client.create_message(
                    messages=messages,
                    max_tokens=max_tokens,
                    temperature=temperature,
                )
                return "".join(b.text for b in resp.content if hasattr(b, "text"))
            except Exception as e:
                logger.warning("智谱 GLM 调用失败", error=str(e))

        # 降级2：Claude
        if self.claude_client.available:
            model = self._resolve_model(model_tier)
            try:
                return await self.claude_client.generate(
                    messages=messages,
                    model=model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                )
            except Exception as e:
                logger.warning("Claude 调用失败", error=str(e))

        # 降级3：通义千问
        if self._dashscope_available:
            fallback_model = (
                settings.qwen_max_model if model_tier == "high" else settings.qwen_turbo_model
            )
            try:
                return await self._call_dashscope(
                    messages=messages, model=fallback_model,
                    max_tokens=max_tokens, temperature=temperature,
                )
            except Exception as e:
                logger.error("Qwen 降级也失败", error=str(e))
                raise

        raise RuntimeError("所有 LLM 提供商均不可用，请检查 API 配置")

    async def _call_dashscope(
        self,
        messages: list,
        model: str,
        max_tokens: int = 4096,
        temperature: float = 0.3,
        system_override: Optional[str] = None,
    ) -> str:
        import asyncio
        import dashscope
        from dashscope import Generation

        dashscope.api_key = settings.dashscope_api_key

        ds_messages = []
        for msg in messages:
            role = msg["role"]
            content = msg["content"] if isinstance(msg["content"], str) else str(msg["content"])
            if role == "system" and ds_messages and ds_messages[-1]["role"] == "system":
                ds_messages[-1]["content"] += "\n\n" + content
            else:
                ds_messages.append({"role": role, "content": content})

        if system_override:
            if ds_messages and ds_messages[0]["role"] == "system":
                ds_messages[0]["content"] = system_override + "\n\n" + ds_messages[0]["content"]
            else:
                ds_messages.insert(0, {"role": "system", "content": system_override})

        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(
            None,
            lambda: Generation.call(
                model=model,
                messages=ds_messages,
                max_tokens=max_tokens,
                temperature=temperature,
                result_format="message",
            ),
        )

        if response.status_code != 200:
            raise RuntimeError(
                f"DashScope API 错误: status={response.status_code}, "
                f"code={response.code}, message={response.message}"
            )

        return response.output.choices[0].message.content

    @staticmethod
    def _text_to_fake_message(text: str) -> Any:
        """将纯文本包装为类 Message 对象"""

        class _FakeUsage:
            input_tokens = 0
            output_tokens = 0

        class _FakeTextBlock:
            type = "text"
            def __init__(self, t: str):
                self.text = t

        class _FakeMessage:
            def __init__(self, t: str):
                self.content = [_FakeTextBlock(t)]
                self.stop_reason = "end_turn"
                self.usage = _FakeUsage()
                self.model = "qwen-fallback"

        return _FakeMessage(text)
