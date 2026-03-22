"""
开造 VibeBuild — 对话助手 Agent
负责意图识别、多轮对话、上下文管理、Agent 转交
"""

import json
from typing import Dict, Any, Optional, List

import structlog

from app.agents.base_agent import BaseAgent
from app.config import settings
from app.llm.router import LLMRouter
from app.safety.injection_defender import PromptInjectionDefender
from app.prompts.assistant_prompts import (
    ASSISTANT_SYSTEM_PROMPT,
    INTENT_CLASSIFICATION_INSTRUCTION,
    CONVERSATION_SUMMARY_PROMPT,
)

logger = structlog.get_logger()


# 需要转交给其他 Agent 的意图映射
HANDOFF_INTENTS = {
    "A1": "ProjectAnalyzer",
    "B1": "SmartMatcher",
}

# 需要页面跳转的意图映射
NAVIGATE_INTENTS = {
    "A2": "/demands/{demand_id}/edit",
    "A3": "/demands/{demand_id}",
    "B3": "/demands/{demand_id}/bid",
    "C1": "/projects/{project_id}",
    "C4": "/conversations/{conversation_id}",
    "D1": "/auth/login",
    "D3": "/settings/verification",
    "D4": "/settings/profile",
}


class ChatAssistantAgent(BaseAgent):
    """
    对话助手 Agent

    功能：
    1. 意图识别 -> 分类用户消息
    2. 多轮对话 -> 上下文滑动窗口
    3. Agent 转交 -> 需求发布转 ProjectAnalyzer，找人转 SmartMatcher
    4. 安全防护 -> Prompt 注入检测 + 内容过滤
    """

    def __init__(self, llm_router: LLMRouter):
        super().__init__(agent_name="ChatAssistant", llm_router=llm_router)
        self.defender = PromptInjectionDefender()
        self._sessions: Dict[str, Dict] = {}

    async def _execute(
        self,
        request_id: str,
        session_id: str,
        user_id: str,
        user_role: Optional[str] = "unknown",
        message: Optional[Dict[str, Any]] = None,
        page_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        对话助手核心逻辑

        Args:
            request_id: 请求 ID
            session_id: 会话 ID
            user_id: 用户 ID
            user_role: 用户角色 demand/provider/both/unknown
            message: 用户消息 {"content": "...", "type": "text"}
            page_context: 页面上下文 {"current_page": "/...", "viewing_demand_id": "..."}

        Returns:
            ChatAssistant 输出（符合 ChatAssistantOutput Schema）
        """
        user_content = (message or {}).get("content", "")

        # 安全检查
        safety_result = self.defender.check(user_content)
        if not safety_result["is_safe"]:
            self.logger.warning(
                "injection_blocked",
                request_id=request_id,
                risk_level=safety_result["risk_level"],
            )
            return {
                "session_id": session_id,
                "intent": {
                    "primary": "Z3",
                    "confidence": 1.0,
                    "entities": {},
                },
                "response": {
                    "message": self.defender.get_safe_response(),
                    "quick_replies": [
                        {"label": "发布需求", "value": "我想发布一个新需求"},
                        {"label": "平台介绍", "value": "介绍一下开造平台"},
                    ],
                    "action": {"type": "none", "target": "", "params": {}},
                },
                "safety": {
                    "input_safe": False,
                    "injection_detected": True,
                    "content_filtered": False,
                },
            }

        # 获取或创建会话
        session = self._get_or_create_session(session_id, user_id, user_role)

        # 记录当前消息
        session["turns"].append({"user_message": user_content, "assistant_message": ""})

        # 构建上下文
        current_page = (page_context or {}).get("current_page", "")
        intent_instruction = INTENT_CLASSIFICATION_INSTRUCTION.format(
            user_role=user_role or "unknown",
            current_page=current_page or "首页",
        )

        # 构建消息列表（滑动窗口）
        extra_context_parts = []

        # 注入会话摘要
        if session.get("summary"):
            extra_context_parts.append(f"[对话历史摘要] {session['summary']}")

        # 注入关键实体
        if session.get("entities"):
            entity_text = " | ".join(
                f"{k}: {v}" for k, v in session["entities"].items()
            )
            extra_context_parts.append(f"[用户关键信息] {entity_text}")

        # 注入当前意图状态
        if session.get("current_intent"):
            extra_context_parts.append(
                f"[当前识别意图] {session['current_intent']}"
            )

        extra_context = (
            "\n".join(extra_context_parts) if extra_context_parts else None
        )

        system_prompt = ASSISTANT_SYSTEM_PROMPT + "\n\n" + intent_instruction

        recent_turns = session["turns"][-settings.max_conversation_turns:]
        messages = self._build_messages(
            system_prompt=system_prompt,
            user_message=user_content,
            conversation_history=recent_turns[:-1],
            injected_context=extra_context,
        )

        # 调用 LLM（对话助手使用 default 级别）
        raw_output = await self.call_llm(
            messages=messages,
            model_tier="default",
            max_tokens=1024,
            temperature=0.5,
        )

        # 解析输出
        result = self._parse_output(raw_output, session_id)

        # 对 AI 输出进行内容过滤
        if result.get("response", {}).get("message"):
            result["response"]["message"] = self.defender.sanitize_output(
                result["response"]["message"]
            )

        # 更新会话状态
        assistant_msg = result.get("response", {}).get("message", "")
        session["turns"][-1]["assistant_message"] = assistant_msg

        intent = result.get("intent", {})
        primary_intent = intent.get("primary", "")
        session["current_intent"] = primary_intent

        # 提取实体并缓存
        entities = intent.get("entities", {})
        if entities:
            session["entities"].update(entities)

        # 处理 Agent 转交
        if primary_intent in HANDOFF_INTENTS:
            result["response"]["action"] = {
                "type": "handoff",
                "target": HANDOFF_INTENTS[primary_intent],
                "params": {"session_id": session_id, "user_id": user_id},
            }
        elif primary_intent in NAVIGATE_INTENTS:
            target_path = NAVIGATE_INTENTS[primary_intent]
            # 替换路径中的占位符
            if page_context:
                for key, value in page_context.items():
                    placeholder = "{" + key.replace("viewing_", "") + "}"
                    if placeholder in target_path and value:
                        target_path = target_path.replace(
                            placeholder, str(value)
                        )
            result["response"]["action"] = {
                "type": "navigate",
                "target": target_path,
                "params": {},
            }

        # 检查是否需要生成历史摘要
        if (
            len(session["turns"]) >= settings.summary_threshold_turns
            and not session.get("summary")
        ):
            session["summary"] = await self._generate_summary(session["turns"])

        # 添加安全信息
        result["safety"] = {
            "input_safe": True,
            "injection_detected": False,
            "content_filtered": False,
        }

        self._sessions[session_id] = session
        return result

    def _get_or_create_session(
        self,
        session_id: str,
        user_id: str,
        user_role: Optional[str] = "unknown",
    ) -> Dict:
        """获取或创建对话会话"""
        if session_id in self._sessions:
            return self._sessions[session_id]

        session = {
            "session_id": session_id,
            "user_id": user_id,
            "user_role": user_role,
            "turns": [],
            "current_intent": None,
            "entities": {},
            "summary": None,
        }
        self._sessions[session_id] = session
        return session

    def _parse_output(self, raw_output: str, session_id: str) -> Dict:
        """解析 LLM 输出"""
        try:
            json_start = raw_output.find("{")
            json_end = raw_output.rfind("}") + 1
            if json_start >= 0 and json_end > json_start:
                json_str = raw_output[json_start:json_end]
                parsed = json.loads(json_str)
                parsed["session_id"] = session_id
                # 确保必要字段存在
                if "intent" not in parsed:
                    parsed["intent"] = {
                        "primary": "E1",
                        "confidence": 0.5,
                        "entities": {},
                    }
                if "response" not in parsed:
                    parsed["response"] = {
                        "message": raw_output[:300],
                        "quick_replies": [],
                        "action": {
                            "type": "none",
                            "target": "",
                            "params": {},
                        },
                    }
                if "action" not in parsed.get("response", {}):
                    parsed["response"]["action"] = {
                        "type": "none",
                        "target": "",
                        "params": {},
                    }
                return parsed
        except json.JSONDecodeError:
            pass

        # 降级处理
        return {
            "session_id": session_id,
            "intent": {"primary": "E1", "confidence": 0.5, "entities": {}},
            "response": {
                "message": (
                    raw_output[:300]
                    if raw_output
                    else "抱歉，我暂时无法处理您的请求。请稍后再试。"
                ),
                "quick_replies": [
                    {"label": "发布需求", "value": "我想发布一个新需求"},
                    {"label": "平台介绍", "value": "介绍一下开造平台"},
                ],
                "action": {"type": "none", "target": "", "params": {}},
            },
        }

    async def _generate_summary(self, turns: List[Dict]) -> str:
        """生成对话历史摘要"""
        dialogue_text = "\n".join(
            f"用户: {t['user_message']}\n助手: {t['assistant_message']}"
            for t in turns
        )
        prompt = CONVERSATION_SUMMARY_PROMPT.format(dialogue_text=dialogue_text)
        messages = [
            {"role": "system", "content": "你是一个对话摘要助手。"},
            {"role": "user", "content": prompt},
        ]
        try:
            summary = await self.call_llm(
                messages=messages, model_tier="low", max_tokens=300
            )
            return summary.strip()
        except Exception as e:
            self.logger.warning("summary_generation_failed", error=str(e))
            return ""
