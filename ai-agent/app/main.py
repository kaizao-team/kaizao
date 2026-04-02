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
from typing import Optional, Any

from app.config import settings

logger = structlog.get_logger()

# 全局组件实例（延迟初始化）
llm_router: Optional[Any] = None
embedding_client: Optional[Any] = None
milvus_store: Optional[Any] = None
retriever: Optional[Any] = None
smart_matcher: Optional[Any] = None
chat_assistant: Optional[Any] = None

# v2 全局组件实例
v2_session: Optional[Any] = None
v2_doc_writer: Optional[Any] = None
v2_minio_store: Optional[Any] = None
v2_orchestrator: Optional[Any] = None
v2_requirement_agent: Optional[Any] = None
v2_design_agent: Optional[Any] = None
v2_task_agent: Optional[Any] = None
v2_pm_agent: Optional[Any] = None
v2_rating_agent: Optional[Any] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理：启动时初始化组件，关闭时释放资源"""
    global llm_router, embedding_client, milvus_store, retriever
    global smart_matcher, chat_assistant
    global v2_session, v2_doc_writer, v2_minio_store, v2_orchestrator
    global v2_requirement_agent, v2_design_agent, v2_task_agent, v2_pm_agent, v2_rating_agent

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

    # ---- 智能匹配 + 对话助手 Agent 初始化 ----
    try:
        from app.agents.smart_matcher import SmartMatcherAgent
        from app.agents.chat_assistant import ChatAssistantAgent

        if llm_router:
            smart_matcher = SmartMatcherAgent(
                llm_router=llm_router,
                embedding_client=embedding_client,
                milvus_store=milvus_store,
                retriever=retriever,
            )
            chat_assistant = ChatAssistantAgent(
                llm_router=llm_router,
            )
            logger.info("智能匹配 + 对话助手 Agent 初始化完成")
    except Exception as e:
        logger.warning(f"匹配/对话 Agent 初始化跳过: {e}")

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
        from app.storage.minio_client import MinioDocStore
        v2_minio_store = MinioDocStore()
        v2_minio_store.connect()
        logger.info("Minio 文档存储连接成功")
    except Exception as e:
        logger.warning(f"Minio 连接跳过（文档仅写入本地）: {e}")
        v2_minio_store = None

    try:
        from app.outputs.writer import DocumentWriter
        v2_doc_writer = DocumentWriter(minio_store=v2_minio_store)
        logger.info("v2 文档写入器初始化完成", minio="enabled" if v2_minio_store else "disabled")
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

    # ---- Rating Agent 初始化 ----
    try:
        from app.agents.rating_agent import RatingAgent

        if llm_router:
            v2_rating_agent = RatingAgent(llm_router=llm_router)
            logger.info("v2 Rating Agent 初始化完成")
    except Exception as e:
        logger.warning(f"v2 Rating Agent 初始化跳过: {e}")

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
    description="开造平台 AI Agent 微服务 — 项目流水线 / 智能匹配 / 对话助手 / 团队方评级",
    version=settings.app_version,
    lifespan=lifespan,
)

# 注册 v2 路由
from app.routers import (
    requirement_router,
    design_router,
    task_router,
    pm_router,
    pipeline_router,
    rating_router,
    match_router,
    chat_router,
    lifecycle_router,
    ears_router,
)
app.include_router(requirement_router.router)
app.include_router(design_router.router)
app.include_router(task_router.router)
app.include_router(pm_router.router)
app.include_router(pipeline_router.router)
app.include_router(rating_router.router)
app.include_router(match_router.router)
app.include_router(chat_router.router)
app.include_router(lifecycle_router.router)
app.include_router(ears_router.router)

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


# ---------- 路由 ----------

@app.get("/health")
async def health_check():
    """健康检查端点"""
    return {
        "status": "healthy",
        "service": settings.app_name,
        "version": settings.app_version,
    }


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
