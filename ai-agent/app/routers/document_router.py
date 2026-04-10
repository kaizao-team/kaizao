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


# ─── PRD 重新分析提取结构化数据 ───

REANALYZE_SYSTEM_PROMPT = """你是 VibeBuild 平台的需求分析专家。
你的任务是：从给定的 PRD markdown 文档中，提取出结构化的需求数据。

你必须调用 extract_prd_structure 工具，输出以下结构化信息：
1. prd 对象：title, summary, target_users, feature_modules（含需求条目 item_id/title/description/priority/acceptance_summary）, tech_requirements, non_functional_requirements
2. complexity：项目复杂度等级 S/M/L/XL

严格基于文档内容提取，不要添加文档中不存在的功能。
feature_modules 中的 feature_items 编号必须使用 F-X.Y 格式（如 F-1.1, F-1.2, F-2.1）。
"""

EXTRACT_PRD_STRUCTURE_TOOL = {
    "name": "extract_prd_structure",
    "description": "从 PRD 文档中提取结构化需求数据",
    "input_schema": {
        "type": "object",
        "properties": {
            "complexity": {
                "type": "string",
                "enum": ["S", "M", "L", "XL"],
            },
            "prd": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "summary": {"type": "string"},
                    "target_users": {"type": "array", "items": {"type": "object"}},
                    "feature_modules": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "module_name": {"type": "string"},
                                "description": {"type": "string"},
                                "feature_items": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "item_id": {"type": "string"},
                                            "title": {"type": "string"},
                                            "description": {"type": "string"},
                                            "priority": {"type": "string", "enum": ["P0", "P1", "P2"]},
                                            "acceptance_summary": {"type": "string"},
                                        },
                                        "required": ["item_id", "title", "description", "priority", "acceptance_summary"],
                                    },
                                },
                            },
                        },
                    },
                    "tech_requirements": {"type": "object"},
                    "non_functional_requirements": {"type": "object"},
                },
                "required": ["title", "summary", "target_users", "feature_modules", "tech_requirements", "non_functional_requirements"],
            },
        },
        "required": ["complexity", "prd"],
    },
}


@router.post("/{project_id}/reanalyze")
async def reanalyze_prd(project_id: str):
    """读取最新 PRD 文档，让 LLM 重新提取结构化数据覆盖 ai_prd_items + ai_project_overview"""
    try:
        # 1. 读取 PRD 文档内容
        content = None
        from app.main import v2_minio_store, v2_doc_writer
        if v2_minio_store:
            try:
                from app.db.repository import ProjectRepository
                repo = ProjectRepository()
                docs = await repo.get_documents(project_id)
                prd_doc = next((d for d in docs if d["filename"] == PRD_FILENAME), None)
                if prd_doc:
                    content = v2_minio_store.get_object(prd_doc["file_path"]).decode("utf-8")
            except Exception as e:
                logger.warning("reanalyze_minio_read_failed", error=str(e))

        if content is None and v2_doc_writer:
            content = v2_doc_writer.read_document(project_id, PRD_FILENAME)

        if not content:
            return APIResponse(code=404, message="未找到 PRD 文档，请先上传", data=None)

        # 2. 调用 LLM 提取结构化数据
        from app.main import llm_router
        if not llm_router:
            return APIResponse(code=500, message="LLM 不可用", data=None)

        messages = [
            {"role": "user", "content": f"请从以下 PRD 文档中提取结构化需求数据：\n\n{content}"},
        ]

        response = await llm_router.create_message(
            messages=messages,
            model_tier="high",
            max_tokens=8192,
            temperature=0.1,
            system=REANALYZE_SYSTEM_PROMPT,
            tools=[EXTRACT_PRD_STRUCTURE_TOOL],
        )

        # 3. 解析 tool_use 结果
        tool_input = None
        for block in response.content:
            if hasattr(block, "type") and block.type == "tool_use" and block.name == "extract_prd_structure":
                tool_input = block.input
                break

        if not tool_input:
            return APIResponse(code=500, message="LLM 未返回结构化数据", data=None)

        prd = tool_input.get("prd", {})
        complexity = tool_input.get("complexity")

        # 4. 清除旧数据 + 写入新数据
        from app.db.repository import ProjectRepository
        repo = ProjectRepository()

        # 清除旧 prd_items
        await repo.delete_prd_items(project_id)

        # 写入新 prd_items
        items = []
        for module in prd.get("feature_modules", []):
            module_name = module.get("module_name", "")
            for fi in module.get("feature_items", []):
                items.append({
                    "item_id": fi.get("item_id", ""),
                    "module_name": module_name,
                    "title": fi.get("title", ""),
                    "description": fi.get("description", ""),
                    "priority": fi.get("priority", "P1"),
                    "acceptance_summary": fi.get("acceptance_summary", ""),
                })
        if items:
            await repo.save_prd_items(project_id, items)

        # 写入/覆盖 project_overview
        overview = {
            "title": prd.get("title", ""),
            "summary": prd.get("summary", ""),
            "target_users": prd.get("target_users", []),
            "complexity": complexity,
            "tech_requirements": prd.get("tech_requirements", {}),
            "non_functional_requirements": prd.get("non_functional_requirements", {}),
            "module_count": len(prd.get("feature_modules", [])),
            "item_count": len(items),
        }
        await repo.save_project_overview(project_id, overview)

        logger.info("reanalyze_prd_complete", project_id=project_id, items=len(items), complexity=complexity)

        return APIResponse(
            code=0,
            message="success",
            data={
                "project_id": project_id,
                "complexity": complexity,
                "module_count": overview["module_count"],
                "item_count": len(items),
            },
        )

    except Exception as e:
        logger.error("reanalyze_prd_error", project_id=project_id, error=str(e))
        return APIResponse(code=500, message=f"重新分析失败: {e}", data=None)
