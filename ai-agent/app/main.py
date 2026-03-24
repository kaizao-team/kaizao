"""
开造 VibeBuild — FastAPI 应用入口
提供 AI Agent 的 HTTP API 接口
"""

import time
import uuid
from contextlib import asynccontextmanager

import structlog
import uvicorn
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any, List

from app.config import settings

logger = structlog.get_logger()

# v1 全局组件实例（延迟初始化，类型为 Any）
llm_router: Optional[Any] = None
embedding_client: Optional[Any] = None
milvus_store: Optional[Any] = None
retriever: Optional[Any] = None
project_analyzer: Optional[Any] = None
smart_matcher: Optional[Any] = None
chat_assistant: Optional[Any] = None

# v2 全局组件实例
v2_session: Optional[Any] = None
v2_doc_writer: Optional[Any] = None
v2_orchestrator: Optional[Any] = None
v2_requirement_agent: Optional[Any] = None
v2_design_agent: Optional[Any] = None
v2_task_agent: Optional[Any] = None
v2_pm_agent: Optional[Any] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理：启动时初始化组件，关闭时释放资源"""
    global llm_router, embedding_client, milvus_store, retriever
    global project_analyzer, smart_matcher, chat_assistant
    global v2_session, v2_doc_writer, v2_orchestrator
    global v2_requirement_agent, v2_design_agent, v2_task_agent, v2_pm_agent

    logger.info("正在启动 VibeBuild AI Agent 服务...")

    try:
        from app.llm.router import LLMRouter
        llm_router = LLMRouter()
        logger.info("LLM 路由初始化完成")
    except Exception as e:
        logger.warning(f"LLM 路由初始化跳过: {e}")
        llm_router = None

    try:
        from app.vectorizer.embedding_client import EmbeddingClient
        embedding_client = EmbeddingClient()
        logger.info("Embedding 客户端初始化完成")
    except Exception as e:
        logger.warning(f"Embedding 客户端初始化跳过: {e}")
        embedding_client = None

    try:
        from app.storage.milvus_store import MilvusStore
        milvus_store = MilvusStore()
        milvus_store.connect()
        logger.info("Milvus 存储连接成功")
    except Exception as e:
        logger.warning(f"Milvus 连接跳过（开发模式可忽略）: {e}")
        milvus_store = None

    try:
        from app.rag.retriever import HybridRetriever
        if milvus_store and embedding_client:
            retriever = HybridRetriever(
                milvus_store=milvus_store,
                embedding_client=embedding_client,
            )
            logger.info("RAG 检索器初始化完成")
        else:
            retriever = None
    except Exception as e:
        logger.warning(f"RAG 检索器初始化跳过: {e}")
        retriever = None

    try:
        from app.agents.project_analyzer import ProjectAnalyzerAgent
        from app.agents.smart_matcher import SmartMatcherAgent
        from app.agents.chat_assistant import ChatAssistantAgent

        if llm_router:
            project_analyzer = ProjectAnalyzerAgent(
                llm_router=llm_router,
                retriever=retriever,
            )
            smart_matcher = SmartMatcherAgent(
                llm_router=llm_router,
                embedding_client=embedding_client,
                milvus_store=milvus_store,
                retriever=retriever,
            )
            chat_assistant = ChatAssistantAgent(
                llm_router=llm_router,
            )
            logger.info("三个核心 Agent 初始化完成")
    except Exception as e:
        logger.warning(f"Agent 初始化跳过: {e}")

    # ---- MySQL 持久化层初始化 ----
    try:
        from app.db.engine import init_db
        await init_db(auto_create_tables=settings.debug)
        logger.info("MySQL 持久化层初始化完成", auto_create_tables=settings.debug)
    except Exception as e:
        logger.warning(f"MySQL 初始化跳过（将仅使用 Redis/内存）: {e}")

    # ---- v2 组件初始化 ----
    try:
        from app.session.manager import SessionManager
        v2_session = SessionManager()
        await v2_session.connect()
        logger.info("v2 异步 Redis 会话管理器初始化完成")
    except Exception as e:
        logger.warning(f"v2 Redis 会话管理器初始化跳过: {e}")
        v2_session = None

    try:
        from app.outputs.writer import DocumentWriter
        v2_doc_writer = DocumentWriter()
        logger.info("v2 文档写入器初始化完成")
    except Exception as e:
        logger.warning(f"v2 文档写入器初始化跳过: {e}")
        v2_doc_writer = None

    try:
        from app.pipeline.orchestrator import PipelineOrchestrator
        if v2_session and v2_doc_writer:
            v2_orchestrator = PipelineOrchestrator(
                session_manager=v2_session,
                doc_writer=v2_doc_writer,
            )
            logger.info("v2 流水线编排器初始化完成")
    except Exception as e:
        logger.warning(f"v2 流水线编排器初始化跳过: {e}")

    try:
        from app.agents.requirement_agent import RequirementAgent
        from app.agents.design_agent import DesignAgent
        from app.agents.task_agent import TaskAgent
        from app.agents.pm_agent import PMAgent

        if llm_router and v2_doc_writer:
            v2_requirement_agent = RequirementAgent(llm_router=llm_router, doc_writer=v2_doc_writer)
            v2_design_agent = DesignAgent(llm_router=llm_router, doc_writer=v2_doc_writer)
            v2_task_agent = TaskAgent(llm_router=llm_router, doc_writer=v2_doc_writer)
            v2_pm_agent = PMAgent(llm_router=llm_router, doc_writer=v2_doc_writer)
            logger.info("v2 四个文档型 Agent 初始化完成")
    except Exception as e:
        logger.warning(f"v2 Agent 初始化跳过: {e}")

    logger.info(
        "VibeBuild AI Agent 服务启动成功",
        host=settings.host,
        port=settings.port,
    )

    yield

    # 关闭资源
    if v2_session:
        await v2_session.disconnect()
    if milvus_store:
        milvus_store.disconnect()
    try:
        from app.db.engine import close_db
        await close_db()
    except Exception:
        pass
    logger.info("VibeBuild AI Agent 服务已关闭")


app = FastAPI(
    title="VibeBuild AI Agent Service",
    description="开造平台 AI Agent 微服务 — 需求分析 / 智能匹配 / 对话助手",
    version=settings.app_version,
    lifespan=lifespan,
)

# 注册 v2 路由
from app.routers import requirement_router, design_router, task_router, pm_router, pipeline_router
app.include_router(requirement_router.router)
app.include_router(design_router.router)
app.include_router(task_router.router)
app.include_router(pm_router.router)
app.include_router(pipeline_router.router)

# CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- 中间件 ----------

@app.middleware("http")
async def request_middleware(request: Request, call_next):
    """统一请求中间件：注入 request_id、计算耗时、结构化日志"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    start_time = time.time()

    response: Response = await call_next(request)

    duration_ms = round((time.time() - start_time) * 1000, 2)
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Duration-Ms"] = str(duration_ms)

    logger.info(
        "request_completed",
        request_id=request_id,
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        duration_ms=duration_ms,
    )
    return response


