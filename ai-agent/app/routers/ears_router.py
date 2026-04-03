"""
开造 VibeBuild — EARS 任务卡片管理路由 (v2)
"""

import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/ears", tags=["v2-EARS 卡片"])


class EarsTaskUpdateRequest(BaseModel):
    """EARS 卡片调整请求"""
    ears_statement: Optional[str] = Field(None, description="EARS 完整语句")
    priority: Optional[int] = Field(None, ge=1, le=5, description="优先级 1-5")
    estimated_hours: Optional[float] = Field(None, description="预估工时")
    acceptance_criteria: Optional[list[str]] = Field(None, description="验收标准")


@router.get(
    "/{project_id}/tasks",
    response_model=APIResponse,
    summary="查询项目所有 EARS 卡片",
)
async def get_ears_tasks(project_id: str, request: Request):
    """查询项目的所有 EARS 任务卡片"""
    from app.db.repository import ProjectRepository

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        repo = ProjectRepository()
        tasks = await repo.get_ears_tasks(project_id)
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
    """查询单个 EARS 卡片"""
    from app.db.repository import ProjectRepository

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        repo = ProjectRepository()
        task = await repo.get_ears_task(project_id, task_id)
        if not task:
            return APIResponse(code=40401, message=f"EARS 卡片 {task_id} 不存在", request_id=request_id)
        return APIResponse(code=0, data=task, request_id=request_id)
    except Exception as e:
        logger.error("get_ears_task_error", error=str(e), request_id=request_id)
        return APIResponse(code=50002, message=f"查询失败: {e}", request_id=request_id)


@router.put(
    "/{project_id}/tasks/{task_id}",
    response_model=APIResponse,
    summary="调整 EARS 卡片（最多 3 次）",
)
async def update_ears_task(
    project_id: str,
    task_id: str,
    req: EarsTaskUpdateRequest,
    request: Request,
):
    """
    调整 EARS 卡片，每张卡片最多调整 3 次。
    允许修改: ears_statement, priority, estimated_hours, acceptance_criteria
    """
    from app.db.repository import ProjectRepository

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    changes = {k: v for k, v in req.model_dump().items() if v is not None}
    if not changes:
        return APIResponse(code=40001, message="无有效修改字段", request_id=request_id)

    try:
        repo = ProjectRepository()
        result = await repo.update_ears_task(project_id, task_id, changes)
        if "error" in result:
            return APIResponse(code=40002, message=result["error"], request_id=request_id)
        return APIResponse(code=0, data=result, request_id=request_id)
    except Exception as e:
        logger.error("update_ears_task_error", error=str(e), request_id=request_id)
        return APIResponse(code=50002, message=f"更新失败: {e}", request_id=request_id)
