"""
开造 VibeBuild — 项目管理 Agent
基于前 3 个 Agent 产物，输出 project-plan.md
"""

from typing import Any

import structlog

from app.agents.base_agent import ToolUseBaseAgent
from app.llm.router import LLMRouter
from app.outputs.writer import DocumentWriter
from app.prompts.pm_prompts import PM_CONTEXT_TEMPLATE, PM_SYSTEM_PROMPT
from app.tools.agent_tools import PRODUCE_PROJECT_PLAN_TOOL
from app.tools.document_tools import SAVE_DOCUMENT_TOOL

logger = structlog.get_logger()


class PMAgent(ToolUseBaseAgent):
    """
    项目管理 Agent（单次执行）
    """

    agent_name = "pm"
    model_tier = "high"

    def __init__(self, llm_router: LLMRouter, doc_writer: DocumentWriter):
        super().__init__(llm_router)
        self.doc_writer = doc_writer
        self._project_id: str = ""

    def _get_tools(self) -> list[dict]:
        return [PRODUCE_PROJECT_PLAN_TOOL, SAVE_DOCUMENT_TOOL]

    def _get_system_prompt(self, **context) -> str:
        requirement_content = context.get("requirement_content", "")
        design_content = context.get("design_content", "")
        task_content = context.get("task_content", "")
        ctx = PM_CONTEXT_TEMPLATE.format(
            requirement_content=requirement_content,
            design_content=design_content,
            task_content=task_content,
        )
        return PM_SYSTEM_PROMPT + "\n\n" + ctx

    async def _execute_tool(self, tool_name: str, tool_input: dict) -> str:
        if tool_name == "produce_project_plan":
            md_content = tool_input.get("markdown_preview", "")
            if not md_content:
                import json
                parts = [tool_input.get("agent_message", "# 项目管理方案")]
                if tool_input.get("project_plan"):
                    parts.append("\n\n```json\n" + json.dumps(tool_input["project_plan"], ensure_ascii=False, indent=2) + "\n```")
                md_content = "\n".join(parts)
            if self._project_id:
                path = self.doc_writer.save_document(self._project_id, "project-plan.md", md_content)
                return f"项目管理方案已保存至 {path}"
            return "项目管理方案已生成。"

        elif tool_name == "save_document":
            filename = tool_input.get("filename", "project-plan.md")
            content = tool_input.get("content", "")
            if self._project_id:
                path = self.doc_writer.save_document(self._project_id, filename, content)
                return f"文档已保存至 {path}"
            return "保存失败：缺少 project_id"

        return f"未知工具: {tool_name}"

    async def generate_stream(self, project_id: str, requirement_content: str, design_content: str, task_content: str, feedback: str = ""):
        """流式生成项目管理方案，yield SSE 事件"""
        self._project_id = project_id
        user_msg = "请基于所有前序文档，使用 produce_project_plan 工具生成完整的项目管理方案。"
        if feedback:
            user_msg = f"请根据以下反馈修改项目管理方案：\n\n{feedback}\n\n使用 produce_project_plan 工具输出修改后的方案。"
        messages = [{"role": "user", "content": user_msg}]
        async for event in self.run_stream(messages=messages, max_tokens=16384, requirement_content=requirement_content, design_content=design_content, task_content=task_content):
            yield event

    async def generate(
        self,
        project_id: str,
        requirement_content: str,
        design_content: str,
        task_content: str,
        feedback: str = "",
    ) -> tuple[list[dict], dict[str, Any]]:
        """生成项目管理方案"""
        self._project_id = project_id

        user_msg = "请基于所有前序文档，使用 produce_project_plan 工具生成完整的项目管理方案。"
        if feedback:
            user_msg = f"请根据以下反馈修改项目管理方案：\n\n{feedback}\n\n使用 produce_project_plan 工具输出修改后的方案。"

        messages = [{"role": "user", "content": user_msg}]

        return await self.run(
            messages=messages,
            max_tokens=16384,
            requirement_content=requirement_content,
            design_content=design_content,
            task_content=task_content,
        )
