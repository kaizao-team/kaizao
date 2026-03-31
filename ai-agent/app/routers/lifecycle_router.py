"""
开造 VibeBuild — 生命周期 Hook 路由 (v2)

Go 后端在关键业务节点调用这些 webhook 接口，触发 AI 行为。

| Go 后端事件          | Hook                          | 触发时机         |
|---------------------|-------------------------------|-----------------|
| BidService.Accept() | POST /on-matched              | 发起人选定造物者  |
| 支付完成             | POST /on-started              | 托管支付成功      |
| 里程碑提交           | POST /on-milestone-delivered  | 造物者提交交付物  |
| 项目完成             | POST /on-completed            | 全部里程碑验收    |
"""

import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/lifecycle", tags=["v2-lifecycle"])


# ─── Request / Response 模型 ───


class OnMatchedRequest(BaseModel):
    project_id: str          # Go 后端 projects.uuid
    provider_id: int         # 造物者 user_id (bigint)
    bid_id: int              # 中标的 bid id
    agreed_price: float      # 商定价格
    agreed_days: int         # 商定工期
    provider_info: Optional[dict] = None  # 可选的造物者详情


class OnStartedRequest(BaseModel):
    project_id: str
    order_id: Optional[str] = None


class OnMilestoneDeliveredRequest(BaseModel):
    project_id: str
    milestone_id: Optional[int] = None


class OnCompletedRequest(BaseModel):
    project_id: str


# ─── 路由 ───


@router.post("/on-matched", response_model=APIResponse)
async def on_matched(req: OnMatchedRequest, request: Request):
    """
    撮合完成 Hook — 发起人选定造物者后由 Go 后端调用。

    内部逻辑：
    1. 验证 project_id 存在且 task 阶段已 confirmed
    2. 加载 3 份前序文档
    3. 将 agreed_price / agreed_days 注入 PM Agent 上下文
    4. 调用 PM Agent 生成 project-plan.md
    5. 标记 pm 阶段为 confirmed
    6. 解析里程碑数据，结构化返回
    """
    from app.main import v2_orchestrator

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    if not v2_orchestrator:
        return APIResponse(code=50001, message="流水线编排器未初始化", request_id=request_id)

    logger.info(
        "lifecycle_on_matched",
        project_id=req.project_id,
        provider_id=req.provider_id,
        bid_id=req.bid_id,
        agreed_price=req.agreed_price,
        agreed_days=req.agreed_days,
        request_id=request_id,
    )

    ok, msg, data = await v2_orchestrator.generate_pm(
        project_id=req.project_id,
        agreed_price=req.agreed_price,
        agreed_days=req.agreed_days,
        provider_info=req.provider_info,
    )

    if not ok:
        return APIResponse(code=40001, message=msg, request_id=request_id)

    return APIResponse(code=0, message=msg, data=data, request_id=request_id)


@router.post("/on-started", response_model=APIResponse)
async def on_started(req: OnStartedRequest, request: Request):
    """支付完成 Hook — 托管支付成功后由 Go 后端调用（占位）"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    logger.info("lifecycle_on_started", project_id=req.project_id, request_id=request_id)
    return APIResponse(code=0, message="ok", data={"project_id": req.project_id}, request_id=request_id)


@router.post("/on-milestone-delivered", response_model=APIResponse)
async def on_milestone_delivered(req: OnMilestoneDeliveredRequest, request: Request):
    """里程碑交付 Hook — 造物者提交交付物后由 Go 后端调用（占位）"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    logger.info("lifecycle_on_milestone_delivered", project_id=req.project_id, request_id=request_id)
    return APIResponse(code=0, message="ok", data={"project_id": req.project_id}, request_id=request_id)


@router.post("/on-completed", response_model=APIResponse)
async def on_completed(req: OnCompletedRequest, request: Request):
    """项目完成 Hook — 全部里程碑验收通过后由 Go 后端调用（占位）"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    logger.info("lifecycle_on_completed", project_id=req.project_id, request_id=request_id)
    return APIResponse(code=0, message="ok", data={"project_id": req.project_id}, request_id=request_id)
