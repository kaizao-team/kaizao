"""
开造 VibeBuild — 共享 Pydantic 模型
"""

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


class AgentStageStatus(BaseModel):
    """单个 Agent 阶段状态"""
    status: str = "pending"  # pending / running / awaiting_confirmation / confirmed / error
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None
    document_path: Optional[str] = None
    version: int = 1


class ProjectMeta(BaseModel):
    """项目元数据"""
    project_id: str
    title: str = ""
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    current_stage: str = "requirement"  # requirement / design / task / pm
    version: int = 1


class APIResponse(BaseModel):
    """统一 API 响应格式"""
    code: int = 0
    message: str = "success"
    data: Optional[Any] = None
    request_id: Optional[str] = None


class DocumentInfo(BaseModel):
    """文档信息"""
    filename: str
    path: str
    version: int
    stage: str
