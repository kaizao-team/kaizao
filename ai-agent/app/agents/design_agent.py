"""
开造 VibeBuild — 架构设计 Agent
基于确认的需求文档，产出 design.md
"""

from typing import Any

import structlog

from app.agents.base_agent import ToolUseBaseAgent
from app.llm.router import LLMRouter
from app.outputs.writer import DocumentWriter
from app.prompts.design_prompts import DESIGN_CONTEXT_TEMPLATE, DESIGN_SYSTEM_PROMPT
from app.tools.agent_tools import PRODUCE_DESIGN_TOOL
from app.tools.document_tools import SAVE_DOCUMENT_TOOL

logger = structlog.get_logger()


class DesignAgent(ToolUseBaseAgent):
    """
    架构设计 Agent（单次执行，非多轮对话）
    """

    agent_name = "design"
    model_tier = "high"

    def __init__(self, llm_router: LLMRouter, doc_writer: DocumentWriter):
        super().__init__(llm_router)
        self.doc_writer = doc_writer
        self._project_id: str = ""

    def _get_tools(self) -> list[dict]:
        return [PRODUCE_DESIGN_TOOL, SAVE_DOCUMENT_TOOL]

    def _get_system_prompt(self, **context) -> str:
        requirement_content = context.get("requirement_content", "")
        ctx = DESIGN_CONTEXT_TEMPLATE.format(requirement_content=requirement_content)
        return DESIGN_SYSTEM_PROMPT + "\n\n" + ctx

    async def _execute_tool(self, tool_name: str, tool_input: dict) -> str:
        if tool_name == "produce_design":
            md_content = tool_input.get("markdown_preview", "")
            # 如果没有 markdown_preview，从 agent_message 和 design 字段生成
            if not md_content:
                import json
                parts = []
                if tool_input.get("agent_message"):
                    parts.append(tool_input["agent_message"])
                if tool_input.get("design"):
                    parts.append("\n\n```json\n" + json.dumps(tool_input["design"], ensure_ascii=False, indent=2) + "\n```")
                md_content = "\n".join(parts) if parts else "# 架构设计文档\n\n（内容待补充）"
            if self._project_id:
                path = self.doc_writer.save_document(self._project_id, "design.md", md_content)
                return f"架构设计文档已保存至 {path}"
            return "架构设计已生成。"

        elif tool_name == "save_document":
            filename = tool_input.get("filename", "design.md")
            content = tool_input.get("content", "")
            if self._project_id:
                path = self.doc_writer.save_document(self._project_id, filename, content)
                return f"文档已保存至 {path}"
            return "保存失败：缺少 project_id"

        return f"未知工具: {tool_name}"

    async def generate(
        self,
        project_id: str,
        requirement_content: str,
        feedback: str = "",
    ) -> tuple[list[dict], dict[str, Any]]:
        """
        生成架构设计

        Args:
            project_id: 项目 ID
            requirement_content: requirement.md 内容
            feedback: 用户反馈（修改意见）

        Returns:
            (messages, last_tool_result)
        """
        self._project_id = project_id

        user_msg = "请基于提供的需求文档，使用 produce_design 工具生成完整的架构设计方案。"
        if feedback:
            user_msg = f"请根据以下反馈修改架构设计：\n\n{feedback}\n\n使用 produce_design 工具输出修改后的设计。"

        messages = [{"role": "user", "content": user_msg}]

        return await self.run(
            messages=messages,
            max_tokens=16384,
            requirement_content=requirement_content,
        )
