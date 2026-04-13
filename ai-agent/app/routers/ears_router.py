"""
开造 VibeBuild — EARS 任务卡片管理路由 (v2)

任务数据已直接存在 Go 后端的 tasks 表中，本路由从 tasks 表读取。
"""

import uuid

import structlog
from fastapi import APIRouter, Request

from app.db.engine import get_session_factory
from app.db.models import Project
from app.schemas.common import APIResponse
from sqlalchemy import select, text as sqlalchemy_text

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/ears", tags=["v2-EARS 卡片"])


async def _get_project_id(project_uuid: str):
    async with get_session_factory()() as session:
        q = await session.execute(
            select(Project.id).where(Project.uuid == project_uuid)
        )
        return q.scalar_one_or_none()


@router.get(
    "/{project_id}/tasks",
    response_model=APIResponse,
    summary="查询项目所有 EARS 卡片",
)
async def get_ears_tasks(project_id: str, request: Request):
    """查询项目的所有 EARS 任务卡片（从 Go tasks 表读取）"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    try:
        pid = await _get_project_id(project_id)
        if not pid:
            return APIResponse(code=40401, message="项目不存在", request_id=request_id)

        async with get_session_factory()() as session:
            result = await session.execute(
                sqlalchemy_text(
                    "SELECT uuid, task_code, feature_item_id, title, ears_type, ears_trigger, "
                    "ears_behavior, ears_full_text, module, role_tag, priority, "
                    "estimated_hours, acceptance_criteria, dependencies, status, "
                    "sort_order, is_ai_generated, created_at "
                    "FROM tasks WHERE project_id = :pid ORDER BY sort_order"
                ),
                {"pid": pid},
            )
            rows = result.mappings().all()
            tasks = [dict(r) for r in rows]
            for t in tasks:
                if t.get("created_at"):
                    t["created_at"] = t["created_at"].isoformat()

        return APIResponse(code=0, data={"tasks": tasks}, request_id=request_id)
    except Exception as e:
        logger.error("get_ears_tasks_error", error=str(e), request_id=request_id)
        return APIResponse(code=50002, message=f"查询失败: {e}", request_id=request_id)


@router.get(
    "/{project_id}/tasks/{task_id}",
    response_model=APIResponse,
    summary="查询单个 EARS 卡片详情",
)
async def get_ears_task(project_id: str, task_id: str, request: Request):
    """查询单个 EARS 卡片（从 Go tasks 表读取）"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    try:
        pid = await _get_project_id(project_id)
        if not pid:
            return APIResponse(code=40401, message="项目不存在", request_id=request_id)

        async with get_session_factory()() as session:
            result = await session.execute(
                sqlalchemy_text(
                    "SELECT uuid, task_code, feature_item_id, title, ears_type, ears_trigger, "
                    "ears_behavior, ears_full_text, module, role_tag, priority, "
                    "estimated_hours, acceptance_criteria, dependencies, status, "
                    "sort_order, is_ai_generated, created_at "
                    "FROM tasks WHERE project_id = :pid AND (task_code = :tid OR uuid = :tid) "
                    "LIMIT 1"
                ),
                {"pid": pid, "tid": task_id},
            )
            row = result.mappings().first()
            if not row:
                return APIResponse(code=40401, message=f"任务 {task_id} 不存在", request_id=request_id)
            task = dict(row)
            if task.get("created_at"):
                task["created_at"] = task["created_at"].isoformat()

        return APIResponse(code=0, data=task, request_id=request_id)
    except Exception as e:
        logger.error("get_ears_task_error", error=str(e), request_id=request_id)
        return APIResponse(code=50002, message=f"查询失败: {e}", request_id=request_id)
