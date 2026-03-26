"""
开造 VibeBuild — 任务文档 Agent
产出可量化的 task.md，含双节奏排期对比
"""

from typing import Any

import structlog

from app.agents.base_agent import ToolUseBaseAgent
from app.llm.router import LLMRouter
from app.outputs.writer import DocumentWriter
from app.prompts.task_prompts import TASK_CONTEXT_TEMPLATE, TASK_SYSTEM_PROMPT
from app.tools.agent_tools import MARK_CRITICAL_RISKS_TOOL, PRODUCE_TASK_BREAKDOWN_TOOL
from app.tools.document_tools import SAVE_DOCUMENT_TOOL

logger = structlog.get_logger()


class TaskAgent(ToolUseBaseAgent):
    """
    任务文档 Agent（单次执行）
    """

    agent_name = "task"
    model_tier = "high"

    def __init__(self, llm_router: LLMRouter, doc_writer: DocumentWriter):
        super().__init__(llm_router)
        self.doc_writer = doc_writer
        self._project_id: str = ""

    def _get_tools(self) -> list[dict]:
        return [PRODUCE_TASK_BREAKDOWN_TOOL, MARK_CRITICAL_RISKS_TOOL, SAVE_DOCUMENT_TOOL]

    def _get_system_prompt(self, **context) -> str:
        requirement_content = context.get("requirement_content", "")
        design_content = context.get("design_content", "")
        ctx = TASK_CONTEXT_TEMPLATE.format(
            requirement_content=requirement_content,
            design_content=design_content,
        )
        return TASK_SYSTEM_PROMPT + "\n\n" + ctx

    async def _execute_tool(self, tool_name: str, tool_input: dict) -> str:
        if tool_name == "produce_task_breakdown":
            md_content = tool_input.get("markdown_preview", "")
            if not md_content:
                import json
                parts = [tool_input.get("agent_message", "# 任务分解文档")]
                if tool_input.get("task_document"):
                    parts.append("\n\n```json\n" + json.dumps(tool_input["task_document"], ensure_ascii=False, indent=2) + "\n```")
                md_content = "\n".join(parts)
            if self._project_id:
                path = self.doc_writer.save_document(self._project_id, "task.md", md_content)
                return f"任务文档已保存至 {path}"
            return "任务分解已生成。"

        elif tool_name == "mark_critical_risks":
            return "风险标注已更新。"

        elif tool_name == "save_document":
            filename = tool_input.get("filename", "task.md")
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
        design_content: str,
        feedback: str = "",
    ) -> tuple[list[dict], dict[str, Any]]:
        """生成任务分解文档"""
        self._project_id = project_id

        user_msg = "请基于需求文档和架构设计，使用 produce_task_breakdown 工具生成完整的任务分解方案。"
        if feedback:
            user_msg = f"请根据以下反馈修改任务分解：\n\n{feedback}\n\n使用 produce_task_breakdown 工具输出修改后的方案。"

        messages = [{"role": "user", "content": user_msg}]

        return await self.run(
            messages=messages,
            max_tokens=16384,
            requirement_content=requirement_content,
            design_content=design_content,
        )
