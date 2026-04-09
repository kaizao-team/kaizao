"""
VibeBuild document router.

Admin side uses this router to list/download/upload AI documents.
"""

from pathlib import Path

import structlog
from fastapi import APIRouter, File, UploadFile
from fastapi.responses import Response

from app.config import settings
from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/documents", tags=["documents"])

PRD_FILENAME = "requirement.md"
PRD_STAGE = "requirement"
MAX_PRD_UPLOAD_BYTES = 2 * 1024 * 1024
PRD_ALLOWED_EXTENSIONS = {".md", ".markdown", ".txt"}
PRD_ALLOWED_CONTENT_TYPES = {"text/markdown", "text/plain", "application/octet-stream"}


def _is_valid_prd_upload(file: UploadFile) -> tuple[bool, str]:
    name = (file.filename or "").strip()
    ext = Path(name).suffix.lower()
    if ext not in PRD_ALLOWED_EXTENSIONS:
        return False, "unsupported file extension"

    content_type = (file.content_type or "").split(";", 1)[0].strip().lower()
    if content_type and content_type not in PRD_ALLOWED_CONTENT_TYPES:
        return False, "unsupported content type"
    return True, ""


async def _read_upload_limited(file: UploadFile, max_bytes: int) -> bytes | None:
    chunks: list[bytes] = []
    total = 0
    while True:
        chunk = await file.read(64 * 1024)
        if not chunk:
            break
        total += len(chunk)
        if total > max_bytes:
            return None
        chunks.append(chunk)
    return b"".join(chunks)


def _safe_local_output_path(file_path: str) -> Path | None:
    if not file_path:
        return None
    root = (Path.cwd() / settings.output_dir).resolve()
    p = Path(file_path)
    if not p.is_absolute():
        p = (Path.cwd() / p).resolve()
    else:
        p = p.resolve()
    try:
        p.relative_to(root)
        return p
    except ValueError:
        return None


async def _cleanup_stale_prd_documents(repo, stale_docs: list[dict]) -> int:
    if not stale_docs:
        return 0

    from app.main import v2_minio_store

    removed_ids: list[int] = []
    for doc in stale_docs:
        doc_id = doc.get("id")
        file_path = str(doc.get("file_path") or "")

        # MinIO object key format in this project.
        if file_path.startswith("projects/") and v2_minio_store:
            try:
                v2_minio_store.remove(file_path)
            except Exception as e:
                logger.warning("remove_old_prd_minio_failed", id=doc_id, path=file_path, error=str(e))
        else:
            local_path = _safe_local_output_path(file_path)
            if local_path and local_path.exists():
                try:
                    local_path.unlink()
                except Exception as e:
                    logger.warning("remove_old_prd_local_failed", id=doc_id, path=str(local_path), error=str(e))

        if isinstance(doc_id, int):
            removed_ids.append(doc_id)

    if removed_ids:
        await repo.delete_documents_by_ids(removed_ids)
    return len(removed_ids)


@router.put("/{project_id}/prd/document")
async def upload_project_prd_document(
    project_id: str,
    file: UploadFile = File(...),
):
    """Upload PRD document and overwrite previous persisted PRD document."""
    try:
        valid, reason = _is_valid_prd_upload(file)
        if not valid:
            return APIResponse(code=400, message=reason, data=None)

        raw = await _read_upload_limited(file, MAX_PRD_UPLOAD_BYTES)
        if raw is None:
            return APIResponse(code=413, message="file too large", data=None)
        if not raw:
            return APIResponse(code=400, message="empty file", data=None)

        try:
            content = raw.decode("utf-8")
        except UnicodeDecodeError:
            return APIResponse(code=400, message="file must be utf-8 text", data=None)

        from app.db.repository import ProjectRepository

        repo = ProjectRepository()
        if not await repo.verify_project_exists(project_id):
            return APIResponse(code=404, message="project not found", data=None)

        docs = await repo.get_documents(project_id)
        prd_docs = [
            d for d in docs
            if d.get("filename") == PRD_FILENAME or d.get("stage") == PRD_STAGE
        ]
        target_version = max((int(d.get("version") or 1) for d in prd_docs), default=1)

        from app.main import v2_doc_writer
        if not v2_doc_writer:
            return APIResponse(code=500, message="document writer unavailable", data=None)

        path = v2_doc_writer.save_document(
            project_id=project_id,
            filename=PRD_FILENAME,
            content=content,
            version=target_version,
            stage=PRD_STAGE,
        )

        stale_docs = [
            d for d in prd_docs
            if d.get("filename") != PRD_FILENAME or int(d.get("version") or 0) != target_version
        ]
        removed_count = await _cleanup_stale_prd_documents(repo, stale_docs)

        return APIResponse(
            code=0,
            message="success",
            data={
                "project_id": project_id,
                "filename": PRD_FILENAME,
                "version": target_version,
                "path": path,
                "overwritten": True,
                "removed_old_versions": removed_count,
            },
        )
    except Exception as e:
        logger.error("upload_prd_document_error", project_id=project_id, error=str(e))
        return APIResponse(code=500, message="upload failed", data=None)


@router.get("/{project_id}")
async def list_project_documents(project_id: str):
    """List project AI documents."""
    try:
        from app.db.repository import ProjectRepository
        repo = ProjectRepository()
        docs = await repo.get_documents(project_id)
        return APIResponse(code=0, message="success", data=docs)
    except Exception as e:
        logger.error("list_documents_error", project_id=project_id, error=str(e))
        return APIResponse(code=500, message="query failed", data=None)


@router.get("/{project_id}/download/{doc_id}")
async def download_document(project_id: str, doc_id: int):
    """Return file content directly for browser download."""
    try:
        from app.db.repository import ProjectRepository
        repo = ProjectRepository()
        docs = await repo.get_documents(project_id)

        doc = next((d for d in docs if d["id"] == doc_id), None)
        if not doc:
            return APIResponse(code=404, message="document not found", data=None)

        file_path = doc["file_path"]
        filename = doc["filename"]
        content = None

        # Prefer MinIO.
        from app.main import v2_minio_store
        if v2_minio_store:
            try:
                content = v2_minio_store.get_object(file_path).decode("utf-8")
            except Exception as e:
                logger.warning("minio_get_object_failed", error=str(e))

        # Fallback to local file.
        if content is None:
            from app.main import v2_doc_writer
            if v2_doc_writer:
                content = v2_doc_writer.read_document(
                    project_id, filename, doc.get("version")
                )

        if content is None:
            return APIResponse(code=404, message="document file unavailable", data=None)

        return Response(
            content=content.encode("utf-8"),
            media_type="text/markdown; charset=utf-8",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
            },
        )
    except Exception as e:
        logger.error("download_document_error", error=str(e))
        return APIResponse(code=500, message="download failed", data=None)
