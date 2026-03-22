"""
开造 VibeBuild — 需求分析 Agent
负责多轮对话引导、PRD 生成、EARS 卡片拆解、复杂度预估
"""

import json
from typing import Dict, Any, Optional, List

import structlog

from app.agents.base_agent import BaseAgent, AgentError
from app.config import settings
from app.llm.router import LLMRouter
from app.rag.retriever import HybridRetriever
from app.safety.injection_defender import PromptInjectionDefender
from app.prompts.analyzer_prompts import (
    ANALYZER_SYSTEM_PROMPT,
    ANALYZER_OUTPUT_INSTRUCTION,
    PRD_GENERATION_INSTRUCTION,
    EARS_GENERATION_INSTRUCTION,
    ESTIMATION_INSTRUCTION,
)

logger = structlog.get_logger()


class ProjectAnalyzerAgent(BaseAgent):
    """
    项目需求分析 Agent

    工作流程：
    1. 接收用户描述 -> 分析需求完整度
    2. 多轮对话引导 -> 补全缺失维度
    3. 生成结构化 PRD -> 用户确认
    4. EARS 卡片拆解 -> 依赖关系分析
    5. 复杂度预估 -> 价格/工期预估
    """

    def __init__(self, llm_router: LLMRouter, retriever: HybridRetriever):
        super().__init__(agent_name="ProjectAnalyzer", llm_router=llm_router)
        self.retriever = retriever
        self.defender = PromptInjectionDefender()
        # 内存中的会话存储（生产环境应使用 Redis）
        self._sessions: Dict[str, Dict] = {}

    async def _execute(
        self,
        request_id: str,
        session_id: str,
        user_id: str,
        message: Dict[str, Any],
        context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        需求分析 Agent 核心逻辑

        Args:
            request_id: 请求 ID
            session_id: 会话 ID
            user_id: 用户 ID
            message: 用户消息 {"type": "text", "content": "..."}
            context: 可选上下文 {"selected_category": "...", "budget_hint": {...}}

        Returns:
            Agent 输出（符合 ProjectAnalyzerOutput Schema）
        """
        user_content = message.get("content", "")

        # 安全检查：Prompt 注入防御
        safety_result = self.defender.check(user_content)
        if not safety_result["is_safe"]:
            self.logger.warning(
                "injection_blocked",
                request_id=request_id,
                risk_level=safety_result["risk_level"],
            )
            return {
                "session_id": session_id,
                "stage": "dialogue_guidance",
                "response": {
                    "message": self.defender.get_safe_response(),
                    "options": [],
                },
                "analysis": None,
                "prd": None,
                "ears_cards": None,
                "estimation": None,
            }

        # 获取或创建会话
        session = self._get_or_create_session(session_id, user_id, context)

        # 添加当前用户消息到历史
        session["turns"].append({"user_message": user_content, "assistant_message": ""})

        # 确定当前阶段
        stage = self._determine_stage(session)

        # 构建额外上下文
        extra_context = ""

        # RAG 检索相似项目参考
        if stage in ("dialogue_guidance", "prd_preview"):
            rag_results = self.retriever.retrieve(
                query=user_content,
                top_k=3,
                metadata_filter={"collection_type": "project"},
            )
            rag_context = self.retriever.format_rag_context(rag_results, max_tokens=1000)
            if rag_context and "未检索到" not in rag_context:
                extra_context += f"\n\n[相似历史项目参考]\n{rag_context}"

        # 如果有会话上下文摘要
        if session.get("summary"):
            extra_context += f"\n\n[对话历史摘要] {session['summary']}"

        # 选择 Prompt
        system_prompt = ANALYZER_SYSTEM_PROMPT + "\n\n" + ANALYZER_OUTPUT_INSTRUCTION
        if stage == "prd_preview":
            system_prompt += "\n\n" + PRD_GENERATION_INSTRUCTION
        elif stage == "ears_generation":
            system_prompt += "\n\n" + EARS_GENERATION_INSTRUCTION
        elif stage == "estimation":
            system_prompt += "\n\n" + ESTIMATION_INSTRUCTION

        # 构建消息列表（使用滑动窗口）
        recent_turns = session["turns"][-settings.max_conversation_turns:]
        messages = self._build_messages(
            system_prompt=system_prompt,
            user_message=user_content,
            conversation_history=recent_turns[:-1],  # 排除当前轮（已在 user_message 中）
            injected_context=extra_context if extra_context else None,
        )

        # 选择模型级别
        model_tier = "high" if stage in ("prd_preview", "ears_generation") else "default"

        # 调用 LLM
        raw_output = await self.call_llm(
            messages=messages,
            model_tier=model_tier,
            max_tokens=settings.claude_max_tokens,
            temperature=0.3,
        )

        # 解析输出
        result = self._parse_output(raw_output, session_id, stage)

        # 更新会话状态
        session["turns"][-1]["assistant_message"] = result.get("response", {}).get("message", "")
        if result.get("analysis"):
            session["completeness_score"] = result["analysis"].get("completeness_score", 0)
        if result.get("prd"):
            session["prd"] = result["prd"]
            session["prd_confirmed"] = False
        if result.get("ears_cards"):
            session["ears_cards"] = result["ears_cards"]

        # 检查是否需要生成历史摘要
        if len(session["turns"]) >= settings.summary_threshold_turns and not session.get("summary"):
            session["summary"] = await self._generate_summary(session["turns"])

        self._sessions[session_id] = session
        return result

    def _get_or_create_session(
        self,
        session_id: str,
        user_id: str,
        context: Optional[Dict] = None,
    ) -> Dict:
        """获取或创建会话"""
        if session_id in self._sessions:
            return self._sessions[session_id]

        session = {
            "session_id": session_id,
            "user_id": user_id,
            "turns": [],
            "completeness_score": 0,
            "category": None,
            "prd": None,
            "prd_confirmed": False,
            "ears_cards": None,
            "summary": None,
            "context": context or {},
        }
        self._sessions[session_id] = session
        return session

    def _determine_stage(self, session: Dict) -> str:
        """根据会话状态确定当前阶段"""
        if session.get("ears_cards"):
            return "estimation"
        if session.get("prd_confirmed"):
            return "ears_generation"
        if session.get("completeness_score", 0) >= settings.completeness_threshold:
            return "prd_preview"
        if len(session["turns"]) <= 1:
            return "intent_recognition"
        return "dialogue_guidance"

    def _parse_output(self, raw_output: str, session_id: str, stage: str) -> Dict:
        """
        解析 LLM 输出为结构化字典

        Args:
            raw_output: LLM 原始输出文本
            session_id: 会话 ID
            stage: 当前阶段

        Returns:
            解析后的字典
        """
        # 尝试从输出中提取 JSON
        try:
            # 查找 JSON 块
            json_start = raw_output.find("{")
            json_end = raw_output.rfind("}") + 1
            if json_start >= 0 and json_end > json_start:
                json_str = raw_output[json_start:json_end]
                parsed = json.loads(json_str)
                # 确保 session_id 正确
                parsed["session_id"] = session_id
                return parsed
        except json.JSONDecodeError:
            pass

        # JSON 解析失败，构造默认响应
        self.logger.warning("llm_output_parse_failed", raw_output_length=len(raw_output))
        return {
            "session_id": session_id,
            "stage": stage,
            "response": {
                "message": raw_output[:500],
                "options": [],
            },
            "analysis": None,
            "prd": None,
            "ears_cards": None,
            "estimation": None,
        }

    async def _generate_summary(self, turns: List[Dict]) -> str:
        """生成对话历史摘要"""
        dialogue_text = "\n".join(
            f"用户: {t['user_message']}\n助手: {t['assistant_message']}" for t in turns
        )
        prompt = (
            f"请将以下对话历史压缩为一段简洁的摘要（不超过200字），"
            f"保留关键信息（用户身份、核心需求、已达成的结论、待解决的问题）：\n\n"
            f"{dialogue_text}\n\n摘要："
        )
        messages = [
            {"role": "system", "content": "你是一个对话摘要助手。"},
            {"role": "user", "content": prompt},
        ]
        try:
            summary = await self.call_llm(messages=messages, model_tier="low", max_tokens=300)
            return summary.strip()
        except Exception as e:
            self.logger.warning("summary_generation_failed", error=str(e))
            return ""
