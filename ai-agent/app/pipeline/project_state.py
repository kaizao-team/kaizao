"""
开造 VibeBuild — 项目状态模型
记录流水线中每个 Agent 阶段的状态
"""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


STAGES = ["requirement", "design", "task", "pm"]
STAGE_FILENAMES = {
    "requirement": "requirement.md",
    "design": "design.md",
    "task": "task.md",
    "pm": "project-plan.md",
}


class StageState(BaseModel):
    """单个阶段状态"""
    status: str = "pending"  # pending / running / awaiting_confirmation / confirmed / error
    sub_stage: Optional[str] = None  # requirement 特有：clarifying / prd_draft / prd_confirmed / tasks_ready
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    document_path: Optional[str] = None
    error_message: Optional[str] = None


class ProjectState(BaseModel):
    """项目全局状态"""
    project_id: str
    title: str = ""
    created_at: str = Field(default_factory=lambda: datetime.now().isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.now().isoformat())
    version: int = 1
    current_stage: str = "requirement"
    session_id: Optional[str] = None  # 当前活跃会话

    # 各阶段状态
    requirement: StageState = Field(default_factory=StageState)
    design: StageState = Field(default_factory=StageState)
    task: StageState = Field(default_factory=StageState)
    pm: StageState = Field(default_factory=StageState)

    def get_stage(self, stage_name: str) -> StageState:
        return getattr(self, stage_name)

    def set_stage_status(self, stage_name: str, status: str, **kwargs) -> None:
        stage = self.get_stage(stage_name)
        stage.status = status
        if status == "running" and not stage.started_at:
            stage.started_at = datetime.now().isoformat()
        if status in ("confirmed", "error"):
            stage.completed_at = datetime.now().isoformat()
        for k, v in kwargs.items():
            if hasattr(stage, k):
                setattr(stage, k, v)
        self.updated_at = datetime.now().isoformat()

    def can_start_stage(self, stage_name: str) -> tuple[bool, str]:
        """检查是否可以启动指定阶段"""
        idx = STAGES.index(stage_name)
        if idx == 0:
            return True, ""
        prev_stage = STAGES[idx - 1]
        prev_state = self.get_stage(prev_stage)
        if prev_state.status != "confirmed":
            return False, f"前置阶段 {prev_stage} 尚未确认（当前状态: {prev_state.status}）"
        return True, ""

    def advance_to_next_stage(self) -> Optional[str]:
        """推进到下一阶段，返回新阶段名或 None（已完成）"""
        idx = STAGES.index(self.current_stage)
        if idx + 1 >= len(STAGES):
            return None
        self.current_stage = STAGES[idx + 1]
        self.updated_at = datetime.now().isoformat()
        return self.current_stage

    def to_summary(self) -> dict:
        """返回状态摘要"""
        return {
            "project_id": self.project_id,
            "title": self.title,
            "current_stage": self.current_stage,
            "version": self.version,
            "stages": {
                s: {"status": self.get_stage(s).status, "sub_stage": self.get_stage(s).sub_stage}
                for s in STAGES
            },
        }
