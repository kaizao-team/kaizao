"""
开造 VibeBuild — 评分定级 API 请求/响应 Schema
"""

from typing import Optional

from pydantic import BaseModel, Field


class EvaluateTextRequest(BaseModel):
    """纯文本方式提交简历进行定级评估

    当不上传文件时，可通过此 JSON 请求体直接提交简历文本。
    """
    provider_id: Optional[str] = Field(None, description="供给方 ID，不传则自动生成")
    resume_text: str = Field(..., min_length=10, description="简历/履历纯文本内容（最少 10 个字符）")
    display_name: Optional[str] = Field(None, description="显示名称")
    type: str = Field(default="individual", pattern="^(individual|team)$", description="类型：individual（个人）/ team（团队）")


class AdjustPointsRequest(BaseModel):
    """积分调整请求

    平台内部调用，用于根据团队方的行为进行加分或扣分。
    """
    action: str = Field(
        ...,
        description="行为类型，如 project_completed / five_star_review / overdue / bad_review / project_abandoned 等",
        json_schema_extra={"examples": ["project_completed", "five_star_review", "overdue"]},
    )
    points: int = Field(..., description="积分变动值，正数加分，负数扣分")
    reason: str = Field(..., description="调整原因说明")
    project_id: Optional[str] = Field(None, description="关联的项目 ID（可选）")


class ProviderProfileResponse(BaseModel):
    """供给方档案响应"""
    id: str
    user_id: str
    type: str
    display_name: Optional[str]
    vibe_power: int
    vibe_level: str
    level_weight: float
    skills: Optional[list] = None
    experience_years: int
    ai_tools: Optional[list] = None
    resume_summary: Optional[str] = None
    review_tags: Optional[dict] = None
    score_tech_depth: int
    score_project_exp: int
    score_ai_proficiency: int
    score_portfolio: int
    score_background: int
    total_projects: int
    completed_projects: int
    avg_rating: float
    on_time_rate: float


class VibePowerLogResponse(BaseModel):
    """积分变动记录响应"""
    id: int
    provider_id: str
    action: str
    points: int
    reason: Optional[str]
    project_id: Optional[str]
    created_at: str
