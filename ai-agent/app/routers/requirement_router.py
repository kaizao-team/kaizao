"""
开造 VibeBuild — 需求分析 API 路由 (v2)
"""

import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/requirement", tags=["v2-requirement"])


class StartRequest(BaseModel):
    """创建项目 + 首轮对话"""
    message: str
    title: Optional[str] = ""
    project_id: Optional[str] = None


class MessageRequest(BaseModel):
    """多轮对话消息"""
    message: str


class ConfirmRequest(BaseModel):
    """确认 PRD"""
    feedback: Optional[str] = None


@router.post("/start", response_model=APIResponse)
async def start_requirement(req: StartRequest, request: Request):
    """创建项目 + 首轮需求对话"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        project_id = req.project_id or str(uuid.uuid4())[:12]
        session_id = f"req-{project_id}"

        # 创建项目
        state = await v2_orchestrator.create_project(project_id, req.title or req.message[:50], session_id)
        state.set_stage_status("requirement", "running", sub_stage="clarifying")
        await v2_orchestrator.save_project(state)

        # 首轮对话
        messages = [{"role": "user", "content": req.message}]
        updated_msgs, tool_result, sub_stage, score = await v2_requirement_agent.chat(
            project_id=project_id,
            messages=messages,
            sub_stage="clarifying",
            completeness_score=0,
        )

        # 保存会话
        await v2_session.save_history(session_id, updated_msgs)
        state.set_stage_status("requirement", "running", sub_stage=sub_stage)
        await v2_orchestrator.save_project(state)

        agent_text = v2_requirement_agent.extract_text_response(updated_msgs)

        # 精简 tool_result，移除大字段
        slim_tool = {k: v for k, v in tool_result.items() if k not in ("markdown_preview", "prd", "ears_tasks")}

        return APIResponse(
            code=0,
            message="success",
            data={
                "project_id": project_id,
                "session_id": session_id,
                "agent_message": agent_text,
                "sub_stage": sub_stage,
                "completeness_score": score,
                "tool_result": slim_tool,
            },
            request_id=request_id,
        )
    except Exception as e:
        logger.error("requirement_start_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"需求分析启动失败: {e}", request_id=request_id)


@router.post("/{project_id}/message", response_model=APIResponse)
async def send_message(project_id: str, req: MessageRequest, request: Request):
    """多轮需求对话"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        state = await v2_orchestrator.get_project(project_id)
        if not state:
            return APIResponse(code=40401, message=f"项目 {project_id} 不存在", request_id=request_id)

        session_id = state.session_id or f"req-{project_id}"
        history = await v2_session.get_history(session_id)

        # 追加用户消息
        history.append({"role": "user", "content": req.message})

        req_stage = state.requirement
        updated_msgs, tool_result, sub_stage, score = await v2_requirement_agent.chat(
            project_id=project_id,
            messages=history,
            sub_stage=req_stage.sub_stage or "clarifying",
            completeness_score=0,
        )

        await v2_session.save_history(session_id, updated_msgs)
        state.set_stage_status("requirement", "running", sub_stage=sub_stage)
        await v2_orchestrator.save_project(state)

        agent_text = v2_requirement_agent.extract_text_response(updated_msgs)

        return APIResponse(
            code=0,
            message="success",
            data={
                "project_id": project_id,
                "agent_message": agent_text,
                "sub_stage": sub_stage,
                "completeness_score": score,
                "tool_name": tool_result.get("tool_name", ""),
            },
            request_id=request_id,
        )
    except Exception as e:
        logger.error("requirement_message_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"需求对话失败: {e}", request_id=request_id)


@router.post("/{project_id}/confirm", response_model=APIResponse)
async def confirm_prd(project_id: str, req: ConfirmRequest, request: Request):
    """确认 PRD → 触发 EARS 拆解"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        state = await v2_orchestrator.get_project(project_id)
        if not state:
            return APIResponse(code=40401, message=f"项目 {project_id} 不存在", request_id=request_id)

        session_id = state.session_id or f"req-{project_id}"
        history = await v2_session.get_history(session_id)

        updated_msgs, tool_result, sub_stage, score = await v2_requirement_agent.confirm_prd(
            project_id=project_id,
            messages=history,
        )

        await v2_session.save_history(session_id, updated_msgs)
        state.set_stage_status("requirement", "awaiting_confirmation", sub_stage=sub_stage)
        if sub_stage == "tasks_ready":
            state.set_stage_status("requirement", "confirmed", sub_stage=sub_stage,
                                   document_path=f"outputs/{project_id}/v1/requirement.md")
        await v2_orchestrator.save_project(state)

        agent_text = v2_requirement_agent.extract_text_response(updated_msgs)

        return APIResponse(
            code=0,
            message="success",
            data={
                "project_id": project_id,
                "agent_message": agent_text,
                "sub_stage": sub_stage,
                "completeness_score": score,
                "tool_name": tool_result.get("tool_name", ""),
                "document_path": f"outputs/{project_id}/v1/requirement.md" if sub_stage == "tasks_ready" else None,
            },
            request_id=request_id,
        )
    except Exception as e:
        logger.error("requirement_confirm_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"PRD 确认失败: {e}", request_id=request_id)


@router.get("/{project_id}/document", response_model=APIResponse)
async def get_document(project_id: str, request: Request):
    """获取需求文档（返回文件路径，内容存文件）"""
    from app.main import v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    content = v2_doc_writer.read_document(project_id, "requirement.md")
    if not content:
        return APIResponse(code=40402, message="文档尚未生成", request_id=request_id)
    path = v2_doc_writer.get_document_path(project_id, "requirement.md")
    return APIResponse(code=0, data={"filename": "requirement.md", "path": path, "size": len(content)}, request_id=request_id)
