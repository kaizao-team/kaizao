"""
开造 VibeBuild — 混合检索器
向量语义检索（Milvus）+ 关键词检索（Elasticsearch）+ RRF 融合排序
"""

from typing import List, Dict, Optional, Any

import numpy as np
import structlog

from app.config import settings
from app.storage.milvus_store import MilvusStore
from app.vectorizer.embedding_client import EmbeddingClient

logger = structlog.get_logger()


class HybridRetriever:
    """
    混合检索器
    1. 向量语义检索（Milvus）-> Top N
    2. 关键词检索（Elasticsearch BM25）-> Top N
    3. RRF 融合重排 -> Top K

    如果 Elasticsearch 不可用，退化为纯向量检索。
    """

    def __init__(
        self,
        milvus_store: MilvusStore,
        embedding_client: EmbeddingClient,
    ):
        self.milvus_store = milvus_store
        self.embedding_client = embedding_client
        self._es_client = None
        self._init_elasticsearch()

    def _init_elasticsearch(self):
        """初始化 Elasticsearch 客户端（可选）"""
        try:
            from elasticsearch import Elasticsearch

            es_kwargs = {"hosts": [settings.elasticsearch_url]}
            if settings.elasticsearch_username:
                es_kwargs["basic_auth"] = (
                    settings.elasticsearch_username,
                    settings.elasticsearch_password,
                )
            self._es_client = Elasticsearch(**es_kwargs)
            if self._es_client.ping():
                logger.info("Elasticsearch 连接成功")
            else:
                logger.warning("Elasticsearch 不可用，将使用纯向量检索模式")
                self._es_client = None
        except Exception as e:
            logger.warning("Elasticsearch 初始化失败，将使用纯向量检索模式", error=str(e))
            self._es_client = None

    def retrieve(
        self,
        query: str,
        collection_name: Optional[str] = None,
        top_k: int = 5,
        metadata_filter: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        混合检索入口

        Args:
            query: 查询文本
            collection_name: Milvus 集合名称，默认使用知识库集合
            top_k: 返回 Top-K 结果
            metadata_filter: 元数据��滤条件

        Returns:
            检索结果列表，每条包含 id、text_chunk、rrf_score 等
        """
        if collection_name is None:
            collection_name = settings.milvus_knowledge_collection

        # Step 1: 向量语义检索
        vector_results = self._vector_search(
            query=query,
            collection_name=collection_name,
            top_n=settings.rag_vector_top_n,
            metadata_filter=metadata_filter,
        )

        # Step 2: 关键词检索（如果 ES 可用）
        keyword_results = []
        if self._es_client is not None:
            keyword_results = self._keyword_search(
                query=query,
                index_name=collection_name,
                top_n=settings.rag_keyword_top_n,
                metadata_filter=metadata_filter,
            )

        # Step 3: RRF 融合排序
        if keyword_results:
            fused = self._rrf_fusion(vector_results, keyword_results, k=settings.rag_rrf_k)
        else:
            # ES 不可用时，直接用向量检索结果
            fused = vector_results

        final_results = fused[:top_k]

        logger.info(
            "hybrid_retrieval",
            query_length=len(query),
            vector_hits=len(vector_results),
            keyword_hits=len(keyword_results),
            fused_results=len(final_results),
        )
        return final_results

    def _vector_search(
        self,
        query: str,
        collection_name: str,
        top_n: int = 20,
        metadata_filter: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        向量语义检索

        Args:
            query: 查询文本
            collection_name: 集合名称
            top_n: 返回条数
            metadata_filter: 过滤条件

        Returns:
            检索结果列表
        """
        query_embedding = self.embedding_client.encode(query)

        # 构建过滤表达式
        expr = None
        if metadata_filter:
            expr_parts = []
            if "collection_type" in metadata_filter:
                expr_parts.append(
                    f'collection_type == "{metadata_filter["collection_type"]}"'
                )
            if "category" in metadata_filter:
                expr_parts.append(f'category == "{metadata_filter["category"]}"')
            if expr_parts:
                expr = " and ".join(expr_parts)

        output_fields = ["text_chunk", "metadata_json", "doc_id"]
        if collection_name != settings.milvus_knowledge_collection:
            output_fields = ["user_uuid", "skills_json", "category_tags"]

        results = self.milvus_store.search_vectors(
            collection_name=collection_name,
            query_vector=query_embedding,
            top_k=top_n,
            output_fields=output_fields,
            expr=expr,
        )

        # 标准化结果格式
        formatted = []
        for hit in results:
            item = {
                "id": str(hit["id"]),
                "score": hit["distance"],
                "source": "vector",
            }
            for key in output_fields:
                item[key] = hit.get(key, "")
            formatted.append(item)

        return formatted

    def _keyword_search(
        self,
        query: str,
        index_name: str,
        top_n: int = 20,
        metadata_filter: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Elasticsearch BM25 关键词检索

        Args:
            query: 查询文本
            index_name: ES 索引名称
            top_n: 返回条数
            metadata_filter: 过滤条件

        Returns:
            检索结果列表
        """
        if not self._es_client:
            return []

        es_query = {
            "query": {
                "bool": {
                    "must": {
                        "multi_match": {
                            "query": query,
                            "fields": ["text_chunk^2", "metadata_json"],
                            "type": "best_fields",
                        }
                    }
                }
            },
            "size": top_n,
        }

        if metadata_filter:
            filters = []
            for key, value in metadata_filter.items():
                filters.append({"term": {key: value}})
            es_query["query"]["bool"]["filter"] = filters

        try:
            response = self._es_client.search(index=index_name, body=es_query)
            results = []
            for hit in response["hits"]["hits"]:
                results.append(
                    {
                        "id": hit["_id"],
                        "score": hit["_score"],
                        "text_chunk": hit["_source"].get("text_chunk", ""),
                        "metadata_json": hit["_source"].get("metadata_json", ""),
                        "source": "keyword",
                    }
                )
            return results
        except Exception as e:
            logger.warning("ES 关键词检索失败", error=str(e))
            return []

    def _rrf_fusion(
        self,
        vector_results: List[Dict],
        keyword_results: List[Dict],
        k: int = 60,
    ) -> List[Dict[str, Any]]:
        """
        Reciprocal Rank Fusion（RRF）融合排序

        公式：score(d) = sum(1 / (k + rank_i(d)))
        k=60 是经验常数，平衡两路检索结果的权重

        Args:
            vector_results: 向量检索结果
            keyword_results: 关键词检索结果
            k: RRF 常数

        Returns:
            融合排序后的结果列表
        """
        scores = {}
        doc_data = {}

        # 处理向量检索结果
        for rank, hit in enumerate(vector_results):
            doc_id = hit["id"]
            rrf_score = 1.0 / (k + rank + 1)
            scores[doc_id] = scores.get(doc_id, 0) + rrf_score
            if doc_id not in doc_data:
                doc_data[doc_id] = hit

        # 处理关键词检索结果
        for rank, hit in enumerate(keyword_results):
            doc_id = hit["id"]
            rrf_score = 1.0 / (k + rank + 1)
            scores[doc_id] = scores.get(doc_id, 0) + rrf_score
            if doc_id not in doc_data:
                doc_data[doc_id] = hit

        # 按融合分数降序排列
        sorted_ids = sorted(scores.keys(), key=lambda x: scores[x], reverse=True)

        results = []
        for doc_id in sorted_ids:
            item = doc_data[doc_id].copy()
            item["rrf_score"] = round(scores[doc_id], 6)
            results.append(item)

        return results

    def format_rag_context(self, results: List[Dict], max_tokens: int = 2000) -> str:
        """
        将检索结果格式化为可注入 Prompt 的上下文文本

        Args:
            results: 检索结果列表
            max_tokens: 最大 token 数限制

        Returns:
            格式化的上下文文本
        """
        if not results:
            return "未检索到相关的历史项目参考信息。"

        context_parts = []
        total_chars = 0
        max_chars = int(max_tokens * 1.5)  # 粗略估算

        for i, item in enumerate(results):
            text = item.get("text_chunk", "")
            if not text:
                continue

            entry = f"[参考 {i + 1}] {text}"

            if total_chars + len(entry) > max_chars:
                break

            context_parts.append(entry)
            total_chars += len(entry)

        return (
            "\n\n".join(context_parts)
            if context_parts
            else "未检索到相关的历史项目参考信息。"
        )
