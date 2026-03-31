"""
开造 VibeBuild — 项目管理 API 路由 (v2)

PM 方案由 lifecycle hook (on-matched) 自动生成，不再支持手动 start/confirm。
本路由只保留文档查询和重新生成能力。
"""

import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Request
from pydantic import BaseModel

from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/pm", tags=["v2-pm"])


class RegenerateRequest(BaseModel):
    agreed_price: Optional[float] = None
    agreed_days: Optional[int] = None
    feedback: Optional[str] = None


@router.get("/{project_id}/document", response_model=APIResponse)
async def get_document(project_id: str, request: Request):
    """获取项目管理文档（返回文件路径和内容）"""
    from app.main import v2_doc_writer
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    content = v2_doc_writer.read_document(project_id, "project-plan.md")
    if not content:
        return APIResponse(code=40402, message="文档尚未生成", request_id=request_id)
    path = v2_doc_writer.get_document_path(project_id, "project-plan.md")
    return APIResponse(code=0, data={"filename": "project-plan.md", "path": path, "size": len(content), "content": content}, request_id=request_id)


@router.post("/{project_id}/regenerate", response_model=APIResponse)
async def regenerate_pm(project_id: str, req: RegenerateRequest, request: Request):
    """
    重新生成 PM 方案。

    用于项目执行期间工期/价格调整后重新生成里程碑计划。
    需要 pm 阶段已生成过文档（即 on-matched 已执行过）。
    """
    from app.main import v2_orchestrator, v2_doc_writer

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    if not v2_orchestrator:
        return APIResponse(code=50001, message="流水线编排器未初始化", request_id=request_id)

    state = await v2_orchestrator.get_project(project_id)
    if not state:
        return APIResponse(code=40401, message=f"项目 {project_id} 不存在", request_id=request_id)

    pm_stage = state.get_stage("pm")
    if pm_stage.status not in ("confirmed", "error"):
        return APIResponse(
            code=40001,
            message=f"PM 方案尚未生成过（当前状态: {pm_stage.status}），请等待撮合完成后自动生成",
            request_id=request_id,
        )

    # 读取现有匹配信息或使用请求中的新值
    # 如果没有提供新值，使用默认占位（regenerate 时至少要有 price 和 days）
    agreed_price = req.agreed_price
    agreed_days = req.agreed_days

    if agreed_price is None or agreed_days is None:
        return APIResponse(
            code=40002,
            message="重新生成 PM 方案需要提供 agreed_price 和 agreed_days",
            request_id=request_id,
        )

    try:
        ok, msg, data = await v2_orchestrator.generate_pm(
            project_id=project_id,
            agreed_price=agreed_price,
            agreed_days=agreed_days,
        )

        if not ok:
            return APIResponse(code=40001, message=msg, request_id=request_id)

        return APIResponse(code=0, message="PM 方案已重新生成", data=data, request_id=request_id)

    except Exception as e:
        logger.error("pm_regenerate_error", error=str(e), request_id=request_id)
        return APIResponse(code=50004, message=f"PM 方案重新生成失败: {e}", request_id=request_id)
