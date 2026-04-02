"""
开造 VibeBuild — 流水线全局 API 路由 (v2)
"""

import uuid

import structlog
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
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


@router.get("/{project_id}/documents/{filename}/download")
async def download_document(project_id: str, filename: str, request: Request):
    """下载项目文档（优先从 Minio，降级到本地文件系统）"""
    from io import BytesIO
    from app.main import v2_minio_store, v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    # 尝试从 Minio 下载
    if v2_minio_store:
        try:
            from app.db.repository import ProjectRepository
            repo = ProjectRepository()
            docs = await repo.get_documents(project_id)
            # 找到最新版本的文档
            target_doc = None
            for doc in docs:
                if doc["filename"] == filename:
                    if target_doc is None or doc["version"] > target_doc["version"]:
                        target_doc = doc
            if target_doc and target_doc["file_path"].startswith("projects/"):
                content = v2_minio_store.get_object(target_doc["file_path"])
                return StreamingResponse(
                    BytesIO(content),
                    media_type="application/octet-stream",
                    headers={"Content-Disposition": f'attachment; filename="{filename}"'},
                )
        except Exception as e:
            logger.warning("minio_download_fallback", error=str(e))

    # 降级到本地文件系统
    if v2_doc_writer:
        content = v2_doc_writer.read_document(project_id, filename)
        if content:
            return StreamingResponse(
                BytesIO(content.encode("utf-8")),
                media_type="application/octet-stream",
                headers={"Content-Disposition": f'attachment; filename="{filename}"'},
            )

    return APIResponse(code=40401, message=f"文档 {filename} 不存在", request_id=request_id)


@router.get(
    "/{project_id}/prd-items",
    response_model=APIResponse,
    summary="查询 PRD 需求条目列表",
)
async def get_prd_items(project_id: str, request: Request):
    """查询项目的 PRD 需求条目（Feature Items），供前端结构化展示"""
    from app.db.repository import ProjectRepository

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        repo = ProjectRepository()
        items = await repo.get_prd_items(project_id)
        return APIResponse(code=0, data={"items": items}, request_id=request_id)
    except Exception as e:
        logger.error("get_prd_items_error", error=str(e), request_id=request_id)
        return APIResponse(code=50002, message=f"查询失败: {e}", request_id=request_id)


@router.get(
    "/{project_id}/milestones",
    response_model=APIResponse,
    summary="查询里程碑列表",
)
async def get_milestones(project_id: str, request: Request):
    """查询项目里程碑列表，供前端项目管理页展示"""
    from app.db.repository import ProjectRepository

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        repo = ProjectRepository()
        milestones = await repo.get_milestones(project_id)
        return APIResponse(code=0, data={"milestones": milestones}, request_id=request_id)
    except Exception as e:
        logger.error("get_milestones_error", error=str(e), request_id=request_id)
        return APIResponse(code=50002, message=f"查询失败: {e}", request_id=request_id)
