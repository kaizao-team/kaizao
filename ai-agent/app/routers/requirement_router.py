"""
开造 VibeBuild — 需求分析 API 路由 (v2)
支持普通 JSON 接口 + SSE 流式接口
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


# ============================================================
# 普通 JSON 接口（保持兼容）
# ============================================================

@router.post("/start", response_model=APIResponse)
async def start_requirement(req: StartRequest, request: Request):
    """创建项目 + 首轮需求对话"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        project_id = req.project_id or str(uuid.uuid4())[:12]
        session_id = f"req-{project_id}"

        state = await v2_orchestrator.create_project(project_id, req.title or req.message[:50], session_id)
        state.set_stage_status("requirement", "running", sub_stage="clarifying")
        await v2_orchestrator.save_project(state)

        messages = [{"role": "user", "content": req.message}]
        updated_msgs, tool_result, sub_stage, score = await v2_requirement_agent.chat(
            project_id=project_id,
            messages=messages,
            sub_stage="clarifying",
            completeness_score=0,
        )

        await v2_session.save_history(session_id, updated_msgs)
        state.set_stage_status("requirement", "running", sub_stage=sub_stage)
        await v2_orchestrator.save_project(state)

        agent_text = v2_requirement_agent.extract_text_response(updated_msgs)
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
    """获取需求文档"""
    from app.main import v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    content = v2_doc_writer.read_document(project_id, "requirement.md")
    if not content:
        return APIResponse(code=40402, message="文档尚未生成", request_id=request_id)
    path = v2_doc_writer.get_document_path(project_id, "requirement.md")
    return APIResponse(code=0, data={"filename": "requirement.md", "path": path, "size": len(content), "content": content}, request_id=request_id)


# ============================================================
# SSE 流式接口（前端实时展示思考过程）
# ============================================================

@router.post("/start/stream")
async def start_requirement_stream(req: StartRequest, request: Request):
    """[SSE 流式] 创建项目 + 首轮需求对话"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    project_id = req.project_id or str(uuid.uuid4())[:12]
    session_id = f"req-{project_id}"

    async def event_generator():
        try:
            yield {"event": "init", "data": json.dumps({"project_id": project_id, "session_id": session_id}, ensure_ascii=False)}

            state = await v2_orchestrator.create_project(project_id, req.title or req.message[:50], session_id)
            state.set_stage_status("requirement", "running", sub_stage="clarifying")
            await v2_orchestrator.save_project(state)

            messages = [{"role": "user", "content": req.message}]

            async for event in v2_requirement_agent.chat_stream(
                project_id=project_id,
                messages=messages,
                sub_stage="clarifying",
                completeness_score=0,
            ):
                yield event

            # 保存状态
            if hasattr(v2_requirement_agent, '_stream_result'):
                updated_msgs, _ = v2_requirement_agent._stream_result
                await v2_session.save_history(session_id, updated_msgs)
                state.set_stage_status("requirement", "running", sub_stage=v2_requirement_agent._sub_stage)
                await v2_orchestrator.save_project(state)

        except Exception as e:
            logger.error("requirement_start_stream_error", error=str(e))
            yield {"event": "error", "data": str(e)}

    return EventSourceResponse(event_generator())


@router.post("/{project_id}/message/stream")
async def send_message_stream(project_id: str, req: MessageRequest, request: Request):
    """[SSE 流式] 多轮需求对话"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    async def event_generator():
        try:
            state = await v2_orchestrator.get_project(project_id)
            if not state:
                yield {"event": "error", "data": f"项目 {project_id} 不存在"}
                return

            session_id = state.session_id or f"req-{project_id}"
            history = await v2_session.get_history(session_id)
            history.append({"role": "user", "content": req.message})

            req_stage = state.requirement

            async for event in v2_requirement_agent.chat_stream(
                project_id=project_id,
                messages=history,
                sub_stage=req_stage.sub_stage or "clarifying",
                completeness_score=0,
            ):
                yield event

            if hasattr(v2_requirement_agent, '_stream_result'):
                updated_msgs, _ = v2_requirement_agent._stream_result
                await v2_session.save_history(session_id, updated_msgs)
                state.set_stage_status("requirement", "running", sub_stage=v2_requirement_agent._sub_stage)
                await v2_orchestrator.save_project(state)

        except Exception as e:
            logger.error("requirement_message_stream_error", error=str(e))
            yield {"event": "error", "data": str(e)}

    return EventSourceResponse(event_generator())


@router.post("/{project_id}/confirm/stream")
async def confirm_prd_stream(project_id: str, req: ConfirmRequest, request: Request):
    """[SSE 流式] 确认 PRD → 触发 EARS 拆解（含实时思考过程）"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    async def event_generator():
        try:
            state = await v2_orchestrator.get_project(project_id)
            if not state:
                yield {"event": "error", "data": f"项目 {project_id} 不存在"}
                return

            session_id = state.session_id or f"req-{project_id}"
            history = await v2_session.get_history(session_id)

            async for event in v2_requirement_agent.confirm_prd_stream(
                project_id=project_id,
                messages=history,
            ):
                yield event

            # 保存状态
            if hasattr(v2_requirement_agent, '_stream_result'):
                updated_msgs, _ = v2_requirement_agent._stream_result
                await v2_session.save_history(session_id, updated_msgs)

                sub_stage = v2_requirement_agent._sub_stage
                state.set_stage_status("requirement", "awaiting_confirmation", sub_stage=sub_stage)
                if sub_stage == "tasks_ready":
                    state.set_stage_status("requirement", "confirmed", sub_stage=sub_stage,
                                           document_path=f"outputs/{project_id}/v1/requirement.md")
                await v2_orchestrator.save_project(state)

        except Exception as e:
            logger.error("requirement_confirm_stream_error", error=str(e))
            yield {"event": "error", "data": str(e)}

    return EventSourceResponse(event_generator())
