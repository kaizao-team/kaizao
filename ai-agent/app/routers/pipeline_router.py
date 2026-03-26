"""
开造 VibeBuild — 流水线全局 API 路由 (v2)
"""

import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/pipeline", tags=["v2-pipeline"])


class CreateProjectRequest(BaseModel):
    title: str
    project_id: Optional[str] = None


@router.post("/start", response_model=APIResponse)
async def create_project(req: CreateProjectRequest, request: Request):
    """创建项目（不启动任何阶段）"""
    from app.main import v2_orchestrator

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    project_id = req.project_id or str(uuid.uuid4())[:12]
    state = await v2_orchestrator.create_project(project_id, req.title)

    return APIResponse(
        code=0,
        message="项目已创建",
        data=state.to_summary(),
        request_id=request_id,
    )


@router.get("/{project_id}/status", response_model=APIResponse)
async def get_status(project_id: str, request: Request):
    """获取项目全局进度"""
    from app.main import v2_orchestrator

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    state = await v2_orchestrator.get_project(project_id)
    if not state:
        return APIResponse(code=40401, message=f"项目 {project_id} 不存在", request_id=request_id)

    return APIResponse(code=0, data=state.to_summary(), request_id=request_id)


@router.get("/{project_id}/documents", response_model=APIResponse)
async def get_all_documents(project_id: str, request: Request):
    """获取项目所有已生成的文档"""
    from app.main import v2_orchestrator

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    docs = await v2_orchestrator.get_all_documents(project_id)
    return APIResponse(code=0, data={"documents": docs}, request_id=request_id)
