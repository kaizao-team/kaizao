"""
开造 VibeBuild — LLM 模型路由
支持 Claude -> 通义千问自动降级，按任务复杂度选择模型
"""

import structlog
from typing import Optional

from app.config import settings
from app.llm.claude_client import ClaudeClient

logger = structlog.get_logger()


class LLMRouter:
    """
    LLM 模型路由器
    - 按 model_tier 选择合适的模型
    - Claude API 异常时自动降级到通义千问
    - 统一调用接口
    """

    def __init__(self):
        self.claude_client = ClaudeClient()
        self._dashscope_available = bool(settings.dashscope_api_key)
        logger.info(
            "LLMRouter 初始化完成",
            claude_available=bool(settings.anthropic_api_key),
            dashscope_available=self._dashscope_available,
        )

    async def generate(
        self,
        messages: list,
        model_tier: str = "default",
        max_tokens: int = 4096,
        temperature: float = 0.3,
        response_format: Optional[str] = None,
    ) -> str:
        """
        统一生成接口

        Args:
            messages: 消息列表
            model_tier: 模型级别
                - "high": 复杂任务（PRD 生成、EARS 拆解）-> Claude Sonnet
                - "default": 普通任务（对话、推荐理由）-> Claude Haiku
                - "low": 简单任务（意图识别、摘要）-> 通义千问 Turbo
            max_tokens: 最大输出 token 数
            temperature: 温度参数
            response_format: 响应格式

        Returns:
            模型输出文本
        """
        # 低级别任务优先使用通义千问降本
        if model_tier == "low" and self._dashscope_available:
            try:
                return await self._call_dashscope(
                    messages=messages,
                    model=settings.qwen_turbo_model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                )
            except Exception as e:
                logger.warning("通义千问 Turbo 调用失败，回退到 Claude Haiku", error=str(e))

        # 选择 Claude 模型
        if model_tier == "high":
            model = settings.claude_sonnet_model
        else:
            model = settings.claude_haiku_model

        # 尝试 Claude
        try:
            return await self.claude_client.generate(
                messages=messages,
                model=model,
                max_tokens=max_tokens,
                temperature=temperature,
            )
        except Exception as e:
            logger.warning(
                "Claude API 调用失败，尝试降级到通义千问",
                model=model,
                error=str(e),
            )

        # 降级到通义千问
        if self._dashscope_available:
            fallback_model = (
                settings.qwen_max_model if model_tier == "high" else settings.qwen_turbo_model
            )
            try:
                return await self._call_dashscope(
                    messages=messages,
                    model=fallback_model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                )
            except Exception as e:
                logger.error("通义千问降级调用也失败", model=fallback_model, error=str(e))
                raise

        raise RuntimeError("所有 LLM 提供商均不可用，请检查 API 配置")

    async def _call_dashscope(
        self,
        messages: list,
        model: str,
        max_tokens: int = 4096,
        temperature: float = 0.3,
    ) -> str:
        """
        调用通义千问 DashScope API

        Args:
            messages: 消息列表
            model: 模型名称
            max_tokens: 最大输出 token 数
            temperature: 温度参数

        Returns:
            模型输出文本
        """
        import dashscope
        from dashscope import Generation

        dashscope.api_key = settings.dashscope_api_key

        # 将消息格式转换为 DashScope 格式
        ds_messages = []
        for msg in messages:
            role = msg["role"]
            # DashScope 不支持多个连续的 system 消息，合并到第一个
            if role == "system" and ds_messages and ds_messages[-1]["role"] == "system":
                ds_messages[-1]["content"] += "\n\n" + msg["content"]
            else:
                ds_messages.append({"role": role, "content": msg["content"]})

        response = Generation.call(
            model=model,
            messages=ds_messages,
            max_tokens=max_tokens,
            temperature=temperature,
            result_format="message",
        )

        if response.status_code != 200:
            raise RuntimeError(
                f"DashScope API 错误: status={response.status_code}, "
                f"code={response.code}, message={response.message}"
            )

        return response.output.choices[0].message.content
