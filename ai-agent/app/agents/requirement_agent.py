"""
开造 VibeBuild — 需求分析 Agent
通过多轮对话产出 requirement.md（PRD + EARS 拆解）
"""

import json
from typing import Any, Optional

import structlog

from app.agents.base_agent import ToolUseBaseAgent
from app.llm.router import LLMRouter
from app.outputs.writer import DocumentWriter
from app.prompts.requirement_prompts import REQUIREMENT_CONTEXT_TEMPLATE, REQUIREMENT_SYSTEM_PROMPT
from app.tools.agent_tools import (
    ASK_CLARIFICATION_TOOL,
    DECOMPOSE_TO_EARS_TOOL,
    GENERATE_PRD_TOOL,
)
from app.tools.document_tools import SAVE_DOCUMENT_TOOL

logger = structlog.get_logger()

# 默认维度覆盖度（全零）
DEFAULT_DIMENSION_COVERAGE = {
    "product_scope": 0,
    "target_users": 0,
    "core_features": 0,
    "tech_preference": 0,
    "business_goal": 0,
    "mvp_scope": 0,
    "constraints": 0,
}


class RequirementAgent(ToolUseBaseAgent):
    """
    需求分析 Agent

    阶段机：clarifying → prd_draft → prd_confirmed → tasks_ready
    - 一句话需求 → 多轮对话澄清 → 生成 PRD → EARS 拆解
    - 清晰需求 → 直接生成 PRD → EARS 拆解
    """

    agent_name = "requirement"
    model_tier = "high"

    def __init__(self, llm_router: LLMRouter, doc_writer: DocumentWriter):
        super().__init__(llm_router)
        self.doc_writer = doc_writer
        # 运行时上下文（由 router 层注入）
        self._project_id: str = ""
        self._sub_stage: str = "clarifying"
        self._completeness_score: int = 0
        self._dimension_coverage: dict = dict(DEFAULT_DIMENSION_COVERAGE)

    def _get_tools(self) -> list[dict]:
        return [
            ASK_CLARIFICATION_TOOL,
            GENERATE_PRD_TOOL,
            DECOMPOSE_TO_EARS_TOOL,
            SAVE_DOCUMENT_TOOL,
        ]

    def _get_system_prompt(self, **context) -> str:
        additional = context.get("additional_context", "")
        ctx = REQUIREMENT_CONTEXT_TEMPLATE.format(
            project_id=self._project_id,
            sub_stage=self._sub_stage,
            completeness_score=self._completeness_score,
            dimension_coverage=json.dumps(self._dimension_coverage, ensure_ascii=False),
            additional_context=additional,
        )
        return REQUIREMENT_SYSTEM_PROMPT + "\n\n" + ctx

    async def _execute_tool(self, tool_name: str, tool_input: dict) -> str:
        if tool_name == "ask_clarification":
            self._completeness_score = tool_input.get("completeness_score", self._completeness_score)
            self._sub_stage = "clarifying"
            # 存储维度覆盖度
            coverage = tool_input.get("dimension_coverage")
            if coverage:
                self._dimension_coverage = coverage
            return "已向用户展示澄清问题。"

        elif tool_name == "generate_prd":
            self._completeness_score = tool_input.get("completeness_score", self._completeness_score)
            self._sub_stage = "prd_draft"
            return "PRD 已生成，等待用户确认。"

        elif tool_name == "decompose_to_ears":
            self._sub_stage = "tasks_ready"
            # 自动保存文档
            md_content = tool_input.get("markdown_preview", "")
            if md_content and self._project_id:
                path = self.doc_writer.save_document(self._project_id, "requirement.md", md_content)
                return f"EARS 拆解完成，文档已保存至 {path}"
            return "EARS 拆解完成。"

        elif tool_name == "save_document":
            filename = tool_input.get("filename", "requirement.md")
            content = tool_input.get("content", "")
            if self._project_id:
                path = self.doc_writer.save_document(self._project_id, filename, content)
                return f"文档已保存至 {path}"
            return "保存失败：缺少 project_id"

        return f"未知工具: {tool_name}"

    @property
    def dimension_coverage(self) -> dict:
        """对外暴露当前维度覆盖度"""
        return dict(self._dimension_coverage)

    async def chat(
        self,
        project_id: str,
        messages: list[dict],
        sub_stage: str = "clarifying",
        completeness_score: int = 0,
        dimension_coverage: Optional[dict] = None,
    ) -> tuple[list[dict], dict[str, Any], str, int]:
        """
        执行一轮对话

        Returns:
            (updated_messages, tool_result, new_sub_stage, new_completeness_score)
        """
        self._project_id = project_id
        self._sub_stage = sub_stage
        self._completeness_score = completeness_score
        if dimension_coverage:
            self._dimension_coverage = dimension_coverage
        else:
            self._dimension_coverage = dict(DEFAULT_DIMENSION_COVERAGE)

        updated_messages, last_tool = await self.run(
            messages=messages,
            # EARS 拆解需要更多 token
            max_tokens=16384,
        )

        return (
            updated_messages,
            last_tool,
            self._sub_stage,
            self._completeness_score,
        )

    async def chat_stream(
        self,
        project_id: str,
        messages: list[dict],
        sub_stage: str = "clarifying",
        completeness_score: int = 0,
        dimension_coverage: Optional[dict] = None,
    ):
        """流式执行一轮对话，yield SSE 事件"""
        self._project_id = project_id
        self._sub_stage = sub_stage
        self._completeness_score = completeness_score
        if dimension_coverage:
            self._dimension_coverage = dimension_coverage
        else:
            self._dimension_coverage = dict(DEFAULT_DIMENSION_COVERAGE)

        async for event in self.run_stream(messages=messages, max_tokens=16384):
            yield event

        # 追加阶段信息到 done 事件后
        yield {
            "event": "stage_info",
            "data": json.dumps({
                "sub_stage": self._sub_stage,
                "completeness_score": self._completeness_score,
                "dimension_coverage": self._dimension_coverage,
            }, ensure_ascii=False),
        }

    async def confirm_prd_stream(
        self,
        project_id: str,
        messages: list[dict],
    ):
        """流式确认 PRD，yield SSE 事件"""
        self._project_id = project_id
        self._sub_stage = "prd_confirmed"
        self._completeness_score = 100

        messages.append({
            "role": "user",
            "content": "PRD 已确认，请使用 decompose_to_ears 工具将 PRD 拆解为 EARS 最小任务单元，并使用 save_document 保存完整的 requirement.md 文档。",
        })

        async for event in self.run_stream(messages=messages, max_tokens=16384):
            yield event

        yield {
            "event": "stage_info",
            "data": json.dumps({
                "sub_stage": self._sub_stage,
                "completeness_score": self._completeness_score,
                "dimension_coverage": self._dimension_coverage,
            }, ensure_ascii=False),
        }

    async def confirm_prd(
        self,
        project_id: str,
        messages: list[dict],
    ) -> tuple[list[dict], dict[str, Any], str, int]:
        """用户确认 PRD，触发 EARS 拆解"""
        self._project_id = project_id
        self._sub_stage = "prd_confirmed"
        self._completeness_score = 100

        # 添加确认指令
        messages.append({
            "role": "user",
            "content": "PRD 已确认，请使用 decompose_to_ears 工具将 PRD 拆解为 EARS 最小任务单元，并使用 save_document 保存完整的 requirement.md 文档。",
        })

        updated_messages, last_tool = await self.run(
            messages=messages,
            # EARS 拆解需要更多 token
            max_tokens=16384,
        )

        return (
            updated_messages,
            last_tool,
            self._sub_stage,
            self._completeness_score,
        )
