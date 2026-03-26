"""
开造 VibeBuild — 智能匹配 API 路由 (v2)

为需求方推荐合适的造物者（供给方），基于向量检索 + 多维评分 + LLM 推荐。
"""

import uuid
from typing import Optional, Dict, Any

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/match", tags=["v2-智能匹配"])


class MatchRequest(BaseModel):
    """匹配请求体"""
    demand_id: str = Field(..., description="需求 ID")
    match_type: str = Field(default="recommend_providers", description="匹配类型")
    user_id: Optional[str] = Field(None, description="用户 ID")
    filters: Optional[Dict[str, Any]] = Field(None, description="筛选条件")
    pagination: Optional[Dict[str, int]] = Field(None, description="分页参数 {page, page_size}")


@router.post(
    "/recommend",
    response_model=APIResponse,
    summary="智能匹配推荐",
    description="""
## 为需求推荐合适的造物者

基于需求描述进行向量检索 + 多维评分 + LLM 推荐理由生成。

匹配维度：
- 技能匹配度 (30%)
- 评分/等级 (25%)
- 价格匹配 (20%)
- 交付能力 (15%)
- 响应速度 (10%)
""",
)
async def smart_match(req: MatchRequest, request: Request):
    """智能匹配 — 为需求推荐供给方"""
    from app.main import smart_matcher

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    if not smart_matcher:
        return APIResponse(
            code=50002,
            message="智能匹配服务未初始化（需要 Milvus + Embedding 组件）",
            request_id=request_id,
        )

    try:
        result = await smart_matcher.process(
            demand_id=req.demand_id,
            match_type=req.match_type,
            user_id=req.user_id,
            filters=req.filters,
            pagination=req.pagination,
        )
        return APIResponse(code=0, message="success", data=result, request_id=request_id)
    except Exception as e:
        logger.error("smart_match_error", error=str(e), request_id=request_id)
        return APIResponse(
            code=50002, message=f"AI 匹配服务异常: {e}", request_id=request_id
        )
