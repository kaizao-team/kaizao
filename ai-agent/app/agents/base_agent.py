"""
开造 VibeBuild — Agent 基类（v2 重写）

ToolUseBaseAgent：
- 异步 agentic loop：调 LLM → 检查 tool_use → 执行 tool → 追加 tool_result → 再调 → 直到 end_turn
- 输出通过 tool 调用自动验证（Pydantic schema = tool input_schema）
- 子类实现 _get_tools() / _execute_tool() / _get_system_prompt()

保留旧 BaseAgent 供 v1 兼容。
"""

import time
import uuid
from abc import ABC, abstractmethod
from typing import Any, Optional

import structlog
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
)

from app.config import settings
from app.llm.router import LLMRouter
from app.safety.injection_defender import PromptInjectionDefender

logger = structlog.get_logger()

# 全局安全防御实例
_injection_defender = PromptInjectionDefender()


class AgentError(Exception):
    """Agent 统一异常"""

    def __init__(self, message: str, error_code: int = 50000, details: Optional[dict] = None):
        super().__init__(message)
        self.error_code = error_code
        self.details = details or {}


# ============================================================
# v1 兼容基类（旧 Agent 继续使用）
# ============================================================

class BaseAgent(ABC):
    """v1 Agent 基类（保留兼容）"""

    def __init__(self, agent_name: str, llm_router: LLMRouter):
        self.agent_name = agent_name
        self.llm_router = llm_router
        self.logger = structlog.get_logger().bind(agent=agent_name)

    async def process(self, **kwargs) -> dict[str, Any]:
        request_id = str(uuid.uuid4())[:16]
        start_time = time.time()
        self.logger.info("agent_process_start", request_id=request_id)
        try:
            result = await self._execute(request_id=request_id, **kwargs)
            duration_ms = round((time.time() - start_time) * 1000, 2)
            self.logger.info("agent_process_success", request_id=request_id, duration_ms=duration_ms)
            return result
        except AgentError:
            raise
        except Exception as e:
            raise AgentError(message=f"{self.agent_name} 处理失败: {e}", details={"original_error": str(e)})

    @abstractmethod
    async def _execute(self, request_id: str, **kwargs) -> dict[str, Any]:
        raise NotImplementedError

    @retry(
        stop=stop_after_attempt(2),
        wait=wait_exponential(multiplier=1, min=1, max=5),
        retry=retry_if_exception_type((TimeoutError, ConnectionError)),
        reraise=True,
    )
    async def call_llm(self, messages: list, model_tier: str = "default", max_tokens: int = 4096, temperature: float = 0.3, response_format: Optional[str] = None) -> str:
        return await self.llm_router.generate(messages=messages, model_tier=model_tier, max_tokens=max_tokens, temperature=temperature, response_format=response_format)

    def _build_messages(self, system_prompt: str, user_message: str, conversation_history: Optional[list] = None, injected_context: Optional[str] = None) -> list:
        messages = [{"role": "system", "content": system_prompt}]
        if injected_context:
            messages.append({"role": "system", "content": injected_context})
        if conversation_history:
            for turn in conversation_history:
                messages.append({"role": "user", "content": turn.get("user_message", "")})
                messages.append({"role": "assistant", "content": turn.get("assistant_message", "")})
        messages.append({"role": "user", "content": user_message})
        return messages

    @staticmethod
    def _estimate_tokens(text: str) -> int:
        return int(len(text) / 1.5)


# ============================================================
# v2 新基类：ToolUseBaseAgent
# ============================================================

