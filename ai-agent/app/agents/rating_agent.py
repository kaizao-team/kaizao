"""
开造 VibeBuild — 团队/个人评分定级 Agent
通过 AI 解析简历，进行五维度评分和 VibeBuild 等级定级
vc-T 序列 10 级体系
"""

import json
from typing import Any, Optional

import structlog

from app.agents.base_agent import ToolUseBaseAgent
from app.llm.router import LLMRouter
from app.safety.injection_defender import PromptInjectionDefender
from app.prompts.rating_prompts import RATING_CONTEXT_TEMPLATE, RATING_SYSTEM_PROMPT
from app.tools.rating_tools import (
    EVALUATE_SKILLS_TOOL,
    GENERATE_REPORT_TOOL,
    PARSE_RESUME_TOOL,
)

logger = structlog.get_logger()

# vc-T 序列 10 级等级映射表
VIBE_LEVELS = [
    {"name": "vc-T1",  "icon": "🌟", "min": 0,    "max": 99,     "weight": 1.00},
    {"name": "vc-T2",  "icon": "🚀", "min": 100,  "max": 199,    "weight": 1.05},
    {"name": "vc-T3",  "icon": "💪", "min": 200,  "max": 349,    "weight": 1.10},
    {"name": "vc-T4",  "icon": "🔥", "min": 350,  "max": 549,    "weight": 1.20},
    {"name": "vc-T5",  "icon": "⭐", "min": 550,  "max": 749,    "weight": 1.35},
    {"name": "vc-T6",  "icon": "💎", "min": 750,  "max": 949,    "weight": 1.50},
    {"name": "vc-T7",  "icon": "🏆", "min": 950,  "max": 1199,   "weight": 1.70},
    {"name": "vc-T8",  "icon": "👑", "min": 1200, "max": 1499,   "weight": 1.90},
    {"name": "vc-T9",  "icon": "🌍", "min": 1500, "max": 1899,   "weight": 2.20},
    {"name": "vc-T10", "icon": "🏛️", "min": 1900, "max": 999999, "weight": 2.50},
]

# 维度权重（×7.5 满分 750）
DIMENSION_WEIGHTS = {
    "tech_depth": 2.25,       # 30% × 7.5 → 满分 225
    "project_exp": 1.875,     # 25% × 7.5 → 满分 187.5
    "ai_proficiency": 1.5,    # 20% × 7.5 → 满分 150
    "portfolio": 1.125,       # 15% × 7.5 → 满分 112.5
    "background": 0.75,       # 10% × 7.5 → 满分 75
}


def calculate_vibe_power(scores: dict) -> int:
    """根据五维度分数计算 VibePower 总积分（满分 750，cap 749）"""
    total = 0.0
    for dim, weight in DIMENSION_WEIGHTS.items():
        dim_score = scores.get(dim, {})
        raw = dim_score.get("score", 0) if isinstance(dim_score, dict) else int(dim_score)
        total += raw * weight
    return min(round(total), 749)


def get_level_for_points(points: int, cap_at_t5: bool = True) -> dict:
    """根据积分返回等级信息，初始化定级最高 vc-T5"""
    effective_max = 749 if cap_at_t5 else 999999
    capped = min(points, effective_max)

    for level in VIBE_LEVELS:
        if level["min"] <= capped <= level["max"]:
            return level
    return VIBE_LEVELS[0]


def get_next_level(current_points: int) -> Optional[dict]:
    """获取下一等级信息"""
    for level in VIBE_LEVELS:
        if level["min"] > current_points:
            return {
                "level": level["name"],
                "points_needed": level["min"] - current_points,
                "min_points": level["min"],
            }
    return None


