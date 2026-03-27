"""
开造 VibeBuild — 流水线全局 API 路由 (v2)
"""

import uuid

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/pipeline", tags=["v2-pipeline"])


class InitProjectRequest(BaseModel):
    """初始化 AI 流水线（project_id 为 Go 后端 projects.uuid，必填）"""
    project_id: str
    title: str = ""


@router.post("/start", response_model=APIResponse)
async def init_project(req: InitProjectRequest, request: Request):
    """初始化 AI 流水线状态（项目需已在 Go 后端创建）"""
    from app.main import v2_orchestrator

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    state = await v2_orchestrator.init_project(req.project_id, req.title)

    return APIResponse(
        code=0,
        message="AI 流水线已初始化",
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
