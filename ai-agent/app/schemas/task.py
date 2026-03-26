"""
开造 VibeBuild — 任务文档 Agent 输出模型
"""

from typing import Literal, Optional

from pydantic import BaseModel, Field


class TaskUnit(BaseModel):
    """任务单元"""
    task_id: str
    title: str
    description: str
    module: str
    ears_reference: Optional[str] = None
    is_critical: bool = False
    risk_level: Literal["low", "medium", "high"] = "low"
    risk_description: Optional[str] = None
    vibe_coding_hours: float = Field(description="AI 辅助开发预估工时")
    traditional_hours: float = Field(description="传统开发预估工时")
    dependencies: list[str] = Field(default_factory=list)
    acceptance_criteria: list[str] = Field(default_factory=list)


class TaskDocument(BaseModel):
    """任务文档"""
    modules: list[dict] = Field(description="按功能模块分组的任务")
    total_tasks: int
    critical_tasks: list[str] = Field(description="关键任务 ID 列表")
    risk_tasks: list[dict] = Field(description="风险任务及说明")
    total_vibe_hours: float
    total_traditional_hours: float
    total_vibe_days: float
    total_traditional_days: float
    speedup_ratio: float = Field(description="加速比")


class TaskOutput(BaseModel):
    """任务文档 Agent 输出"""
    agent_message: str
    task_document: TaskDocument
    markdown_preview: str
    document_path: Optional[str] = None
