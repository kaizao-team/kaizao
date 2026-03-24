"""
开造 VibeBuild — 架构设计 Agent 输出模型
"""

from typing import Optional

from pydantic import BaseModel, Field


class APIEndpoint(BaseModel):
    """API 接口定义"""
    method: str = Field(description="HTTP 方法")
    path: str = Field(description="接口路径")
    description: str
    request_body: Optional[dict] = None
    response_body: dict


class DataModel(BaseModel):
    """数据模型定义"""
    entity_name: str
    fields: list[dict] = Field(description="字段列表 [{name, type, description, required}]")
    relationships: list[str] = Field(default_factory=list, description="关联关系描述")


class DesignDocument(BaseModel):
    """架构设计文档"""
    system_architecture: dict = Field(description="技术栈、部署拓扑、架构概述")
    frontend_modules: list[dict] = Field(description="前端功能模块定义")
    backend_modules: list[dict] = Field(description="后端服务模块定义")
    api_design: list[APIEndpoint] = Field(description="API 接口设计")
    data_models: list[DataModel] = Field(description="数据模型设计")
    non_functional: dict = Field(description="性能、安全、可扩展性")
    tech_decisions: list[dict] = Field(description="关键技术决策及理由")


class DesignOutput(BaseModel):
    """架构设计 Agent 输出"""
    agent_message: str
    design: DesignDocument
    markdown_preview: str = Field(description="Markdown 格式预览")
    document_path: Optional[str] = None
