"""
开造 VibeBuild — 项目管理 Agent 输出模型
"""

from typing import Literal, Optional

from pydantic import BaseModel, Field


class Milestone(BaseModel):
    """里程碑"""
    name: str
    target_day: int = Field(description="距项目启动的天数")
    deliverables: list[str]
    quality_gate: list[str] = Field(description="验收标准")


class Risk(BaseModel):
    """风险"""
    risk_id: str
    description: str
    probability: Literal["low", "medium", "high"]
    impact: Literal["low", "medium", "high"]
    mitigation: str
    contingency: str
    owner: str


class ProjectPlan(BaseModel):
    """项目管理方案"""
    executive_summary: str
    milestones: list[Milestone]
    critical_path: list[str] = Field(description="关键路径任务 ID 链")
    critical_path_duration_days: int
    risk_register: list[Risk]
    resource_plan: list[dict] = Field(description="资源配置")
    quality_gates: list[dict] = Field(description="质量检查点")
    acceptance_criteria: list[str]
    communication_plan: dict
    change_management: str
    tracking_framework: dict
    vibe_timeline_days: int
    traditional_timeline_days: int
    recommended_approach: str


class PMOutput(BaseModel):
    """项目管理 Agent 输出"""
    agent_message: str
    project_plan: ProjectPlan
    markdown_preview: str
    document_path: Optional[str] = None
