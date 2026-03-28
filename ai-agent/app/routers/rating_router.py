"""
开造 VibeBuild — 团队方评分定级 API 路由 (v2)

提供团队方（供给方）的 AI 能力评估、VibeBuild 等级定级、积分管理等功能。
支持简历文件上传（PDF / Word / Markdown）和纯文本两种方式。
"""

import json
import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, File, Form, Request, UploadFile
from sse_starlette.sse import EventSourceResponse

from app.agents.rating_agent import get_level_for_points, get_next_level
from app.db.repository import RatingRepository
from app.schemas.common import APIResponse
from app.schemas.rating import AdjustPointsRequest, EvaluateTextRequest
from app.utils.resume_parser import SUPPORTED_EXTENSIONS, parse_resume_file

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/rating", tags=["v2-团队方评分定级"])

rating_repo = RatingRepository()


# ============================================================
# 内部辅助
# ============================================================

async def _resolve_resume_text(
    resume_file: Optional[UploadFile],
    resume_text: Optional[str],
) -> str:
    """从文件或文本中提取简历内容，文件优先"""
    if resume_file and resume_file.filename:
        file_bytes = await resume_file.read()
        if not file_bytes:
            raise ValueError("上传的文件内容为空")
        return await parse_resume_file(
            file_bytes=file_bytes,
            filename=resume_file.filename,
            content_type=resume_file.content_type or "",
        )
    if resume_text and resume_text.strip():
        return resume_text.strip()
    raise ValueError("请上传简历文件（PDF/Word/Markdown）或填写简历文本")


def _build_profile_data(
    provider_id: str,
    provider_type: str,
    display_name: str,
    result: dict,
) -> dict:
    """从 Agent 评估结果构建 profile_data"""
    report = result.get("report", {})
    parsed = result.get("parsed_profile", {})
    scores = result.get("scores", {})
    vibe_power = report.get("vibe_power", result.get("vibe_power", 0))
    level = get_level_for_points(vibe_power)

    return {
        "id": provider_id,
        "user_id": provider_id,
        "type": provider_type,
        "display_name": display_name or parsed.get("display_name", ""),
        "vibe_power": vibe_power,
        "vibe_level": level["name"],
        "level_weight": level["weight"],
        "skills": parsed.get("skills"),
        "experience_years": parsed.get("experience_years", 0),
        "ai_tools": parsed.get("ai_tools"),
        "resume_summary": parsed.get("resume_summary", ""),
        "score_tech_depth": _extract_score(scores, "tech_depth"),
        "score_project_exp": _extract_score(scores, "project_exp"),
        "score_ai_proficiency": _extract_score(scores, "ai_proficiency"),
        "score_portfolio": _extract_score(scores, "portfolio"),
        "score_background": _extract_score(scores, "background"),
        "review_tags": result.get("review_tags") or parsed.get("review_tags"),
    }


def _extract_score(scores: dict, dimension: str) -> int:
    """从 scores dict 中提取维度分数"""
    val = scores.get(dimension, {})
    if isinstance(val, dict):
        return val.get("score", 0)
    return int(val) if val else 0


# ============================================================
# 内部通用评估逻辑
# ============================================================

async def _do_evaluate(
    request: Request,
    resume_text: str,
    provider_id: Optional[str],
    display_name: Optional[str],
    provider_type: str,
) -> APIResponse:
    """通用评估逻辑，供文件上传和纯文本接口共用"""
    from app.main import v2_rating_agent

    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    pid = provider_id or str(uuid.uuid4())[:12]

    updated_msgs, result = await v2_rating_agent.evaluate(
        provider_id=pid,
        resume_text=resume_text,
        eval_type="initial",
    )

    profile_data = _build_profile_data(pid, provider_type, display_name or "", result)
    report = result.get("report", {})
    vibe_power = profile_data["vibe_power"]
    level = get_level_for_points(vibe_power)

    try:
        await rating_repo.save_provider_profile(profile_data)
        await rating_repo.add_power_log(
            provider_id=pid,
            action="initial_evaluation",
            points=vibe_power,
            reason="AI 简历解析初始化定级",
        )
    except Exception as db_err:
        logger.warning("rating_db_save_skip", error=str(db_err))

    agent_text = v2_rating_agent.extract_text_response(updated_msgs)

    return APIResponse(
        code=0,
        message="success",
        data={
            "provider_id": pid,
            "agent_message": agent_text,
            "vibe_power": vibe_power,
            "vibe_level": level["name"],
            "level_icon": level["icon"],
            "level_weight": level["weight"],
            "report": report,
            "review_tags": result.get("review_tags") or result.get("parsed_profile", {}).get("review_tags"),
        },
        request_id=request_id,
    )


