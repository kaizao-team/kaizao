"""
开造 VibeBuild — AI 文档下载路由

管理端通过此接口查询项目 AI 文档列表，返回 MinIO 预签名下载 URL。
"""

import os

import structlog
from fastapi import APIRouter

from app.config import settings
from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/documents", tags=["documents"])

# MinIO 外网地址，如 47.236.165.75:39531
MINIO_PUBLIC_ENDPOINT = os.getenv("MINIO_PUBLIC_ENDPOINT", "")


@router.get("/{project_id}")
async def list_project_documents(project_id: str):
    """列出项目的所有 AI 文档"""
    try:
        from app.db.repository import ProjectRepository
        repo = ProjectRepository()
        docs = await repo.get_documents(project_id)
        return APIResponse(code=0, message="success", data=docs)
    except Exception as e:
        logger.error("list_documents_error", project_id=project_id, error=str(e))
        return APIResponse(code=500, message="查询失败", data=None)


@router.get("/{project_id}/download/{doc_id}")
async def download_document(project_id: str, doc_id: int):
    """返回文档的 MinIO 预签名下载 URL"""
    try:
        from app.db.repository import ProjectRepository
        repo = ProjectRepository()
        docs = await repo.get_documents(project_id)

        doc = next((d for d in docs if d["id"] == doc_id), None)
        if not doc:
            return APIResponse(code=404, message="文档不存在", data=None)

        file_path = doc["file_path"]

        from app.main import v2_minio_store
        if v2_minio_store:
            try:
                url = v2_minio_store.download_url(file_path, expires_hours=1)
                # 将内网地址替换为外网可访问地址
                if MINIO_PUBLIC_ENDPOINT:
                    internal = f"http://{settings.minio_endpoint}"
                    url = url.replace(internal, f"http://{MINIO_PUBLIC_ENDPOINT}")
                return APIResponse(
                    code=0, message="success",
                    data={"download_url": url, "filename": doc["filename"]},
                )
            except Exception as e:
                logger.warning("minio_presign_failed", error=str(e))

        return APIResponse(code=404, message="文档文件不可用", data=None)

    except Exception as e:
        logger.error("download_document_error", error=str(e))
        return APIResponse(code=500, message="下载失败", data=None)
