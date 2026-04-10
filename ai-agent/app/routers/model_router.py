"""
开造 VibeBuild — AI 模型配置路由

管理端通过此接口查询 / 切换当前激活的 LLM 模型。
激活模型存储在 Redis key `llm:active_provider`，无 key 时默认 openai_gpt。
"""

import structlog
from fastapi import APIRouter
from pydantic import BaseModel

from app.config import settings
from app.schemas.common import APIResponse

logger = structlog.get_logger()

router = APIRouter(prefix="/api/v2/models", tags=["model-config"])

REDIS_KEY = "llm:active_provider"
DEFAULT_PROVIDER = "openai_gpt"

AVAILABLE_PROVIDERS = [
    {
        "id": "openai_gpt",
        "name": "GPT-5.4",
        "description": "OpenAI GPT-5.4 via codex-for.me proxy",
        "available": bool(settings.openai_api_key),
    },
    {
        "id": "zhipu",
        "name": "智谱 GLM-5.1",
        "description": "智谱大模型",
        "available": bool(settings.zhipu_api_key),
    },
    {
        "id": "claude",
        "name": "Claude Sonnet",
        "description": "Anthropic Claude",
        "available": bool(settings.anthropic_api_key),
    },
    {
        "id": "dashscope",
        "name": "通义千问",
        "description": "阿里云 DashScope Qwen",
        "available": bool(settings.dashscope_api_key),
    },
]


async def _get_redis():
    """获取全局 SessionManager 的 Redis 连接"""
    from app.main import v2_session
    if v2_session and v2_session._redis:
        return v2_session._redis
    return None


async def _get_active_provider() -> str:
    rdb = await _get_redis()
    if rdb:
        try:
            val = await rdb.get(REDIS_KEY)
            if val:
                return val
        except Exception as e:
            logger.warning("读取 active_provider 失败", error=str(e))
    return DEFAULT_PROVIDER


class UpdateModelConfigRequest(BaseModel):
    provider: str


@router.get("/config")
async def get_model_config():
    active = await _get_active_provider()
    return APIResponse(
        code=0,
        message="success",
        data={
            "active_provider": active,
            "providers": AVAILABLE_PROVIDERS,
        },
    )


@router.put("/config")
async def update_model_config(req: UpdateModelConfigRequest):
    valid_ids = {p["id"] for p in AVAILABLE_PROVIDERS}
    if req.provider not in valid_ids:
        return APIResponse(code=400, message=f"不支持的 provider: {req.provider}", data=None)

    rdb = await _get_redis()
    if not rdb:
        return APIResponse(code=500, message="Redis 不可用，无法切换模型", data=None)

    try:
        await rdb.set(REDIS_KEY, req.provider)
        logger.info("切换 LLM 模型", provider=req.provider)
        return APIResponse(
            code=0,
            message="success",
            data={"active_provider": req.provider},
        )
    except Exception as e:
        logger.error("写入 active_provider 失败", error=str(e))
        return APIResponse(code=500, message="切换失败", data=None)