# ============================================================
# 1. AI 初始化定级 — 文件上传版（multipart/form-data）
# ============================================================

@router.post(
    "/evaluate/file",
    response_model=APIResponse,
    summary="AI 初始化定级 — 上传简历文件",
    description="""
## 上传简历文件进行 AI 评估定级

支持的文件格式：**PDF (.pdf)** / **Word (.docx)** / **Markdown (.md)** / **纯文本 (.txt)**

点击下方 **resume_file** 的 **Choose File** 按钮上传简历文件。
""",
)
async def evaluate_provider_file(
    request: Request,
    resume_file: UploadFile = File(
        ...,
        description="简历文件（支持 PDF / Word / Markdown / 纯文本）",
    ),
    provider_id: str = Form("", description="供给方 ID（留空自动生成）"),
    display_name: str = Form("", description="显示名称"),
    type: str = Form("individual", description="类型：individual（个人）/ team（团队）"),
):
    """上传简历文件（PDF/Word/Markdown/TXT）→ AI 五维度评分 → VibeBuild 等级定级"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        file_bytes = await resume_file.read()
        if not file_bytes:
            return APIResponse(code=40001, message="上传的文件内容为空", request_id=request_id)

        text = await parse_resume_file(
            file_bytes=file_bytes,
            filename=resume_file.filename or "unknown",
            content_type=resume_file.content_type or "",
        )

        return await _do_evaluate(
            request=request,
            resume_text=text,
            provider_id=provider_id or None,
            display_name=display_name or None,
            provider_type=type,
        )
    except ValueError as ve:
        return APIResponse(code=40001, message=str(ve), request_id=request_id)
    except Exception as e:
        logger.error("rating_evaluate_file_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"评估失败: {e}", request_id=request_id)


# ============================================================
# 2. AI 初始化定级 — 纯文本 JSON 版（方便测试）
# ============================================================

@router.post(
    "/evaluate/text",
    response_model=APIResponse,
    summary="AI 初始化定级 — 纯文本 JSON",
    description="""
## 通过 JSON 直接提交简历文本进行 AI 评估定级

适用于 Swagger 快速测试、Postman 调试、前端已完成文件解析后传文本等场景。

