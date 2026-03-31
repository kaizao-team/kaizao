"""
开造 VibeBuild — 智能匹配 Agent
负责需求-供给方匹配评分、向量检索、LLM 推荐理由生成
"""

import json
import time
from typing import Dict, Any, Optional, List

import numpy as np
import structlog

from app.agents.base_agent import BaseAgent
from app.config import settings
from app.db.repository import ProjectRepository
from app.llm.router import LLMRouter
from app.vectorizer.embedding_client import EmbeddingClient
from app.storage.milvus_store import MilvusStore
from app.rag.retriever import HybridRetriever
from app.prompts.matcher_prompts import MATCHER_SYSTEM_PROMPT, MATCH_RECOMMENDATION_PROMPT

logger = structlog.get_logger()


class SmartMatcherAgent(BaseAgent):
    """
    智能匹配 Agent

    工作流程：
    1. 接收需求信息 -> 生成需求向量
    2. 向量检索候选供给方 -> Top-N 召回
    3. 多维评分 -> 加权排序
    4. LLM 生成推荐理由
    5. 返回推荐列表
    """

    # 匹配维度权重
    WEIGHTS = {
        "skill_match": 0.30,
        "rating": 0.25,
        "price_match": 0.20,
        "response_speed": 0.15,
        "portfolio_similarity": 0.10,
    }

    def __init__(
        self,
        llm_router: LLMRouter,
        embedding_client: EmbeddingClient,
        milvus_store: MilvusStore,
        retriever: HybridRetriever,
    ):
        super().__init__(agent_name="SmartMatcher", llm_router=llm_router)
        self.embedding_client = embedding_client
        self.milvus_store = milvus_store
        self.retriever = retriever
        self._project_repo = ProjectRepository()

    async def _execute(
        self,
        request_id: str,
        demand_id: str,
        match_type: str = "recommend_providers",
        user_id: Optional[str] = None,
        filters: Optional[Dict[str, Any]] = None,
        pagination: Optional[Dict[str, int]] = None,
    ) -> Dict[str, Any]:
        """
        智能匹配核心逻辑

        Args:
            request_id: 请求 ID
            demand_id: 需求 UUID
            match_type: 匹配类型
            user_id: 用户 ID（供给方推荐场景）
            filters: 过滤条件
            pagination: 分页参数

        Returns:
            匹配结果（符合 SmartMatcherOutput Schema）
        """
        start_time = time.time()
        page = (pagination or {}).get("page", 1)
        page_size = min((pagination or {}).get("page_size", 10), 20)

        # 从数据库读取真实需求信息
        demand = await self._get_demand_info(demand_id)
        if demand is None:
            return {
                "demand_id": demand_id,
                "match_type": match_type,
                "recommendations": [],
                "overall_suggestion": "",
                "no_match_reason": f"需求 {demand_id} 不存在，无法进行匹配。",
                "meta": {"total_candidates_scanned": 0, "processing_time_ms": 0, "rag_references_used": 0},
            }

        # Step 1: 生成需求语义向量
        demand_text = (
            f"{demand.get('title', '')} "
            f"{demand.get('description', '')} "
            f"{' '.join(demand.get('tech_stack', []))}"
        )
        demand_vector = self.embedding_client.encode(demand_text)

        # Step 2: 向量检索候选供给方
        expr = "is_active == true"
        if filters:
            if filters.get("is_verified_only"):
                expr += " and credit_score >= 600"

        candidates = self.milvus_store.search_vectors(
            collection_name=settings.milvus_provider_collection,
            query_vector=demand_vector,
            top_k=50,
            output_fields=[
                "user_uuid", "skills_json", "category_tags",
                "avg_rating", "credit_score",
            ],
            expr=expr,
        )

        # Step 3: 批量从 MySQL 补全供给方数据 + 多维评分
        candidate_uuids = [c.get("user_uuid", "") for c in candidates if c.get("user_uuid")]
        user_profiles = await self._batch_enrich_providers(candidate_uuids)

        scored_candidates = []
        for candidate in candidates:
            provider = self._parse_provider(candidate, user_profiles)
            score_result = self._calculate_match_score(
                demand=demand,
                provider=provider,
                vector_similarity=candidate.get("distance", 0),
            )
            scored_candidates.append({
                "provider": provider,
                "score": score_result,
            })

        # Step 4: 排序
        scored_candidates.sort(key=lambda x: x["score"]["total_score"], reverse=True)

        # 分页
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        page_candidates = scored_candidates[start_idx:end_idx]

        # Step 5: 使用 LLM 生成推荐理由
        recommendations = await self._generate_recommendations(
            demand=demand,
            candidates=page_candidates,
        )

        # 判断是否无匹配
        no_match_reason = None
        overall_suggestion = ""
        if not recommendations:
            no_match_reason = "暂未找到高度匹配的供给方，建议适当放宽技术栈要求或调整预算范围。"
        elif recommendations[0]["match_score"] < settings.match_min_score:
            no_match_reason = "当前匹配分数偏低，建议完善需求描述或扩大技术栈范围。"
        else:
            overall_suggestion = (
                "根据您的需求，建议优先与排名前3的供给方沟通，"
                "他们在技术匹配度和历史评价方面表现突出。"
            )

        processing_time = round((time.time() - start_time) * 1000)

        return {
            "demand_id": demand_id,
            "match_type": match_type,
            "recommendations": recommendations,
            "overall_suggestion": overall_suggestion,
            "no_match_reason": no_match_reason,
            "meta": {
                "total_candidates_scanned": len(candidates),
                "processing_time_ms": processing_time,
                "rag_references_used": 0,
            },
        }

    async def _get_demand_info(self, demand_id: str) -> Optional[Dict[str, Any]]:
        """
        从 MySQL projects 表读取真实需求信息

        Args:
            demand_id: 需求 UUID (Go 后端 projects.uuid)

        Returns:
            需求信息字典，项目不存在时返回 None
        """
        try:
            return await self._project_repo.get_project_for_matching(demand_id)
        except Exception as e:
            self.logger.error("get_demand_info_failed", demand_id=demand_id, error=str(e))
            return None

    async def _batch_enrich_providers(self, uuids: list[str]) -> dict[str, dict]:
        """批量从 MySQL users 表读取供给方真实数据"""
        try:
            return await self._project_repo.batch_get_users_by_uuids(uuids)
        except Exception as e:
            self.logger.warning("batch_enrich_providers_failed", error=str(e))
            return {}

    def _parse_provider(self, candidate: Dict, user_profiles: dict[str, dict] | None = None) -> Dict[str, Any]:
        """
        解析候选供给方数据：Milvus 向量检索结果 + MySQL users 表真实数据

        Args:
            candidate: Milvus 检索结果
            user_profiles: 批量查询的用户信息 {uuid: user_dict}

        Returns:
            供给方信息字典
        """
        user_uuid = candidate.get("user_uuid", "")
        db_user = (user_profiles or {}).get(user_uuid, {})

        # 技能：优先 Milvus，MySQL 无此字段
        skills = []
        try:
            skills_raw = candidate.get("skills_json", "[]")
            if skills_raw:
                skills = json.loads(skills_raw)
        except json.JSONDecodeError:
            pass

        # 从 MySQL users 表取真实数据，Milvus 字段作为 fallback
        avg_rating = db_user.get("avg_rating", candidate.get("avg_rating", 0))
        credit_score = db_user.get("credit_score", candidate.get("credit_score", 500))

        # 价格代理：使用 hourly_rate 作为 avg_price 的近似
        hourly_rate = db_user.get("hourly_rate", 0)

        # 响应速度：response_time_avg 单位是分钟，转换为小时
        response_minutes = db_user.get("response_time_avg", 0)
        avg_response_hours = response_minutes / 60.0 if response_minutes > 0 else 24

        # 注册时间戳
        register_timestamp = 0
        if db_user.get("created_at"):
            try:
                from datetime import datetime
                dt = datetime.fromisoformat(db_user["created_at"])
                register_timestamp = dt.timestamp()
            except (ValueError, TypeError):
                pass

        return {
            "user_uuid": user_uuid,
            "nickname": db_user.get("nickname", ""),
            "skills": skills,
            "avg_rating": avg_rating,
            "credit_score": credit_score,
            "total_orders": db_user.get("total_orders", 0),
            "completed_orders": db_user.get("completed_orders", 0),
            "completion_rate": db_user.get("completion_rate", 0),
            "positive_rate": db_user.get("completion_rate", 0),  # 暂用完成率近似
            "avg_price": hourly_rate,
            "avg_response_hours": avg_response_hours,
            "last_order_timestamp": 0,  # Go 后端暂无此字段
            "register_timestamp": register_timestamp,
            "is_verified": db_user.get("is_verified", False),
            "available_status": db_user.get("available_status", 1),
        }

    def _calculate_match_score(
        self,
        demand: Dict,
        provider: Dict,
        vector_similarity: float,
    ) -> Dict[str, Any]:
        """
        完整匹配评分

        最终得分 = sum(维度分数 x 维度权重) x 100 x 调节因子

        Args:
            demand: 需求信息
            provider: 供给方信息
            vector_similarity: 向量相似度

        Returns:
            评分结果字典
        """
        scores = {}

        # 维度1: 技能匹配度（权重 30%）
        demand_skills = set(demand.get("tech_stack", []))
        provider_skills = set(provider.get("skills", []))
        if demand_skills:
            exact_overlap = len(demand_skills & provider_skills) / len(demand_skills)
            scores["skill_match"] = exact_overlap * 0.6 + vector_similarity * 0.4
        else:
            scores["skill_match"] = 0.5

        # 维度2: 历史评价（权重 25%）
        if provider.get("total_orders", 0) == 0:
            scores["rating"] = 0.60  # 新用户基准分
        else:
            avg_rating = provider.get("avg_rating", 0)
            completion_rate = provider.get("completion_rate", 0)
            positive_rate = provider.get("positive_rate", 0)
            scores["rating"] = (
                (avg_rating / 5.0) * 0.60
                + (completion_rate / 100.0) * 0.25
                + (positive_rate / 100.0) * 0.15
            )

        # 维度3: 价格匹配（权重 20%）
        budget_min = demand.get("budget_min", 0) or 0
        budget_max = demand.get("budget_max", 0) or 0
        provider_avg_price = provider.get("avg_price", 0)

        if provider_avg_price == 0 or budget_max == 0:
            scores["price_match"] = 0.5
        elif budget_min <= provider_avg_price <= budget_max:
            scores["price_match"] = 1.0
        else:
            budget_mid = (budget_min + budget_max) / 2 if budget_max > 0 else 5000
            deviation = abs(provider_avg_price - budget_mid) / (budget_mid + 1e-8)
            scores["price_match"] = max(0, 1 - deviation)

        # 维度4: 响应速度（权重 15%）
        avg_response_hours = provider.get("avg_response_hours", 24)
        scores["response_speed"] = max(0, 1 - avg_response_hours / 48.0)

        # 维度5: 作品相似度（权重 10%）
        scores["portfolio_similarity"] = max(0, min(1, vector_similarity))

        # 加权汇总
        raw_score = sum(scores[dim] * self.WEIGHTS[dim] for dim in self.WEIGHTS) * 100

        # 调节因子
        adjustment_factors = {}

        # 时间衰减因子
        last_order_days = (time.time() - provider.get("last_order_timestamp", 0)) / 86400
        if provider.get("last_order_timestamp", 0) == 0:
            adjustment_factors["time_decay"] = 1.0
        elif last_order_days <= 30:
            adjustment_factors["time_decay"] = 1.2
        elif last_order_days <= 90:
            adjustment_factors["time_decay"] = 1.0
        else:
            adjustment_factors["time_decay"] = 0.8

        # 新人扶持因子
        register_days = (time.time() - provider.get("register_timestamp", 0)) / 86400
        if (
            register_days <= settings.newbie_boost_days
            and provider.get("total_orders", 0) == 0
            and provider.get("register_timestamp", 0) > 0
        ):
            adjustment_factors["newbie_boost"] = settings.newbie_boost_factor
        else:
            adjustment_factors["newbie_boost"] = 1.0

        total_adjustment = 1.0
        for factor_value in adjustment_factors.values():
            total_adjustment *= factor_value

        final_score = min(100, raw_score * total_adjustment)

        # 生成推荐理由关键词
        explanation_parts = []
        dim_names = {
            "skill_match": "技能匹配度",
            "rating": "历史好评",
            "price_match": "价格匹配",
            "response_speed": "响应速度",
            "portfolio_similarity": "作品相关度",
        }
        sorted_dims = sorted(
            scores.items(), key=lambda x: x[1] * self.WEIGHTS[x[0]], reverse=True
        )
        for dim, score in sorted_dims[:3]:
            if score > 0.7:
                explanation_parts.append(f"{dim_names[dim]}高")
            elif score > 0.4:
                explanation_parts.append(f"{dim_names[dim]}良好")
        explanation = "、".join(explanation_parts) if explanation_parts else "综合匹配"

        return {
            "total_score": round(final_score, 2),
            "dimension_scores": {k: round(v * 100, 2) for k, v in scores.items()},
            "adjustment_factors": adjustment_factors,
            "explanation": explanation,
        }

    async def _generate_recommendations(
        self,
        demand: Dict,
        candidates: List[Dict],
    ) -> List[Dict[str, Any]]:
        """
        使用 LLM 生成推荐理由

        Args:
            demand: 需求信息
            candidates: 评分后的候选列表

        Returns:
            推荐列表
        """
        if not candidates:
            return []

        # 构建候选列表文本
        candidate_lines = []
        for i, c in enumerate(candidates):
            provider = c["provider"]
            score = c["score"]
            line = (
                f"{i + 1}. UUID: {provider['user_uuid']}, "
                f"技能: {', '.join(provider['skills'][:5])}, "
                f"评分: {provider.get('avg_rating', 0)}, "
                f"匹配分: {score['total_score']}, "
                f"关键优势: {score['explanation']}"
            )
            candidate_lines.append(line)

        candidate_text = "\n".join(candidate_lines)

        prompt = MATCH_RECOMMENDATION_PROMPT.format(
            demand_summary=f"{demand.get('title', '')} - {demand.get('description', '')}",
            tech_stack=", ".join(demand.get("tech_stack", [])) or "未指定",
            budget_range=(
                f"{demand.get('budget_min', '未指定')} - "
                f"{demand.get('budget_max', '未指定')} 元"
            ),
            rag_context="暂无历史项目参考",
            candidate_list=candidate_text,
        )

        messages = [
            {"role": "system", "content": MATCHER_SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]

        try:
            raw_output = await self.call_llm(
                messages=messages,
                model_tier="default",
                max_tokens=2048,
                temperature=0.3,
            )

            # 解析 LLM 输出
            parsed = self._parse_recommendations(raw_output, candidates)
            return parsed

        except Exception as e:
            self.logger.warning("recommendation_generation_failed", error=str(e))
            # 降级：使用评分算法生成的简单理由
            return self._fallback_recommendations(candidates)

    def _parse_recommendations(
        self,
        raw_output: str,
        candidates: List[Dict],
    ) -> List[Dict[str, Any]]:
        """解析 LLM 输出的推荐结果"""
        try:
            json_start = raw_output.find("{")
            json_end = raw_output.rfind("}") + 1
            if json_start >= 0 and json_end > json_start:
                parsed = json.loads(raw_output[json_start:json_end])
                return parsed.get("recommendations", [])
        except json.JSONDecodeError:
            pass

        return self._fallback_recommendations(candidates)

    def _fallback_recommendations(self, candidates: List[Dict]) -> List[Dict[str, Any]]:
        """降级推荐结果（不使用 LLM）"""
        results = []
        for i, c in enumerate(candidates):
            provider = c["provider"]
            score = c["score"]
            results.append({
                "provider_id": provider["user_uuid"],
                "rank": i + 1,
                "match_score": score["total_score"],
                "recommendation_reason": score["explanation"],
                "highlight_skills": provider.get("skills", [])[:3],
                "similar_project_reference": "",
                "dimension_scores": score["dimension_scores"],
            })
        return results
