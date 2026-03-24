"""
开造 VibeBuild — 架构设计 API 路由 (v2)
"""

import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/design", tags=["v2-design"])


class StartRequest(BaseModel):
    feedback: Optional[str] = None


@router.post("/{project_id}/start", response_model=APIResponse)
async def start_design(project_id: str, req: StartRequest, request: Request):
    """启动架构设计生成"""
    from app.main import v2_orchestrator, v2_design_agent, v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        ok, msg, state = await v2_orchestrator.start_stage(project_id, "design")
        if not ok:
            return APIResponse(code=40001, message=msg, request_id=request_id)

        # 加载前序文档
        context = v2_orchestrator.load_stage_context(project_id, "design")
        requirement_content = context.get("requirement.md", "")

        messages, tool_result = await v2_design_agent.generate(
            project_id=project_id,
            requirement_content=requirement_content,
            feedback=req.feedback or "",
        )

        agent_text = v2_design_agent.extract_text_response(messages)
        tool_name = tool_result.get("tool_name", "")

        # 校验文档是否实际生成
        doc_exists = v2_doc_writer.read_document(project_id, "design.md") is not None

        if doc_exists:
            doc_path = f"outputs/{project_id}/v1/design.md"
            state.set_stage_status("design", "awaiting_confirmation", document_path=doc_path)
            await v2_orchestrator.save_project(state)
            return APIResponse(
                code=0, message="success",
                data={"project_id": project_id, "agent_message": agent_text, "tool_name": tool_name, "document_path": doc_path},
                request_id=request_id,
            )
        else:
            # 模型未调用 tool，文档未生成 → 保持 running 状态，提示重试
            state.set_stage_status("design", "running")
            await v2_orchestrator.save_project(state)
            return APIResponse(
                code=50002,
                message="架构设计未生成：模型未调用 produce_design 工具，请重试或提供更详细的反馈",
                data={"project_id": project_id, "agent_message": agent_text, "tool_name": tool_name},
                request_id=request_id,
            )
    except Exception as e:
        logger.error("design_start_error", error=str(e), request_id=request_id)
        return APIResponse(code=50002, message=f"架构设计生成失败: {e}", request_id=request_id)


@router.post("/{project_id}/confirm", response_model=APIResponse)
async def confirm_design(project_id: str, request: Request):
    """确认架构设计（需文档已生成）"""
    from app.main import v2_orchestrator, v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    # 校验文档是否存在
    doc_exists = v2_doc_writer.read_document(project_id, "design.md") is not None
    if not doc_exists:
        return APIResponse(code=40002, message="无法确认：design.md 文档尚未生成，请先调用 start 接口", request_id=request_id)

    ok, msg, state = await v2_orchestrator.confirm_stage(project_id, "design")
    if not ok:
        return APIResponse(code=40001, message=msg, request_id=request_id)

    return APIResponse(code=0, message=msg, data=state.to_summary(), request_id=request_id)


@router.get("/{project_id}/document", response_model=APIResponse)
async def get_document(project_id: str, request: Request):
    """获取设计文档（返回文件路径）"""
    from app.main import v2_doc_writer
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    content = v2_doc_writer.read_document(project_id, "design.md")
    if not content:
        return APIResponse(code=40402, message="文档尚未生成", request_id=request_id)
    path = v2_doc_writer.get_document_path(project_id, "design.md")
    return APIResponse(code=0, data={"filename": "design.md", "path": path, "size": len(content)}, request_id=request_id)
