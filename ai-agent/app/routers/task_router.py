"""
开造 VibeBuild — 任务文档 API 路由 (v2)
"""

import json
import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/task", tags=["v2-task"])


class StartRequest(BaseModel):
    feedback: Optional[str] = None


@router.post("/{project_id}/start", response_model=APIResponse)
async def start_task(project_id: str, req: StartRequest, request: Request):
    """启动任务分解生成"""
    from app.main import v2_orchestrator, v2_task_agent, v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        ok, msg, state = await v2_orchestrator.start_stage(project_id, "task")
        if not ok:
            return APIResponse(code=40001, message=msg, request_id=request_id)

        context = v2_orchestrator.load_stage_context(project_id, "task")

        messages, tool_result = await v2_task_agent.generate(
            project_id=project_id,
            requirement_content=context.get("requirement.md", ""),
            design_content=context.get("design.md", ""),
            feedback=req.feedback or "",
        )

        agent_text = v2_task_agent.extract_text_response(messages)
        tool_name = tool_result.get("tool_name", "")
        doc_exists = v2_doc_writer.read_document(project_id, "task.md") is not None

        if doc_exists:
            doc_path = f"outputs/{project_id}/v1/task.md"
            state.set_stage_status("task", "awaiting_confirmation", document_path=doc_path)
            await v2_orchestrator.save_project(state)
            return APIResponse(
                code=0, message="success",
                data={"project_id": project_id, "agent_message": agent_text, "tool_name": tool_name, "document_path": doc_path},
                request_id=request_id,
            )
        else:
            state.set_stage_status("task", "running")
            await v2_orchestrator.save_project(state)
            return APIResponse(
                code=50003,
                message="任务文档未生成：模型未调用 produce_task_breakdown 工具，请重试",
                data={"project_id": project_id, "agent_message": agent_text, "tool_name": tool_name},
                request_id=request_id,
            )
    except Exception as e:
        logger.error("task_start_error", error=str(e), request_id=request_id)
        return APIResponse(code=50003, message=f"任务分解生成失败: {e}", request_id=request_id)


@router.post("/{project_id}/confirm", response_model=APIResponse)
async def confirm_task(project_id: str, request: Request):
    """确认任务文档（需文档已生成）"""
    from app.main import v2_orchestrator, v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    doc_exists = v2_doc_writer.read_document(project_id, "task.md") is not None
    if not doc_exists:
        return APIResponse(code=40002, message="无法确认：task.md 文档尚未生成，请先调用 start 接口", request_id=request_id)

    ok, msg, state = await v2_orchestrator.confirm_stage(project_id, "task")
    if not ok:
        return APIResponse(code=40001, message=msg, request_id=request_id)
    return APIResponse(code=0, message=msg, data=state.to_summary(), request_id=request_id)


@router.get("/{project_id}/document", response_model=APIResponse)
async def get_document(project_id: str, request: Request):
    """获取任务文档（返回文件路径）"""
    from app.main import v2_doc_writer
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    content = v2_doc_writer.read_document(project_id, "task.md")
    if not content:
        return APIResponse(code=40402, message="文档尚未生成", request_id=request_id)
    path = v2_doc_writer.get_document_path(project_id, "task.md")
    return APIResponse(code=0, data={"filename": "task.md", "path": path, "size": len(content), "content": content}, request_id=request_id)


@router.post("/{project_id}/start/stream")
async def start_task_stream(project_id: str, req: StartRequest, request: Request):
    """[SSE 流式] 启动任务分解生成"""
    from app.main import v2_orchestrator, v2_task_agent, v2_doc_writer

    async def event_generator():
        try:
            ok, msg, state = await v2_orchestrator.start_stage(project_id, "task")
            if not ok:
                yield {"event": "error", "data": msg}
                return

            context = v2_orchestrator.load_stage_context(project_id, "task")

            async for event in v2_task_agent.generate_stream(
                project_id=project_id,
                requirement_content=context.get("requirement.md", ""),
                design_content=context.get("design.md", ""),
                feedback=req.feedback or "",
            ):
                yield event

            doc_exists = v2_doc_writer.read_document(project_id, "task.md") is not None
            if doc_exists:
                state.set_stage_status("task", "awaiting_confirmation", document_path=f"outputs/{project_id}/v1/task.md")
            await v2_orchestrator.save_project(state)

        except Exception as e:
            logger.error("task_stream_error", error=str(e))
            yield {"event": "error", "data": str(e)}

    return EventSourceResponse(event_generator())
