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
    "product_positioning": 0,
    "target_users": 0,
    "core_modules": 0,
    "business_flow": 0,
    "tech_preference": 0,
    "delivery_expectation": 0,
}


class RequirementAgent(ToolUseBaseAgent):
    """
    需求分析 Agent

    阶段机：
    - 对话阶段（chat）: clarifying → prd_draft（只用 ask_clarification + generate_prd）
    - 确认阶段（confirm）: prd_draft → prd_confirmed（轻量标记）
    - 拆解阶段（decompose）: prd_confirmed → ears_decomposing → tasks_ready（独立接口，用 decompose_to_ears + save_document）
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
        """对话阶段只暴露澄清+PRD生成，EARS 拆解由独立接口触发"""
        if self._sub_stage == "ears_decomposing":
            return [DECOMPOSE_TO_EARS_TOOL, SAVE_DOCUMENT_TOOL]
        return [ASK_CLARIFICATION_TOOL, GENERATE_PRD_TOOL]

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
            if self._project_id:
                prd = tool_input.get("prd", {})
                complexity = tool_input.get("complexity")
                # 解析 PRD feature_modules → 写入 ai_prd_items
                self._persist_prd_items(self._project_id, prd)
                # 持久化项目级概览信息 → 写入 ai_project_overview
                self._persist_project_overview(self._project_id, prd, complexity)
                # 保存 PRD markdown 到 MinIO / 文件系统
                md_preview = tool_input.get("markdown_preview", "")
                if md_preview:
                    path = self.doc_writer.save_document(
                        self._project_id, "requirement.md", md_preview, stage="requirement",
                    )
                    logger.info("prd_document_saved", project_id=self._project_id, path=path)
            return "PRD 已生成，等待用户确认。"

        elif tool_name == "decompose_to_ears":
            self._sub_stage = "tasks_ready"
            # EARS 任务直接写 Go 的 tasks 表，里程碑写 Go 的 milestones 表
            if self._project_id:
                tasks = tool_input.get("ears_tasks", [])
                milestones = tool_input.get("milestones", [])
                self._persist_ears_to_go_tasks(self._project_id, tasks)
                if milestones:
                    self._persist_milestones_to_go(self._project_id, milestones)
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

    @staticmethod
    def _persist_prd_items(project_id: str, prd: dict) -> None:
        """解析 PRD feature_modules，异步写入 ai_prd_items"""
        import asyncio

        items = []
        for module in prd.get("feature_modules", []):
            module_name = module.get("module_name", "")
            for fi in module.get("feature_items", []):
                items.append({
                    "item_id": fi.get("item_id", ""),
                    "module_name": module_name,
                    "title": fi.get("title", ""),
                    "description": fi.get("description", ""),
                    "priority": fi.get("priority", "P1"),
                    "acceptance_summary": fi.get("acceptance_summary", ""),
                })
        if not items:
            return

        async def _do():
            try:
                from app.db.repository import ProjectRepository
                repo = ProjectRepository()
                await repo.save_prd_items(project_id, items)
            except Exception as e:
                logger.warning("persist_prd_items_failed", error=str(e))

        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_do())
        except RuntimeError:
            pass

    @staticmethod
    def _persist_project_overview(project_id: str, prd: dict, complexity: str | None = None) -> None:
        """持久化项目级概览信息，异步写入 ai_project_overview"""
        import asyncio

        modules = prd.get("feature_modules", [])
        item_count = sum(len(m.get("feature_items", [])) for m in modules)

        overview = {
            "title": prd.get("title", ""),
            "summary": prd.get("summary", ""),
            "target_users": prd.get("target_users"),
            "complexity": complexity,
            "tech_requirements": prd.get("tech_requirements"),
            "non_functional_requirements": prd.get("non_functional_requirements"),
            "module_count": len(modules),
            "item_count": item_count,
        }

        async def _do():
            try:
                from app.db.repository import ProjectRepository
                repo = ProjectRepository()
                await repo.save_project_overview(project_id, overview)
            except Exception as e:
                logger.warning("persist_project_overview_failed", error=str(e))

        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_do())
        except RuntimeError:
            pass

    @staticmethod
    def _persist_ears_tasks(project_id: str, tasks: list[dict]) -> None:
        """[DEPRECATED] 旧的 ai_ears_tasks 落库，保留供兼容，新流程请用 _persist_ears_to_go_tasks"""
        import asyncio

        if not tasks:
            return

        async def _do():
            try:
                from app.db.repository import ProjectRepository
                repo = ProjectRepository()
                await repo.save_ears_tasks(project_id, tasks)
            except Exception as e:
                logger.warning("persist_ears_tasks_failed", error=str(e))

        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_do())
        except RuntimeError:
            pass

    @staticmethod
    def _persist_ears_to_go_tasks(project_id: str, tasks: list[dict]) -> None:
        """EARS 任务直接写入 Go 的 tasks 表（使用 projects.uuid 关联到内部 bigint id）"""
        import asyncio

        if not tasks:
            return

        async def _do():
            try:
                from app.db.repository import GoTasksRepository
                repo = GoTasksRepository()
                count = await repo.save_ears_to_tasks(project_id, tasks)
                logger.info("ears_tasks_written_to_go", project_id=project_id, count=count)
            except Exception as e:
                logger.warning("persist_ears_to_go_tasks_failed", project_id=project_id, error=str(e))

        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_do())
        except RuntimeError:
            pass

    @staticmethod
    def _persist_milestones_to_go(project_id: str, milestones: list[dict]) -> None:
        """AI 规划的里程碑直接写入 Go 的 milestones 表"""
        import asyncio

        if not milestones:
            return

        async def _do():
            try:
                from app.db.repository import GoTasksRepository
                repo = GoTasksRepository()
                count = await repo.save_milestones_to_go(project_id, milestones)
                logger.info("milestones_written_to_go", project_id=project_id, count=count)
            except Exception as e:
                logger.warning("persist_milestones_to_go_failed", project_id=project_id, error=str(e))

        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_do())
        except RuntimeError:
            pass

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

        # 对话阶段（澄清+PRD）用 8192 加速，EARS 拆解在独立方法中用 16384
        updated_messages, last_tool = await self.run(
            messages=messages,
            max_tokens=8192,
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

        async for event in self.run_stream(messages=messages, max_tokens=8192):
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

    async def decompose_ears_stream(
        self,
        project_id: str,
        messages: list[dict],
    ):
        """流式 EARS 拆解（确认合作后调用），yield SSE 事件"""
        self._project_id = project_id
        self._sub_stage = "ears_decomposing"
        self._completeness_score = 100

        messages.append({
            "role": "user",
            "content": "需求双方已确认合作，请使用 decompose_to_ears 工具将 PRD 拆解为 EARS 最小任务单元，并使用 save_document 保存完整的 requirement.md 文档。",
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

    async def decompose_ears(
        self,
        project_id: str,
        messages: list[dict],
    ) -> tuple[list[dict], dict[str, Any], str, int]:
        """EARS 拆解（确认合作后调用）"""
        self._project_id = project_id
        self._sub_stage = "ears_decomposing"
        self._completeness_score = 100

        messages.append({
            "role": "user",
            "content": "需求双方已确认合作，请使用 decompose_to_ears 工具将 PRD 拆解为 EARS 最小任务单元，并使用 save_document 保存完整的 requirement.md 文档。",
        })

        updated_messages, last_tool = await self.run(
            messages=messages,
            max_tokens=16384,
        )

        return (
            updated_messages,
            last_tool,
            self._sub_stage,
            self._completeness_score,
        )
