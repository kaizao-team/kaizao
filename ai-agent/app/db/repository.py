"""
开造 VibeBuild — 异步 CRUD 操作封装
提供 ProjectRepository 用于 MySQL 持久化
"""

import json
from datetime import datetime
from typing import Optional

import structlog
from sqlalchemy import select, delete
from sqlalchemy.dialects.mysql import insert as mysql_insert

from app.db.engine import get_session_factory
from app.db.models import ConversationMessage, Document, Project, ProjectStage

logger = structlog.get_logger()


class ProjectRepository:
    """项目持久化仓库"""

    # ---- 项目 CRUD ----

    async def save_project(self, project_id: str, state: dict) -> None:
        """保存/更新项目及其阶段状态"""
        async with get_session_factory()() as session:
            async with session.begin():
                # upsert 项目主表
                stmt = mysql_insert(Project).values(
                    id=project_id,
                    title=state.get("title", ""),
                    current_stage=state.get("current_stage", "requirement"),
                    version=state.get("version", 1),
                    session_id=state.get("session_id"),
                )
                stmt = stmt.on_duplicate_key_update(
                    title=stmt.inserted.title,
                    current_stage=stmt.inserted.current_stage,
                    version=stmt.inserted.version,
                    session_id=stmt.inserted.session_id,
                    updated_at=datetime.now(),
                )
                await session.execute(stmt)

                # upsert 各阶段状态
                for stage_name in ("requirement", "design", "task", "pm"):
                    stage_data = state.get(stage_name, {})
                    if isinstance(stage_data, dict):
                        stage_stmt = mysql_insert(ProjectStage).values(
                            project_id=project_id,
                            stage_name=stage_name,
                            status=stage_data.get("status", "pending"),
                            sub_stage=stage_data.get("sub_stage"),
                            document_path=stage_data.get("document_path"),
                            error_message=stage_data.get("error_message"),
                            started_at=_parse_dt(stage_data.get("started_at")),
                            completed_at=_parse_dt(stage_data.get("completed_at")),
                        )
                        stage_stmt = stage_stmt.on_duplicate_key_update(
                            status=stage_stmt.inserted.status,
                            sub_stage=stage_stmt.inserted.sub_stage,
                            document_path=stage_stmt.inserted.document_path,
                            error_message=stage_stmt.inserted.error_message,
                            started_at=stage_stmt.inserted.started_at,
                            completed_at=stage_stmt.inserted.completed_at,
                        )
                        await session.execute(stage_stmt)

    async def get_project(self, project_id: str) -> Optional[dict]:
        """从 MySQL 读取项目及阶段状态，还原为 ProjectState 格式的 dict"""
        async with get_session_factory()() as session:
            project = await session.get(Project, project_id)
            if not project:
                return None

            result = {
                "project_id": project.id,
                "title": project.title,
                "current_stage": project.current_stage,
                "version": project.version,
                "session_id": project.session_id,
                "created_at": project.created_at.isoformat() if project.created_at else None,
                "updated_at": project.updated_at.isoformat() if project.updated_at else None,
            }

            # 读取各阶段
            stages_q = await session.execute(
                select(ProjectStage).where(ProjectStage.project_id == project_id)
            )
            for stage in stages_q.scalars().all():
                result[stage.stage_name] = {
                    "status": stage.status,
                    "sub_stage": stage.sub_stage,
                    "document_path": stage.document_path,
                    "error_message": stage.error_message,
                    "started_at": stage.started_at.isoformat() if stage.started_at else None,
                    "completed_at": stage.completed_at.isoformat() if stage.completed_at else None,
                }

            return result

    async def delete_project(self, project_id: str) -> None:
        """删除项目（级联删除阶段）"""
        async with get_session_factory()() as session:
            async with session.begin():
                await session.execute(
                    delete(ProjectStage).where(ProjectStage.project_id == project_id)
                )
                await session.execute(
                    delete(Project).where(Project.id == project_id)
                )

    # ---- 文档记录 ----

    async def save_document_record(
        self,
        project_id: str,
        stage: str,
        filename: str,
        file_path: str,
        version: int = 1,
        size_bytes: int = 0,
    ) -> None:
        """保存文档元信息"""
        async with get_session_factory()() as session:
            async with session.begin():
                stmt = mysql_insert(Document).values(
                    project_id=project_id,
                    stage=stage,
                    filename=filename,
                    file_path=file_path,
                    version=version,
                    size_bytes=size_bytes,
                )
                stmt = stmt.on_duplicate_key_update(
                    file_path=stmt.inserted.file_path,
                    size_bytes=stmt.inserted.size_bytes,
                    stage=stmt.inserted.stage,
                )
                await session.execute(stmt)

    async def get_documents(self, project_id: str) -> list[dict]:
        """获取项目所有文档记录"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(Document).where(Document.project_id == project_id)
            )
            return [
                {
                    "id": doc.id,
                    "stage": doc.stage,
                    "filename": doc.filename,
                    "file_path": doc.file_path,
                    "version": doc.version,
                    "size_bytes": doc.size_bytes,
                    "created_at": doc.created_at.isoformat() if doc.created_at else None,
                }
                for doc in q.scalars().all()
            ]

    # ---- 对话消息 ----

    async def save_messages(
        self,
        session_id: str,
        messages: list[dict],
        project_id: Optional[str] = None,
    ) -> None:
        """批量保存对话消息（全量覆盖写入）"""
        async with get_session_factory()() as session:
            async with session.begin():
                # 先清除该 session 的旧消息
                await session.execute(
                    delete(ConversationMessage).where(
                        ConversationMessage.session_id == session_id
                    )
                )
                # 写入新消息
                for idx, msg in enumerate(messages):
                    content = msg.get("content", "")
                    if not isinstance(content, str):
                        content = json.dumps(content, ensure_ascii=False, default=str)
                    session.add(ConversationMessage(
                        session_id=session_id,
                        project_id=project_id,
                        role=msg.get("role", "unknown"),
                        content=content,
                        message_index=idx,
                    ))

    async def get_messages(self, session_id: str) -> list[dict]:
        """读取对话消息"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(ConversationMessage)
                .where(ConversationMessage.session_id == session_id)
                .order_by(ConversationMessage.message_index)
            )
            results = []
            for msg in q.scalars().all():
                content = msg.content
                # 尝试还原 JSON 格式的 content
                try:
                    content = json.loads(content)
                except (json.JSONDecodeError, TypeError):
                    pass
                results.append({"role": msg.role, "content": content})
            return results


def _parse_dt(val) -> Optional[datetime]:
    """安全解析 ISO 格式日期字符串"""
    if val is None:
        return None
    if isinstance(val, datetime):
        return val
    try:
        return datetime.fromisoformat(val)
    except (ValueError, TypeError):
        return None
