"""
开造 VibeBuild — 流水线编排器
管理阶段守卫、上下文加载、状态流转
"""

from typing import Optional

import structlog

from app.outputs.writer import DocumentWriter
from app.pipeline.project_state import ALL_STAGES, STAGE_FILENAMES, STAGES, ProjectState
from app.session.manager import SessionManager

logger = structlog.get_logger()


class PipelineOrchestrator:
    """流水线编排器"""

    def __init__(self, session_manager: SessionManager, doc_writer: DocumentWriter):
        self.session = session_manager
        self.writer = doc_writer

    async def init_project(self, project_id: str, title: str = "", session_id: Optional[str] = None) -> ProjectState:
        """
        初始化 AI 流水线状态。

        project_id 是 Go 后端 projects.uuid，项目行由 Go 后端创建。
        此方法仅在 ai_project_stages 中初始化阶段状态。
        """
        # 先尝试恢复已有状态
        existing = await self.get_project(project_id)
        if existing:
            logger.info("project_state_restored", project_id=project_id)
            return existing

        state = ProjectState(
            project_id=project_id,
            title=title,
            session_id=session_id,
        )
        await self.session.save_project_state(project_id, state.model_dump())
        logger.info("project_initialized", project_id=project_id)
        return state

    async def get_project(self, project_id: str) -> Optional[ProjectState]:
        """获取项目状态"""
        data = await self.session.get_project_state(project_id)
        if not data:
            return None
        return ProjectState(**data)

    async def save_project(self, state: ProjectState) -> None:
        """保存项目状态"""
        await self.session.save_project_state(state.project_id, state.model_dump())

    async def start_stage(self, project_id: str, stage_name: str) -> tuple[bool, str, Optional[ProjectState]]:
        """
        启动指定阶段

        Returns:
            (success, message, state)
        """
        state = await self.get_project(project_id)
        if not state:
            return False, f"项目 {project_id} 不存在", None

        can_start, reason = state.can_start_stage(stage_name)
        if not can_start:
            return False, reason, state

        stage = state.get_stage(stage_name)
        if stage.status == "running":
            return True, "阶段已在运行中", state

        state.set_stage_status(stage_name, "running")
        state.current_stage = stage_name
        await self.save_project(state)
        return True, "ok", state

    async def confirm_stage(self, project_id: str, stage_name: str) -> tuple[bool, str, Optional[ProjectState]]:
        """确认阶段完成"""
        state = await self.get_project(project_id)
        if not state:
            return False, f"项目 {project_id} 不存在", None

        stage = state.get_stage(stage_name)
        if stage.status not in ("running", "awaiting_confirmation"):
            return False, f"阶段 {stage_name} 当前状态为 {stage.status}，无法确认", state

        state.set_stage_status(stage_name, "confirmed")
        next_stage = state.advance_to_next_stage()
        await self.save_project(state)

        msg = f"阶段 {stage_name} 已确认"
        if next_stage:
            msg += f"，可以开始 {next_stage} 阶段"
        else:
            msg += "，需求分析流水线已完成，可以发布到广场"
        return True, msg, state

    def load_stage_context(self, project_id: str, stage_name: str) -> dict[str, str]:
        """
        加载阶段所需的前序文档上下文

        Returns:
            {filename: content} 字典
        """
        # PM 阶段需要读取 requirement.md + design.md（如果存在）
        if stage_name == "pm":
            context = {}
            for prev_stage in ["requirement", "design"]:
                filename = STAGE_FILENAMES[prev_stage]
                content = self.writer.read_document(project_id, filename)
                if content:
                    context[filename] = content
            return context

        idx = STAGES.index(stage_name)
        context = {}
        for prev_stage in STAGES[:idx]:
            filename = STAGE_FILENAMES[prev_stage]
            content = self.writer.read_document(project_id, filename)
            if content:
                context[filename] = content
        return context

    async def generate_pm(
        self,
        project_id: str,
        agreed_price: float,
        agreed_days: int,
        provider_info: dict | None = None,
    ) -> tuple[bool, str, dict | None]:
        """
        撮合完成后自动生成 PM 方案。

        由 lifecycle hook (on-matched) 调用，不走流水线守卫。

        Returns:
            (success, message, result_data)
        """
        from app.main import v2_pm_agent, v2_doc_writer

        state = await self.get_project(project_id)
        if not state:
            return False, f"项目 {project_id} 不存在", None

        # 校验流水线 requirement 阶段已完成（EARS 拆解完成）
        req_stage = state.get_stage("requirement")
        if req_stage.status != "confirmed":
            return False, f"流水线 requirement 阶段尚未确认（当前状态: {req_stage.status}），无法生成 PM 方案", None

        # 加载前序文档
        context = self.load_stage_context(project_id, "pm")
        if not context.get("requirement.md"):
            return False, "缺少需求文档 requirement.md", None

        # 调用 PM Agent
        try:
            messages, tool_result = await v2_pm_agent.generate(
                project_id=project_id,
                requirement_content=context.get("requirement.md", ""),
                design_content=context.get("design.md", ""),
                task_content="",
                agreed_price=agreed_price,
                agreed_days=agreed_days,
                provider_info=provider_info,
            )
        except Exception as e:
            logger.error("generate_pm_error", project_id=project_id, error=str(e))
            state.set_stage_status("pm", "error", error_message=str(e))
            await self.save_project(state)
            return False, f"PM Agent 调用失败: {e}", None

        # 检查文档是否生成
        doc_content = v2_doc_writer.read_document(project_id, "project-plan.md")
        if not doc_content:
            return False, "PM Agent 未生成 project-plan.md 文档", None

        # 直接标记 pm 阶段为 confirmed
        doc_path = f"outputs/{project_id}/v1/project-plan.md"
        state.set_stage_status("pm", "confirmed", document_path=doc_path)
        await self.save_project(state)

        # 解析里程碑数据
        milestones = self._parse_milestones(doc_content)

        logger.info("pm_generated_via_lifecycle", project_id=project_id, milestones_count=len(milestones))

        return True, "PM 方案已生成", {
            "project_id": project_id,
            "pm_document_path": doc_path,
            "milestones": milestones,
        }

    @staticmethod
    def _parse_milestones(doc_content: str) -> list[dict]:
        """
        从 project-plan.md 中解析里程碑数据。

        尝试提取结构化信息；如果解析失败返回空列表（不阻断流程）。
        """
        import re

        milestones = []
        # 匹配 ### 里程碑 N: 名称（X天，支付 Y%）
        pattern = r"###\s*里程碑\s*(\d+)\s*[:：]\s*(.+?)（(\d+)\s*天[，,]\s*支付\s*(\d+)%）"
        for match in re.finditer(pattern, doc_content):
            milestones.append({
                "index": int(match.group(1)),
                "title": match.group(2).strip(),
                "duration_days": int(match.group(3)),
                "payment_ratio": int(match.group(4)) / 100.0,
            })
        return milestones

    async def get_all_documents(self, project_id: str) -> list[dict]:
        """获取项目所有已生成的文档（只返回元数据，不返回内容）"""
        state = await self.get_project(project_id)
        if not state:
            return []

        docs = []
        for stage_name in ALL_STAGES:
            stage = state.get_stage(stage_name)
            if stage.status in ("confirmed", "awaiting_confirmation"):
                filename = STAGE_FILENAMES[stage_name]
                content = self.writer.read_document(project_id, filename)
                if content:
                    docs.append({
                        "stage": stage_name,
                        "filename": filename,
                        "path": self.writer.get_document_path(project_id, filename),
                        "size": len(content),
                        "status": stage.status,
                    })
        return docs
