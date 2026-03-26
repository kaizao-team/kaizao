"""
开造 VibeBuild — 全局配置
使用 Pydantic Settings 管理环境变量和配置项
"""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional


class Settings(BaseSettings):
    """应用全局配置，从环境变量或 .env 文件加载"""

    # 服务基础配置
    app_name: str = "vibebuild-ai-agent"
    app_version: str = "1.0.0"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 39528
    log_level: str = "INFO"

    # Claude API 配置（主选 LLM）
    anthropic_api_key: str = Field(default="", description="Anthropic API Key")
    claude_sonnet_model: str = "claude-sonnet-4-20250514"
    claude_haiku_model: str = "claude-haiku-4-20250514"
    claude_max_tokens: int = 8192
    claude_timeout: int = 30

    # 智谱 GLM API 配置（支持 tool use）
    zhipu_api_key: str = Field(default="", description="智谱 API Key")
    zhipu_model: str = "GLM-4-FlashX"

    # 通义千问 API 配置（备选 LLM / 国内合规）
    dashscope_api_key: str = Field(default="", description="阿里云 DashScope API Key")
    qwen_max_model: str = "qwen-max"
    qwen_turbo_model: str = "qwen-turbo"

    # Embedding 配置
    embedding_provider: str = Field(
        default="dashscope", description="embedding 供应商: dashscope / local"
    )
    dashscope_embedding_model: str = "text-embedding-v3"
    local_embedding_model_path: str = "BAAI/bge-m3"
    embedding_dimension: int = 768

    # Milvus 向量数据库配置
    milvus_host: str = "localhost"
    milvus_port: int = 19530
    milvus_provider_collection: str = "provider_profiles"
    milvus_demand_collection: str = "demand_requirements"
    milvus_knowledge_collection: str = "project_knowledge"

    # Elasticsearch 配置
    elasticsearch_url: str = "http://localhost:9200"
    elasticsearch_username: Optional[str] = None
    elasticsearch_password: Optional[str] = None

    # Redis 配置
    redis_url: str = "redis://localhost:6379/0"
    redis_session_ttl: int = 86400  # 会话过期时间 24 小时

    # MySQL 配置
    mysql_url: str = "mysql+aiomysql://root:root@localhost:3306/vibebuild?charset=utf8mb4"

    # Agent 配置
    max_conversation_turns: int = 20
    max_context_tokens: int = 8000
    summary_threshold_turns: int = 10
    completeness_threshold: int = 80

    # v2 Pipeline 配置
    output_dir: str = "outputs"
    project_state_ttl: int = 604800   # 7 天
    session_history_ttl: int = 86400  # 24 小时
    max_agentic_loop_iterations: int = 10

    # 匹配配置
    match_top_k: int = 10
    match_min_score: float = 50.0
    match_cold_start_threshold: int = 100
    newbie_boost_days: int = 30
    newbie_boost_factor: float = 1.5

    # RAG 配置
    rag_top_k: int = 5
    rag_vector_top_n: int = 20
    rag_keyword_top_n: int = 20
    rag_rrf_k: int = 60
    rag_chunk_size: int = 512
    rag_chunk_overlap: int = 64

    # 安全配置
    max_input_length: int = 5000
    special_char_ratio_threshold: float = 0.15
    injection_length_threshold: int = 3000

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


# 全局配置单例
settings = Settings()
