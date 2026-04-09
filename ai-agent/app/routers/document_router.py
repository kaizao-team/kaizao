"""
开造 VibeBuild — AI 文档下载路由

管理端通过此接口查询项目 AI 文档列表，直接返回文件内容供前端下载。
"""

import structlog
from fastapi import APIRouter

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/documents", tags=["documents"])


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
    """读取文档内容并返回，前端用 Blob 下载"""
    try:
        from app.db.repository import ProjectRepository
        repo = ProjectRepository()
        docs = await repo.get_documents(project_id)

        doc = next((d for d in docs if d["id"] == doc_id), None)
        if not doc:
            return APIResponse(code=404, message="文档不存在", data=None)

        file_path = doc["file_path"]
        filename = doc["filename"]

        # 优先从 MinIO 读取
        from app.main import v2_minio_store
        if v2_minio_store:
            try:
                content_bytes = v2_minio_store.get_object(file_path)
                content = content_bytes.decode("utf-8")
                return APIResponse(
                    code=0, message="success",
                    data={"content": content, "filename": filename},
                )
            except Exception as e:
                logger.warning("minio_get_object_failed", error=str(e))

        # 降级：本地文件读取
        from app.main import v2_doc_writer
        if v2_doc_writer:
            content = v2_doc_writer.read_document(
                project_id, filename, doc.get("version")
            )
            if content:
                return APIResponse(
                    code=0, message="success",
                    data={"content": content, "filename": filename},
                )

        return APIResponse(code=404, message="文档文件不可用", data=None)

    except Exception as e:
        logger.error("download_document_error", error=str(e))
        return APIResponse(code=500, message="下载失败", data=None)
