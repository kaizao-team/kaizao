"""
开造 VibeBuild — 对话助手 API 路由 (v2)

意图识别 + 多轮对话 + Agent 转交。
"""

import uuid
from typing import Optional, Dict, Any

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/chat", tags=["v2-对话助手"])


class ChatRequest(BaseModel):
    """对话请求体"""
    session_id: str = Field(..., description="会话 ID")
    user_id: str = Field(..., description="用户 ID")
    user_role: Optional[str] = Field("unknown", description="用户角色")
    message: Dict[str, Any] = Field(..., description="消息内容")
    page_context: Optional[Dict[str, Any]] = Field(None, description="当前页面上下文")


@router.post(
    "/message",
    response_model=APIResponse,
    summary="对话助手",
    description="""
## 智能对话助手

功能：
- 意图识别 — 自动分类用户消息意图
- 多轮对话 — 上下文滑动窗口管理
- Agent 转交 — 需求发布转需求分析 Agent，找人转匹配 Agent
- 页面导航 — 根据意图建议跳转到相应页面
""",
)
async def chat(req: ChatRequest, request: Request):
    """对话助手 — 意图识别 + 多轮对话"""
    from app.main import chat_assistant

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    if not chat_assistant:
        return APIResponse(
            code=50003,
            message="对话助手服务未初始化",
            request_id=request_id,
        )

    try:
        result = await chat_assistant.process(
            session_id=req.session_id,
            user_id=req.user_id,
            user_role=req.user_role,
            message=req.message,
            page_context=req.page_context,
        )
        return APIResponse(code=0, message="success", data=result, request_id=request_id)
    except Exception as e:
        logger.error("chat_error", error=str(e), request_id=request_id)
        return APIResponse(
            code=50003, message=f"AI 对话服务异常: {e}", request_id=request_id
        )