class RatingAgent(ToolUseBaseAgent):
    """
    团队/个人评分定级 Agent

    流程：解析简历 → 五维度评分 → 生成报告
    """

    agent_name = "rating"
    model_tier = "high"

    # 工具名称中文映射（覆盖基类，供 SSE 进度展示）
    TOOL_DISPLAY_NAMES = {
        "parse_resume": "正在解析简历信息...",
        "evaluate_skills": "正在进行五维度能力评估...",
        "generate_report": "正在生成评估报告...",
    }

    # 简历文本专用的安全检测器
    _resume_defender = PromptInjectionDefender()

    def __init__(self, llm_router: LLMRouter):
        super().__init__(llm_router)
        # 运行时上下文
        self._provider_id: str = ""
        self._parsed_profile: dict = {}
        self._scores: dict = {}
        self._vibe_power: int = 0
        self._report: dict = {}
        self._review_tags: dict = {}

    def _check_safety(self, user_input: str) -> dict:
        """
        覆盖基类安全检查：简历文本天然很长，跳过长度和特殊字符检测，
        只保留关键词注入检测。
        """
        if not user_input:
            return {"is_safe": True, "risk_level": "none", "detection_method": "none", "matched_pattern": ""}

        # 只做 Layer 1: 关键词检测
        for i, pattern in enumerate(self._resume_defender.COMPILED_PATTERNS):
            match = pattern.search(user_input)
            if match:
                return {
                    "is_safe": False,
                    "risk_level": "high",
                    "detection_method": "keyword",
                    "matched_pattern": self._resume_defender.INJECTION_PATTERNS[i],
                }

        return {"is_safe": True, "risk_level": "none", "detection_method": "none", "matched_pattern": ""}

    def _get_tools(self) -> list[dict]:
        return [
            PARSE_RESUME_TOOL,
            EVALUATE_SKILLS_TOOL,
            GENERATE_REPORT_TOOL,
        ]

    def _get_system_prompt(self, **context) -> str:
        additional = context.get("additional_context", "")
        ctx = RATING_CONTEXT_TEMPLATE.format(
            provider_id=self._provider_id,
            eval_type=context.get("eval_type", "initial"),
            additional_context=additional,
        )
        return RATING_SYSTEM_PROMPT + "\n\n" + ctx

    async def _execute_tool(self, tool_name: str, tool_input: dict) -> str:
        if tool_name == "parse_resume":
            self._parsed_profile = tool_input.get("parsed_profile", {})
            self._review_tags = self._parsed_profile.get("review_tags", {})
            return json.dumps({
                "status": "ok",
                "message": "简历解析完成，已提取结构化信息。",
                "profile_summary": self._parsed_profile.get("resume_summary", ""),
                "skills_count": len(self._parsed_profile.get("skills", [])),
                "projects_count": len(self._parsed_profile.get("projects", [])),
                "ai_tools_count": len(self._parsed_profile.get("ai_tools", [])),
                "review_tags_extracted": bool(self._review_tags),
            }, ensure_ascii=False)

        elif tool_name == "evaluate_skills":
            self._scores = tool_input.get("scores", {})
            self._vibe_power = tool_input.get("vibe_power", 0)
            # 校验 vibe_power 计算
            recalc = calculate_vibe_power(self._scores)
            if abs(recalc - self._vibe_power) > 20:
                self._vibe_power = recalc
            level = get_level_for_points(self._vibe_power)
            return json.dumps({
                "status": "ok",
                "message": "五维度评分完成。",
                "vibe_power": self._vibe_power,
                "vibe_level": level["name"],
                "level_icon": level["icon"],
                "level_weight": level["weight"],
            }, ensure_ascii=False)

        elif tool_name == "generate_report":
            self._report = tool_input.get("report", {})
            return json.dumps({
                "status": "ok",
                "message": "评估报告已生成。",
                "vibe_level": self._report.get("vibe_level", "vc-T1"),
                "vibe_power": self._report.get("vibe_power", 0),
            }, ensure_ascii=False)

        return f"未知工具: {tool_name}"

    async def evaluate(
        self,
        provider_id: str,
        resume_text: str,
        eval_type: str = "initial",
    ) -> tuple[list[dict], dict[str, Any]]:
        """
        执行一次完整评估

        Returns:
            (updated_messages, result_data)
        """
        self._provider_id = provider_id
        self._parsed_profile = {}
        self._scores = {}
        self._vibe_power = 0
        self._report = {}
        self._review_tags = {}

        messages = [{"role": "user", "content": f"请评估以下团队方的简历并进行 VibeBuild 定级：\n\n{resume_text}"}]

        updated_messages, last_tool = await self.run(
            messages=messages,
            max_tokens=8192,
            eval_type=eval_type,
        )

        result = {
            "provider_id": provider_id,
            "parsed_profile": self._parsed_profile,
            "scores": self._scores,
            "vibe_power": self._vibe_power,
            "report": self._report,
            "review_tags": self._review_tags,
        }

        return updated_messages, result

    async def evaluate_stream(
        self,
        provider_id: str,
        resume_text: str,
        eval_type: str = "initial",
    ):
        """流式执行评估，yield SSE 事件"""
        self._provider_id = provider_id
        self._parsed_profile = {}
        self._scores = {}
        self._vibe_power = 0
        self._report = {}
        self._review_tags = {}

        messages = [{"role": "user", "content": f"请评估以下团队方的简历并进行 VibeBuild 定级：\n\n{resume_text}"}]

        async for event in self.run_stream(
            messages=messages,
            max_tokens=8192,
            eval_type=eval_type,
        ):
            yield event

        # 追加评估结果
        yield {
            "event": "rating_result",
            "data": json.dumps({
                "provider_id": provider_id,
                "vibe_power": self._vibe_power,
                "vibe_level": self._report.get("vibe_level", "vc-T1"),
                "report": self._report,
            }, ensure_ascii=False),
        }