class ToolUseBaseAgent(ABC):
    """
    v2 Agent 基类 — 基于 Anthropic tool use 的 agentic loop

    子类需实现：
    - _get_tools() → 返回 tool 定义列表
    - _execute_tool(tool_name, tool_input) → 执行 tool，返回结果字符串
    - _get_system_prompt(**context) → 返回 system prompt
    """

    agent_name: str = "base"
    model_tier: str = "high"

    def __init__(self, llm_router: LLMRouter):
        self.llm_router = llm_router
        self.logger = structlog.get_logger().bind(agent=self.agent_name)

    @abstractmethod
    def _get_tools(self) -> list[dict]:
        """返回 Anthropic tool 定义列表"""
        raise NotImplementedError

    @abstractmethod
    async def _execute_tool(self, tool_name: str, tool_input: dict) -> str:
        """执行 tool，返回 tool_result 内容字符串"""
        raise NotImplementedError

    @abstractmethod
    def _get_system_prompt(self, **context) -> str:
        """根据上下文返回 system prompt"""
        raise NotImplementedError

    async def run(
        self,
        messages: list[dict],
        system_prompt: Optional[str] = None,
        max_tokens: int = 8192,
        temperature: float = 0.3,
        **context,
    ) -> tuple[list[dict], dict[str, Any]]:
        """
        执行 agentic loop

        Args:
            messages: Anthropic 原生格式对话历史
            system_prompt: 覆盖默认 system prompt
            max_tokens: 最大输出 token
            temperature: 温度参数
            **context: 传递给 _get_system_prompt 的上下文

        Returns:
            (updated_messages, last_tool_result_parsed)
            - updated_messages: 包含完整 tool 调用链的消息列表
            - last_tool_result_parsed: 最后一次 tool 调用的 input（结构化数据）
        """
        request_id = str(uuid.uuid4())[:16]
        start_time = time.time()
        self.logger.info("agentic_loop_start", request_id=request_id)

        # ---- 前置安全拦截：检查用户最新消息 ----
        last_user_text = self._extract_last_user_text(messages)
        if last_user_text:
            check_result = self._check_safety(last_user_text)
            if not check_result["is_safe"]:
                self.logger.warning(
                    "prompt_injection_blocked",
                    agent=self.agent_name,
                    request_id=request_id,
                    risk_level=check_result["risk_level"],
                    method=check_result["detection_method"],
                )
                safe_reply = (
                    f"我是 VibeBuild 平台的{self.agent_name}，"
                    f"无法处理该请求。请描述您的正常需求。"
                )
                messages.append({"role": "assistant", "content": [{"type": "text", "text": safe_reply}]})
                return messages, {}

        sys_prompt = system_prompt or self._get_system_prompt(**context)
        tools = self._get_tools()
        last_tool_input: dict[str, Any] = {}

        for iteration in range(settings.max_agentic_loop_iterations):
            response = await self.llm_router.create_message(
                messages=messages,
                model_tier=self.model_tier,
                max_tokens=max_tokens,
                temperature=temperature,
                system=sys_prompt,
                tools=tools,
            )

            # 将 assistant 回复追加到消息列表
            assistant_content = self._serialize_content_blocks(response.content)
            messages.append({"role": "assistant", "content": assistant_content})

            # 检查是否有 tool_use
            tool_use_blocks = [b for b in response.content if getattr(b, "type", None) == "tool_use"]

            if not tool_use_blocks:
                # 没有 tool 调用，loop 结束
                self.logger.info(
                    "agentic_loop_end",
                    request_id=request_id,
                    iterations=iteration + 1,
                    stop_reason=response.stop_reason,
                    duration_ms=round((time.time() - start_time) * 1000, 2),
                )
                break

            # 执行所有 tool 调用
            tool_results = []
            for block in tool_use_blocks:
                tool_name = block.name
                tool_input = block.input
                last_tool_input = {"tool_name": tool_name, **tool_input}

                self.logger.info("tool_call", tool=tool_name, request_id=request_id)

                try:
                    result_str = await self._execute_tool(tool_name, tool_input)
                except Exception as e:
                    result_str = f"Error: {str(e)}"
                    self.logger.error("tool_error", tool=tool_name, error=str(e))

                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": result_str,
                })

            messages.append({"role": "user", "content": tool_results})

        else:
            self.logger.warning("agentic_loop_max_iterations", request_id=request_id)

        return messages, last_tool_input

    # 工具名称中文映射（供 SSE 进度展示）
    TOOL_DISPLAY_NAMES = {
        "ask_clarification": "正在分析需求完整度...",
        "generate_prd": "正在生成 PRD 文档...",
        "decompose_to_ears": "正在拆解 EARS 任务...",
        "save_document": "正在保存文档...",
        "produce_design": "正在生成架构设计...",
        "produce_task_breakdown": "正在生成任务分解...",
        "produce_project_plan": "正在生成项目管理方案...",
    }

    async def run_stream(
        self,
        messages: list[dict],
        system_prompt: Optional[str] = None,
        max_tokens: int = 8192,
        temperature: float = 0.3,
        **context,
    ):
        """
        流式执行 agentic loop，yield SSE 事件 dict

        事件类型:
        - {"event": "thinking", "data": "正在分析..."}
        - {"event": "tool_call", "data": "正在生成 PRD 文档..."}
        - {"event": "tool_result", "data": "PRD 已生成"}
        - {"event": "text", "data": "Agent 的回复文本"}
        - {"event": "done", "data": {最终结果 JSON}}
        - {"event": "error", "data": "错误信息"}
        """
        import json as _json

        request_id = str(uuid.uuid4())[:16]
        start_time = time.time()
        self.logger.info("agentic_loop_stream_start", request_id=request_id)

        yield {"event": "thinking", "data": "正在理解您的需求..."}

        # 前置安全拦截
        last_user_text = self._extract_last_user_text(messages)
        if last_user_text:
            check_result = self._check_safety(last_user_text)
            if not check_result["is_safe"]:
                safe_reply = f"我是 VibeBuild 平台的{self.agent_name}，无法处理该请求。请描述您的正常需求。"
                messages.append({"role": "assistant", "content": [{"type": "text", "text": safe_reply}]})
                yield {"event": "error", "data": safe_reply}
                return

        sys_prompt = system_prompt or self._get_system_prompt(**context)
        tools = self._get_tools()
        last_tool_input: dict[str, Any] = {}

        for iteration in range(settings.max_agentic_loop_iterations):
            yield {"event": "thinking", "data": f"AI 思考中...（第 {iteration + 1} 轮）"}

            response = await self.llm_router.create_message(
                messages=messages,
                model_tier=self.model_tier,
                max_tokens=max_tokens,
                temperature=temperature,
                system=sys_prompt,
                tools=tools,
            )

            assistant_content = self._serialize_content_blocks(response.content)
            messages.append({"role": "assistant", "content": assistant_content})

            # 提取文本回复，流式发送
            for block in response.content:
                if getattr(block, "type", None) == "text" and block.text.strip():
                    yield {"event": "text", "data": block.text}

            tool_use_blocks = [b for b in response.content if getattr(b, "type", None) == "tool_use"]

            if not tool_use_blocks:
                break

            # 执行 tool 调用
            tool_results = []
            for block in tool_use_blocks:
                tool_name = block.name
                tool_input = block.input
                last_tool_input = {"tool_name": tool_name, **tool_input}

                display = self.TOOL_DISPLAY_NAMES.get(tool_name, f"正在执行 {tool_name}...")
                yield {"event": "tool_call", "data": display}

                try:
                    result_str = await self._execute_tool(tool_name, tool_input)
                except Exception as e:
                    result_str = f"Error: {str(e)}"

                yield {"event": "tool_result", "data": result_str[:200]}

                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": result_str,
                })

            messages.append({"role": "user", "content": tool_results})

            # ask_clarification 执行后立即结束 loop，防止 LLM 二次输出重复内容
            if any(b.name == "ask_clarification" for b in tool_use_blocks):
                break

        duration_ms = round((time.time() - start_time) * 1000, 2)
        self.logger.info("agentic_loop_stream_end", request_id=request_id, duration_ms=duration_ms)

        # 构建 done 事件
        done_data = self._build_done_data(last_tool_input, duration_ms)
        yield {
            "event": "done",
            "data": _json.dumps(done_data, ensure_ascii=False),
        }

        # 将结果存到实例变量供调用方获取
        self._stream_result = (messages, last_tool_input)

    @staticmethod
    def _build_done_data(last_tool_input: dict, duration_ms: float) -> dict:
        """
        构建 done 事件数据。

        当 ask_clarification 被调用时，返回单个 question 对象 + completeness_score；
        其他情况返回通用格式。
        """
        import json as _json

        tool_name = last_tool_input.get("tool_name", "")

        if tool_name == "ask_clarification":
            questions = last_tool_input.get("questions", [])
            question_raw = questions[0] if questions else None

            if question_raw:
                # 构建 options（带 key 标签）
                opts = question_raw.get("options", [])
                options_payload = []
                for i, opt in enumerate(opts):
                    options_payload.append({"key": chr(65 + i), "label": opt.get("label", "")})
                # allow_custom → 追加"其他"选项
                if question_raw.get("allow_custom", True):
                    options_payload.append({
                        "key": chr(65 + len(opts)),
                        "label": "其他",
                        "is_custom": True,
                    })

                return {
                    "question": {
                        "id": question_raw.get("id", "q1"),
                        "content": question_raw.get("question", ""),
                        "input_type": question_raw.get("input_type", "single_choice"),
                        "options": options_payload,
                        "allow_custom": question_raw.get("allow_custom", True),
                    },
                    "completeness_score": last_tool_input.get("completeness_score", 0),
                    "duration_ms": duration_ms,
                }

        # 默认格式（generate_prd / decompose_to_ears / 其他 tool）
        return {
            "messages": "ok",
            "last_tool": last_tool_input,
            "duration_ms": duration_ms,
        }

    def _check_safety(self, user_input: str) -> dict:
        """
        安全检查（子类可覆盖以调整策略）

        默认使用全局 PromptInjectionDefender 的完整检测。
        处理长文本输入的 Agent（如简历解析）可覆盖此方法放宽长度限制。
        """
        return _injection_defender.check(user_input)

    def extract_text_response(self, messages: list[dict]) -> str:
        """从消息列表中提取最后一条 assistant 文本回复"""
        for msg in reversed(messages):
            if msg.get("role") != "assistant":
                continue
            content = msg.get("content", "")
            if isinstance(content, str):
                return content
            if isinstance(content, list):
                texts = []
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        texts.append(block["text"])
                    elif hasattr(block, "type") and block.type == "text":
                        texts.append(block.text)
                if texts:
                    return "\n".join(texts)
        return ""

    @staticmethod
    def _extract_last_user_text(messages: list[dict]) -> str:
        """从消息列表中提取最后一条用户文本"""
        for msg in reversed(messages):
            if msg.get("role") != "user":
                continue
            content = msg.get("content", "")
            if isinstance(content, str):
                return content
            if isinstance(content, list):
                texts = []
                for block in content:
                    if isinstance(block, dict):
                        if block.get("type") == "text":
                            texts.append(block.get("text", ""))
                if texts:
                    return "\n".join(texts)
        return ""

    @staticmethod
    def _serialize_content_blocks(content_blocks) -> list[dict]:
        """将 Anthropic ContentBlock 对象序列化为可 JSON 化的 dict 列表"""
        result = []
        for block in content_blocks:
            if hasattr(block, "type"):
                if block.type == "text":
                    result.append({"type": "text", "text": block.text})
                elif block.type == "tool_use":
                    result.append({
                        "type": "tool_use",
                        "id": block.id,
                        "name": block.name,
                        "input": block.input,
                    })
                else:
                    result.append({"type": block.type, "data": str(block)})
            elif isinstance(block, dict):
                result.append(block)
            else:
                result.append({"type": "text", "text": str(block)})
        return result