在下方 Request body 中填入 `resume_text` 字段即可。
""",
)
async def evaluate_provider_text(req: EvaluateTextRequest, request: Request):
    """纯文本 JSON 方式提交简历 → AI 评估定级"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        return await _do_evaluate(
            request=request,
            resume_text=req.resume_text,
            provider_id=req.provider_id,
            display_name=req.display_name,
            provider_type=req.type,
        )
    except Exception as e:
        logger.error("rating_evaluate_text_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"评估失败: {e}", request_id=request_id)


# ============================================================
# 3. AI 初始化定级 — SSE 流式（实时展示思考过程）
# ============================================================

@router.post(
    "/evaluate/stream/file",
    summary="AI 初始化定级 — 文件上传 + SSE 流式",
    description="""
## 上传简历文件，以 SSE 流式返回 AI 评估过程

前端可实时展示思考进度。支持 PDF / Word / Markdown / 纯文本 文件。
""",
)
async def evaluate_provider_stream_file(
    request: Request,
    resume_file: UploadFile = File(
        ...,
        description="简历文件（支持 PDF / Word / Markdown / 纯文本）",
    ),
    provider_id: str = Form("", description="供给方 ID（留空自动生成）"),
    display_name: str = Form("", description="显示名称"),
    type: str = Form("individual", description="类型：individual / team"),
):
    """[SSE 流式] 上传简历文件 → AI 实时解析 + 五维度评分 + 定级"""
    from app.main import v2_rating_agent

    pid = provider_id or str(uuid.uuid4())[:12]

    # 先同步读取文件内容（在生成器外部）
    file_bytes = await resume_file.read()
    filename = resume_file.filename or "unknown"
    content_type = resume_file.content_type or ""

    async def event_generator():
        try:
            try:
                text = await parse_resume_file(file_bytes, filename, content_type)
            except ValueError as ve:
                yield {"event": "error", "data": str(ve)}
                return

            yield {
                "event": "init",
                "data": json.dumps({"provider_id": pid}, ensure_ascii=False),
            }

            async for event in v2_rating_agent.evaluate_stream(
                provider_id=pid,
                resume_text=text,
                eval_type="initial",
            ):
                yield event

            # 持久化
            if hasattr(v2_rating_agent, "_report") and v2_rating_agent._report:
                result = {
                    "report": v2_rating_agent._report,
                    "parsed_profile": v2_rating_agent._parsed_profile,
                    "scores": v2_rating_agent._scores,
                    "vibe_power": v2_rating_agent._vibe_power,
                }
                profile_data = _build_profile_data(pid, type, display_name or "", result)

                try:
                    await rating_repo.save_provider_profile(profile_data)
                    await rating_repo.add_power_log(
                        provider_id=pid,
                        action="initial_evaluation",
                        points=profile_data["vibe_power"],
                        reason="AI 简历解析初始化定级",
                    )
                except Exception as db_err:
                    logger.warning("rating_stream_db_save_skip", error=str(db_err))

        except Exception as e:
            logger.error("rating_evaluate_stream_error", error=str(e))
            yield {"event": "error", "data": str(e)}

    return EventSourceResponse(event_generator())


@router.post(
    "/evaluate/stream/text",
    summary="AI 初始化定级 — 纯文本 + SSE 流式",
    description="""
## 提交简历文本，以 SSE 流式返回 AI 评估过程

前端可实时展示思考进度。
""",
)
async def evaluate_provider_stream_text(
    req: EvaluateTextRequest,
    request: Request,
):
    """[SSE 流式] 纯文本简历 → AI 实时解析 + 五维度评分 + 定级"""
    from app.main import v2_rating_agent

    pid = req.provider_id or str(uuid.uuid4())[:12]
    d_name = req.display_name or ""
    p_type = req.type

    async def event_generator():
        try:
            yield {
                "event": "init",
                "data": json.dumps({"provider_id": pid}, ensure_ascii=False),
            }

            async for event in v2_rating_agent.evaluate_stream(
                provider_id=pid,
                resume_text=req.resume_text,
                eval_type="initial",
            ):
                yield event

            if hasattr(v2_rating_agent, "_report") and v2_rating_agent._report:
                result = {
                    "report": v2_rating_agent._report,
                    "parsed_profile": v2_rating_agent._parsed_profile,
                    "scores": v2_rating_agent._scores,
                    "vibe_power": v2_rating_agent._vibe_power,
                }
                profile_data = _build_profile_data(pid, p_type, d_name, result)

                try:
                    await rating_repo.save_provider_profile(profile_data)
                    await rating_repo.add_power_log(
                        provider_id=pid,
                        action="initial_evaluation",
                        points=profile_data["vibe_power"],
                        reason="AI 简历解析初始化定级",
                    )
                except Exception as db_err:
                    logger.warning("rating_stream_db_save_skip", error=str(db_err))

        except Exception as e:
            logger.error("rating_evaluate_stream_text_error", error=str(e))
            yield {"event": "error", "data": str(e)}

    return EventSourceResponse(event_generator())


# ============================================================
# 4. 查看供给方档案
# ============================================================

@router.get(
    "/{provider_id}/profile",
    response_model=APIResponse,
    summary="查看团队方档案",
    description="""
获取指定团队方的完整档案信息，包括：
- VibePower 积分 & 当前等级
- 五维度评分详情
- 技能树 & AI 工具经验
- 项目统计数据
- 距离下一等级的积分差
""",
)
async def get_provider_profile(provider_id: str, request: Request):
    """根据 provider_id 查询团队方的档案详情和等级信息"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        profile = await rating_repo.get_provider_profile(provider_id)
        if not profile:
            return APIResponse(code=40401, message=f"供给方 {provider_id} 不存在", request_id=request_id)

        next_level = get_next_level(profile["vibe_power"])
        level_info = get_level_for_points(profile["vibe_power"], cap_at_t5=False)

        profile["level_icon"] = level_info["icon"]
        profile["next_level"] = next_level

        return APIResponse(code=0, data=profile, request_id=request_id)
    except Exception as e:
        logger.error("rating_get_profile_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"获取档案失败: {e}", request_id=request_id)


# ============================================================
# 5. 积分变动历史
# ============================================================

@router.get(
    "/{provider_id}/history",
    response_model=APIResponse,
    summary="查看积分变动历史",
    description="""
获取团队方的 VibePower 积分变动流水记录。

支持分页查询：
- `limit`: 每页条数（默认 50）
- `offset`: 偏移量（默认 0）
""",
)
async def get_power_history(
    provider_id: str,
    request: Request,
    limit: int = 50,
    offset: int = 0,
):
    """查询团队方积分变动记录，支持分页"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        logs = await rating_repo.get_power_logs(provider_id, limit=limit, offset=offset)
        return APIResponse(
            code=0,
            data={"provider_id": provider_id, "logs": logs, "count": len(logs)},
            request_id=request_id,
        )
    except Exception as e:
        logger.error("rating_get_history_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"获取历史失败: {e}", request_id=request_id)


# ============================================================
# 6. 积分调整（平台内部调用）
# ============================================================

@router.post(
    "/{provider_id}/adjust",
    response_model=APIResponse,
    summary="积分调整（平台内部）",
    description="""
根据团队方的平台行为进行积分加减，自动触发等级升降。

### 加分行为
| action | 积分 | 说明 |
|--------|------|------|
| `project_completed` | +30 ~ +100 | 完成项目交付 |
| `five_star_review` | +20 | 获得 5 星好评 |
| `on_time_delivery` | +15 | 准时交付 |
| `early_delivery` | +25 | 提前交付 |
| `weekly_active` | +10 | 连续活跃 |
| `repeat_client` | +30 | 需求方复购 |

### 扣分行为
| action | 积分 | 说明 |
|--------|------|------|
| `overdue` | -20 | 项目逾期 |
| `bad_review` | -30 | 1-2 星差评 |
| `project_abandoned` | -50 | 中途退出 |
| `inactivity_decay` | -5 | 不活跃衰减 |
| `complaint_upheld` | -40 | 投诉成立 |
""",
)
async def adjust_points(provider_id: str, req: AdjustPointsRequest, request: Request):
    """对团队方进行积分加减调整，自动计算等级变化"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])

    try:
        profile = await rating_repo.get_provider_profile(provider_id)
        if not profile:
            return APIResponse(code=40401, message=f"供给方 {provider_id} 不存在", request_id=request_id)

        old_power = profile["vibe_power"]
        new_power = max(0, old_power + req.points)
        new_level = get_level_for_points(new_power, cap_at_t5=False)

        await rating_repo.update_vibe_power(
            provider_id=provider_id,
            points_delta=req.points,
            new_level=new_level["name"],
            new_weight=new_level["weight"],
        )

        await rating_repo.add_power_log(
            provider_id=provider_id,
            action=req.action,
            points=req.points,
            reason=req.reason,
            project_id=req.project_id,
        )

        old_level = get_level_for_points(old_power, cap_at_t5=False)
        level_changed = old_level["name"] != new_level["name"]

        return APIResponse(
            code=0,
            data={
                "provider_id": provider_id,
                "old_power": old_power,
                "new_power": new_power,
                "points_delta": req.points,
                "old_level": old_level["name"],
                "new_level": new_level["name"],
                "level_changed": level_changed,
                "level_weight": new_level["weight"],
            },
            request_id=request_id,
        )
    except Exception as e:
        logger.error("rating_adjust_error", error=str(e), request_id=request_id)
        return APIResponse(code=50001, message=f"积分调整失败: {e}", request_id=request_id)
