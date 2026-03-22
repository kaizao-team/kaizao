"""
开造 VibeBuild — 智能匹配 Agent 单元测试
"""

import pytest
from unittest.mock import MagicMock

from app.agents.smart_matcher import SmartMatcherAgent


class TestMatchScoring:
    """匹配评分逻辑测试"""

    def setup_method(self):
        mock_llm = MagicMock()
        mock_embedding = MagicMock()
        mock_milvus = MagicMock()
        mock_retriever = MagicMock()
        self.agent = SmartMatcherAgent(
            llm_router=mock_llm,
            embedding_client=mock_embedding,
            milvus_store=mock_milvus,
            retriever=mock_retriever,
        )

    def test_perfect_skill_match(self):
        """技能完全匹配应得高分"""
        demand = {"tech_stack": ["Flutter", "Go", "PostgreSQL"]}
        provider = {
            "skills": ["Flutter", "Go", "PostgreSQL"],
            "avg_rating": 4.8,
            "total_orders": 10,
            "completion_rate": 95,
            "positive_rate": 98,
            "avg_price": 3000,
            "avg_response_hours": 2,
            "last_order_timestamp": 0,
            "register_timestamp": 0,
        }
        result = self.agent._calculate_match_score(demand, provider, vector_similarity=0.9)
        assert result["total_score"] > 70

    def test_no_skill_match(self):
        """技能完全不匹配应得低分"""
        demand = {"tech_stack": ["Flutter", "Go"]}
        provider = {
            "skills": ["Java", "Spring"],
            "avg_rating": 3.0,
            "total_orders": 5,
            "completion_rate": 80,
            "positive_rate": 70,
            "avg_price": 5000,
            "avg_response_hours": 48,
            "last_order_timestamp": 0,
            "register_timestamp": 0,
        }
        result = self.agent._calculate_match_score(demand, provider, vector_similarity=0.2)
        assert result["total_score"] < 50

    def test_new_user_baseline(self):
        """新用户应获得基准评价分"""
        demand = {"tech_stack": []}
        provider = {
            "skills": [],
            "avg_rating": 0,
            "total_orders": 0,
            "completion_rate": 0,
            "positive_rate": 0,
            "avg_price": 0,
            "avg_response_hours": 24,
            "last_order_timestamp": 0,
            "register_timestamp": 0,
        }
        result = self.agent._calculate_match_score(demand, provider, vector_similarity=0.5)
        assert result["dimension_scores"]["rating"] == 60.0

    def test_price_in_budget(self):
        """价格在预算范围内应满分"""
        demand = {"tech_stack": [], "budget_min": 2000, "budget_max": 5000}
        provider = {
            "skills": [],
            "avg_rating": 0,
            "total_orders": 0,
            "completion_rate": 0,
            "positive_rate": 0,
            "avg_price": 3000,
            "avg_response_hours": 24,
            "last_order_timestamp": 0,
            "register_timestamp": 0,
        }
        result = self.agent._calculate_match_score(demand, provider, vector_similarity=0.5)
        assert result["dimension_scores"]["price_match"] == 100.0

    def test_score_has_explanation(self):
        """评分结果应包含推荐理由"""
        demand = {"tech_stack": ["React"]}
        provider = {
            "skills": ["React", "Node.js"],
            "avg_rating": 4.5,
            "total_orders": 20,
            "completion_rate": 90,
            "positive_rate": 95,
            "avg_price": 0,
            "avg_response_hours": 6,
            "last_order_timestamp": 0,
            "register_timestamp": 0,
        }
        result = self.agent._calculate_match_score(demand, provider, vector_similarity=0.8)
        assert "explanation" in result
        assert len(result["explanation"]) > 0

    def test_weight_sum_equals_one(self):
        """权重之和应等于 1.0"""
        total = sum(SmartMatcherAgent.WEIGHTS.values())
        assert abs(total - 1.0) < 1e-6
