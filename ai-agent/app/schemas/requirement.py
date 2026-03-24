"""
开造 VibeBuild — 需求分析 Agent 输出模型
"""

from typing import Literal, Optional

from pydantic import BaseModel, Field


class EARSTask(BaseModel):
    """EARS 最小任务单元"""
    task_id: str = Field(description="任务编号，如 T-001")
    ears_type: Literal["ubiquitous", "event", "state", "optional", "unwanted"]
    ears_statement: str = Field(description="EARS 标准语句")
    module: str = Field(description="所属功能模块")
    role_tag: Literal["frontend", "backend", "fullstack", "design", "testing"]
    priority: int = Field(ge=1, le=5, description="优先级 1-5，1 最高")
    acceptance_criteria: list[str] = Field(description="验收标准列表")
    dependencies: list[str] = Field(default_factory=list, description="依赖的任务 ID")


class PRDDocument(BaseModel):
    """PRD 文档结构"""
    title: str
    summary: str
    target_users: list[dict] = Field(description="目标用户画像列表")
    feature_modules: list[dict] = Field(description="功能模块列表")
    tech_requirements: dict = Field(description="技术需求")
    non_functional_requirements: dict = Field(description="非功能性需求")


class ClarificationQuestion(BaseModel):
    """澄清问题"""
    question: str
    category: str = Field(description="问题类别：scope/user/tech/business/priority")
    options: Optional[list[str]] = None


class RequirementOutput(BaseModel):
    """需求分析 Agent 最终输出"""
    stage: str = Field(description="当前阶段：clarifying/prd_draft/prd_confirmed/tasks_ready")
    agent_message: str = Field(description="Agent 回复文本")
    completeness_score: int = Field(ge=0, le=100, description="需求完整度评分")
    clarification_questions: Optional[list[ClarificationQuestion]] = None
    prd: Optional[PRDDocument] = None
    ears_tasks: Optional[list[EARSTask]] = None
    document_path: Optional[str] = None
    markdown_preview: Optional[str] = None
