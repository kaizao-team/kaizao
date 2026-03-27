"""
开造 VibeBuild — 流水线编排器
管理阶段守卫、上下文加载、状态流转
"""

from typing import Optional

import structlog

from app.outputs.writer import DocumentWriter
from app.pipeline.project_state import STAGE_FILENAMES, STAGES, ProjectState
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
            msg += "，所有阶段已完成"
        return True, msg, state

    def load_stage_context(self, project_id: str, stage_name: str) -> dict[str, str]:
        """
        加载阶段所需的前序文档上下文

        Returns:
            {filename: content} 字典
        """
        idx = STAGES.index(stage_name)
        context = {}
        for prev_stage in STAGES[:idx]:
            filename = STAGE_FILENAMES[prev_stage]
            content = self.writer.read_document(project_id, filename)
            if content:
                context[filename] = content
        return context

    async def get_all_documents(self, project_id: str) -> list[dict]:
        """获取项目所有已生成的文档（只返回元数据，不返回内容）"""
        state = await self.get_project(project_id)
        if not state:
            return []

        docs = []
        for stage_name in STAGES:
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
