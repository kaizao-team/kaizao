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
    """初始化 AI 流水线 + 首轮需求对话"""
    message: str
    title: Optional[str] = ""
    project_id: str  # Go 后端 projects.uuid，必填


class MessageRequest(BaseModel):
    """多轮对话消息"""
    message: str
    option_key: Optional[str] = None


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
        project_id = req.project_id
        session_id = f"req-{project_id}"

        state = await v2_orchestrator.init_project(project_id, req.title or req.message[:50], session_id)
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
        slim_tool = {k: v for k, v in tool_result.items() if k not in ("markdown_preview", "prd", "ears_tasks", "questions", "dimension_coverage")}

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
                "questions": tool_result.get("questions", []),
                "dimension_coverage": tool_result.get("dimension_coverage") or v2_requirement_agent.dimension_coverage,
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
        user_content = req.message
        if req.option_key:
            user_content = f"[用户选择了选项 {req.option_key}] {req.message}"
        history.append({"role": "user", "content": user_content})

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
                "questions": tool_result.get("questions", []),
                "dimension_coverage": tool_result.get("dimension_coverage") or v2_requirement_agent.dimension_coverage,
            },
            request_id=request_id,
        )
    except Exception as e:
        logger.error("requirement_message_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"需求对话失败: {e}", request_id=request_id)


@router.post("/{project_id}/confirm", response_model=APIResponse)
async def confirm_prd(project_id: str, req: ConfirmRequest, request: Request):
    """
    确认 PRD — 轻量操作，立即返回。

    只标记 PRD 已确认，不触发 EARS 拆解。
    EARS 拆解在撮合成功、确认合作后由 POST /{project_id}/decompose 触发。
    """
    from app.main import v2_orchestrator

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        state = await v2_orchestrator.get_project(project_id)
        if not state:
            return APIResponse(code=40401, message=f"项目 {project_id} 不存在", request_id=request_id)

        # 标记 PRD 已确认，requirement 阶段完成
        state.set_stage_status("requirement", "confirmed", sub_stage="prd_confirmed",
                               document_path=f"outputs/{project_id}/v1/prd.md")
        await v2_orchestrator.save_project(state)

        return APIResponse(
            code=0,
            message="PRD 已确认",
            data={
                "project_id": project_id,
                "sub_stage": "prd_confirmed",
                "completeness_score": 100,
            },
            request_id=request_id,
        )
    except Exception as e:
        logger.error("requirement_confirm_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"PRD 确认失败: {e}", request_id=request_id)


@router.post("/{project_id}/decompose", response_model=APIResponse)
async def decompose_ears(project_id: str, request: Request):
    """
    触发 EARS 拆解 — PRD 确认后调用。

    内部逻辑：
    1. 从 MinIO 读取 requirement.md（完整 PRD 文档）
    2. 从 ai_prd_items 读取结构化需求条目
    3. 构建上下文喂给 AI 做 EARS 拆解
    4. 拆解结果直接写入 Go 的 tasks 表 + milestones 表
    5. 后台异步执行，前端通过 GET /pipeline/{project_id}/status 轮询 sub_stage
    """
    import asyncio
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent, v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        state = await v2_orchestrator.get_project(project_id)
        if not state:
            return APIResponse(code=40401, message=f"项目 {project_id} 不存在", request_id=request_id)

        session_id = state.session_id or f"req-{project_id}"

        # 读取预期交付天数
        agreed_days = None
        try:
            from app.db.repository import ProjectRepository as _PR
            agreed_days = await _PR().get_project_agreed_days(project_id)
        except Exception as e:
            logger.warning("decompose_read_agreed_days_skip", error=str(e))

        # 读取 PRD 文档和结构化需求条目，构建拆解上下文
        prd_context_parts = []

        # 1. 从 MinIO 读取 requirement.md
        try:
            prd_md = v2_doc_writer.read_document(project_id, "requirement.md")
            if prd_md:
                prd_context_parts.append(f"## 完整 PRD 文档\n\n{prd_md}")
        except Exception as e:
            logger.warning("decompose_read_prd_md_skip", project_id=project_id, error=str(e))

        # 2. 从 ai_prd_items 读取结构化条目
        try:
            from app.db.repository import ProjectRepository
            repo = ProjectRepository()
            prd_items = await repo.get_prd_items(project_id)
            if prd_items:
                items_text = "\n".join(
                    f"- [{it.get('item_id', '')}] {it.get('title', '')}：{it.get('description', '')}（优先级 {it.get('priority', 'P1')}）"
                    for it in prd_items
                )
                prd_context_parts.append(f"## 结构化需求条目\n\n{items_text}")
        except Exception as e:
            logger.warning("decompose_read_prd_items_skip", project_id=project_id, error=str(e))

        # 标记 EARS 拆解进行中
        state.set_stage_status("requirement", "running", sub_stage="ears_decomposing")
        await v2_orchestrator.save_project(state)

        # 后台异步执行 EARS 拆解
        async def _background_ears_decompose():
            try:
                history = await v2_session.get_history(session_id)

                # 注入 PRD 上下文到历史消息
                if prd_context_parts:
                    prd_context_msg = {
                        "role": "user",
                        "content": "以下是已确认的 PRD 文档和需求条目，请基于此进行 EARS 拆解：\n\n" + "\n\n".join(prd_context_parts),
                    }
                    history = history + [prd_context_msg]

                updated_msgs, tool_result, sub_stage, score = await v2_requirement_agent.decompose_ears(
                    project_id=project_id,
                    messages=history,
                    agreed_days=agreed_days,
                )
                await v2_session.save_history(session_id, updated_msgs)
                bg_state = await v2_orchestrator.get_project(project_id)
                if bg_state:
                    if sub_stage == "tasks_ready":
                        bg_state.set_stage_status("requirement", "confirmed", sub_stage=sub_stage,
                                                   document_path=f"outputs/{project_id}/v1/requirement.md")
                        await v2_orchestrator.save_project(bg_state)
                        logger.info("ears_decompose_done", project_id=project_id)
                    else:
                        bg_state.set_stage_status("requirement", "running", sub_stage=sub_stage)
                        await v2_orchestrator.save_project(bg_state)
                logger.info("ears_decompose_complete", project_id=project_id, sub_stage=sub_stage)
            except Exception as e:
                logger.error("ears_decompose_failed", project_id=project_id, error=str(e))
                err_state = await v2_orchestrator.get_project(project_id)
                if err_state:
                    err_state.set_stage_status("requirement", "error", error_message=str(e))
                    await v2_orchestrator.save_project(err_state)

        asyncio.create_task(_background_ears_decompose())

        return APIResponse(
            code=0,
            message="EARS 拆解已启动",
            data={
                "project_id": project_id,
                "sub_stage": "ears_decomposing",
                "ears_status": "processing",
            },
            request_id=request_id,
        )
    except Exception as e:
        logger.error("ears_decompose_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"EARS 拆解启动失败: {e}", request_id=request_id)


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

    project_id = req.project_id
    session_id = f"req-{project_id}"

    async def event_generator():
        try:
            yield {"event": "init", "data": json.dumps({"project_id": project_id, "session_id": session_id}, ensure_ascii=False)}

            state = await v2_orchestrator.init_project(project_id, req.title or req.message[:50], session_id)
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
            user_content = req.message
            if req.option_key:
                user_content = f"[用户选择了选项 {req.option_key}] {req.message}"
            history.append({"role": "user", "content": user_content})

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


@router.post("/{project_id}/decompose/stream")
async def decompose_ears_stream(project_id: str, request: Request):
    """[SSE 流式] EARS 拆解（确认合作后调用，含实时思考过程）"""
    from app.main import v2_orchestrator, v2_session, v2_requirement_agent

    async def event_generator():
        try:
            state = await v2_orchestrator.get_project(project_id)
            if not state:
                yield {"event": "error", "data": f"项目 {project_id} 不存在"}
                return

            # 读取预期交付天数
            agreed_days = None
            try:
                from app.db.repository import ProjectRepository as _PR
                agreed_days = await _PR().get_project_agreed_days(project_id)
            except Exception:
                pass

            session_id = state.session_id or f"req-{project_id}"
            history = await v2_session.get_history(session_id)

            async for event in v2_requirement_agent.decompose_ears_stream(
                project_id=project_id,
                messages=history,
                agreed_days=agreed_days,
            ):
                yield event

            # 保存状态
            if hasattr(v2_requirement_agent, '_stream_result'):
                import asyncio
                updated_msgs, _ = v2_requirement_agent._stream_result
                await v2_session.save_history(session_id, updated_msgs)

                sub_stage = v2_requirement_agent._sub_stage
                if sub_stage == "tasks_ready":
                    state.set_stage_status("requirement", "confirmed", sub_stage=sub_stage,
                                           document_path=f"outputs/{project_id}/v1/requirement.md")
                    await v2_orchestrator.save_project(state)
                    logger.info("ears_stream_decompose_done", project_id=project_id)
                else:
                    state.set_stage_status("requirement", "running", sub_stage=sub_stage)
                    await v2_orchestrator.save_project(state)

        except Exception as e:
            logger.error("ears_decompose_stream_error", error=str(e))
            yield {"event": "error", "data": str(e)}

    return EventSourceResponse(event_generator())