# ---------- 请求/响应模型 ----------

class AgentRequest(BaseModel):
    """Agent 通用请求体"""
    session_id: str
    user_id: str
    message: Dict[str, Any]
    context: Optional[Dict[str, Any]] = None


class MatchRequest(BaseModel):
    """匹配请求体"""
    demand_id: str
    match_type: str = "recommend_providers"
    user_id: Optional[str] = None
    filters: Optional[Dict[str, Any]] = None
    pagination: Optional[Dict[str, int]] = None


class ChatRequest(BaseModel):
    """对话请求体"""
    session_id: str
    user_id: str
    user_role: Optional[str] = "unknown"
    message: Dict[str, Any]
    page_context: Optional[Dict[str, Any]] = None


class APIResponse(BaseModel):
    """统一 API 响应格式"""
    code: int = 0
    message: str = "success"
    data: Optional[Any] = None
    request_id: Optional[str] = None


# ---------- 路由 ----------

@app.get("/health")
async def health_check():
    """健康检查端点"""
    return {
        "status": "healthy",
        "service": settings.app_name,
        "version": settings.app_version,
    }


@app.post("/api/v1/agent/analyze", response_model=APIResponse)
async def analyze_requirement(req: AgentRequest, request: Request):
    """需求分析 Agent 接口 — 多轮对话生成 PRD + EARS 卡片"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
    try:
        result = await project_analyzer.process(
            session_id=req.session_id,
            user_id=req.user_id,
            message=req.message,
            context=req.context,
        )
        return APIResponse(code=0, message="success", data=result, request_id=request_id)
    except Exception as e:
        logger.error("analyze_requirement_error", error=str(e), request_id=request_id)
        return APIResponse(
            code=50001, message=f"AI 分析服务异常: {str(e)}", request_id=request_id
        )


@app.post("/api/v1/agent/match", response_model=APIResponse)
async def smart_match(req: MatchRequest, request: Request):
    """智能匹配 Agent 接口 — 为需求推荐供给方"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
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
            code=50002, message=f"AI 匹配服务异常: {str(e)}", request_id=request_id
        )


@app.post("/api/v1/agent/chat", response_model=APIResponse)
async def chat(req: ChatRequest, request: Request):
    """对话助手 Agent 接口 — 意图识别 + 多轮对话"""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:16])
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
            code=50003, message=f"AI 对话服务异常: {str(e)}", request_id=request_id
        )


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
