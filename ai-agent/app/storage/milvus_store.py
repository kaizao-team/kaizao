"""
开造 VibeBuild — Milvus 向量数据库存储
提供集合创建、向量插入、检索、删除等 CRUD 操作
"""

from typing import List, Dict, Optional, Any

import numpy as np
import structlog
from pymilvus import (
    connections,
    Collection,
    CollectionSchema,
    FieldSchema,
    DataType,
    utility,
)

from app.config import settings

logger = structlog.get_logger()


class MilvusStore:
    """
    Milvus 向量数据库操作封装
    管理三个核心 Collection：
    1. provider_profiles — 供给方画像向量
    2. demand_requirements — 需求向量
    3. project_knowledge — RAG 知识库向量
    """

    def __init__(self):
        self._connected = False

    def connect(self):
        """连接到 Milvus 服务"""
        connections.connect(
            alias="default",
            host=settings.milvus_host,
            port=settings.milvus_port,
        )
        self._connected = True
        logger.info(
            "Milvus 连接成功",
            host=settings.milvus_host,
            port=settings.milvus_port,
        )
        self._ensure_collections()

    def disconnect(self):
        """断开 Milvus 连接"""
        if self._connected:
            connections.disconnect("default")
            self._connected = False
            logger.info("Milvus 连接已断开")

    def _ensure_collections(self):
        """确保所有必要的 Collection 已创建"""
        self._ensure_provider_collection()
        self._ensure_demand_collection()
        self._ensure_knowledge_collection()

    def _ensure_provider_collection(self):
        """创建供给方画像向量集合"""
        name = settings.milvus_provider_collection
        if utility.has_collection(name):
            logger.info(f"Collection '{name}' 已存在")
            return

        fields = [
            FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
            FieldSchema(name="user_uuid", dtype=DataType.VARCHAR, max_length=64),
            FieldSchema(
                name="vector",
                dtype=DataType.FLOAT_VECTOR,
                dim=settings.embedding_dimension,
            ),
            FieldSchema(name="skills_json", dtype=DataType.VARCHAR, max_length=2048),
            FieldSchema(name="category_tags", dtype=DataType.VARCHAR, max_length=512),
            FieldSchema(name="avg_rating", dtype=DataType.FLOAT),
            FieldSchema(name="credit_score", dtype=DataType.INT32),
            FieldSchema(name="is_active", dtype=DataType.BOOL),
            FieldSchema(name="updated_at", dtype=DataType.INT64),
        ]
        schema = CollectionSchema(fields=fields, description="供给方画像向量")
        collection = Collection(name=name, schema=schema)

        collection.create_index(
            field_name="vector",
            index_params={
                "metric_type": "IP",
                "index_type": "IVF_FLAT",
                "params": {"nlist": 256},
            },
        )
        logger.info(f"Collection '{name}' 创建完成")

    def _ensure_demand_collection(self):
        """创建需求向量集合"""
        name = settings.milvus_demand_collection
        if utility.has_collection(name):
            logger.info(f"Collection '{name}' 已存在")
            return

        fields = [
            FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
            FieldSchema(name="demand_uuid", dtype=DataType.VARCHAR, max_length=64),
            FieldSchema(
                name="vector",
                dtype=DataType.FLOAT_VECTOR,
                dim=settings.embedding_dimension,
            ),
            FieldSchema(name="category", dtype=DataType.VARCHAR, max_length=32),
            FieldSchema(name="complexity", dtype=DataType.VARCHAR, max_length=4),
            FieldSchema(name="budget_max", dtype=DataType.FLOAT),
            FieldSchema(name="status", dtype=DataType.INT32),
            FieldSchema(name="created_at", dtype=DataType.INT64),
        ]
        schema = CollectionSchema(fields=fields, description="需求向量")
        collection = Collection(name=name, schema=schema)

        collection.create_index(
            field_name="vector",
            index_params={
                "metric_type": "IP",
                "index_type": "IVF_FLAT",
                "params": {"nlist": 256},
            },
        )
        logger.info(f"Collection '{name}' 创建完成")

    def _ensure_knowledge_collection(self):
        """创建 RAG 知识库向量集合"""
        name = settings.milvus_knowledge_collection
        if utility.has_collection(name):
            logger.info(f"Collection '{name}' 已存在")
            return

        fields = [
            FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
            FieldSchema(name="doc_id", dtype=DataType.VARCHAR, max_length=64),
            FieldSchema(
                name="embedding",
                dtype=DataType.FLOAT_VECTOR,
                dim=settings.embedding_dimension,
            ),
            FieldSchema(name="text_chunk", dtype=DataType.VARCHAR, max_length=4096),
            FieldSchema(name="metadata_json", dtype=DataType.VARCHAR, max_length=2048),
            FieldSchema(name="collection_type", dtype=DataType.VARCHAR, max_length=32),
        ]
        schema = CollectionSchema(fields=fields, description="RAG 知识库向量")
        collection = Collection(name=name, schema=schema)

        collection.create_index(
            field_name="embedding",
            index_params={
                "metric_type": "IP",
                "index_type": "IVF_FLAT",
                "params": {"nlist": 256},
            },
        )
        logger.info(f"Collection '{name}' 创建完成")

    def insert_vectors(
        self,
        collection_name: str,
        data: List[Dict[str, Any]],
    ) -> List[int]:
        """
        向集合中插入向量数据

        Args:
            collection_name: 集合名称
            data: 数据列表，每条包含向量和元数据字段

        Returns:
            插入的主键 ID 列表
        """
        collection = Collection(collection_name)
        result = collection.insert(data)
        collection.flush()
        logger.info(
            "milvus_insert",
            collection=collection_name,
            count=len(data) if isinstance(data, list) else 1,
        )
        return result.primary_keys

    def search_vectors(
        self,
        collection_name: str,
        query_vector: np.ndarray,
        top_k: int = 10,
        output_fields: Optional[List[str]] = None,
        expr: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        向量相似度检索

        Args:
            collection_name: 集合名称
            query_vector: 查询向量
            top_k: 返回 Top-K 结果
            output_fields: 需要返回的字段列表
            expr: Milvus 过滤表达式

        Returns:
            检索结果列表，每条包含 id、distance、以及指定的���出字段
        """
        collection = Collection(collection_name)
        collection.load()

        # 确定向量字段名
        vector_field = "vector"
        if collection_name == settings.milvus_knowledge_collection:
            vector_field = "embedding"

        search_params = {"metric_type": "IP", "params": {"nprobe": 16}}

        results = collection.search(
            data=[query_vector.tolist()],
            anns_field=vector_field,
            param=search_params,
            limit=top_k,
            output_fields=output_fields or [],
            expr=expr,
        )

        hits = []
        for hit in results[0]:
            item = {
                "id": hit.id,
                "distance": hit.distance,
            }
            for field in output_fields or []:
                item[field] = hit.entity.get(field)
            hits.append(item)

        logger.info(
            "milvus_search",
            collection=collection_name,
            top_k=top_k,
            hits_count=len(hits),
        )
        return hits

    def delete_by_expr(self, collection_name: str, expr: str) -> int:
        """
        按表达式删除向量

        Args:
            collection_name: 集合名称
            expr: 删除表达式，如 'user_uuid == "xxx"'

        Returns:
            删除的记录数
        """
        collection = Collection(collection_name)
        result = collection.delete(expr)
        collection.flush()
        logger.info(
            "milvus_delete",
            collection=collection_name,
            expr=expr,
        )
        return result.delete_count

    def upsert_provider_vector(
        self,
        user_uuid: str,
        vector: np.ndarray,
        skills_json: str,
        category_tags: str,
        avg_rating: float,
        credit_score: int,
        is_active: bool,
        updated_at: int,
    ):
        """
        更新或插入供给方画像向量（先删后插实现 upsert）

        Args:
            user_uuid: 用户 UUID
            vector: 画像向量
            skills_json: 技能 JSON 字符串
            category_tags: 类别标签
            avg_rating: 平均评分
            credit_score: 信用分
            is_active: 是否活跃
            updated_at: 更新时间戳
        """
        name = settings.milvus_provider_collection
        # 先删除旧向量
        self.delete_by_expr(name, f'user_uuid == "{user_uuid}"')

        # 插入新向量
        data = [
            {
                "user_uuid": user_uuid,
                "vector": vector.tolist(),
                "skills_json": skills_json,
                "category_tags": category_tags,
                "avg_rating": avg_rating,
                "credit_score": credit_score,
                "is_active": is_active,
                "updated_at": updated_at,
            }
        ]
        self.insert_vectors(name, data)

    def upsert_demand_vector(
        self,
        demand_uuid: str,
        vector: np.ndarray,
        category: str,
        complexity: str,
        budget_max: float,
        status: int,
        created_at: int,
    ):
        """
        更新或插入需求向量

        Args:
            demand_uuid: 需求 UUID
            vector: 需求向量
            category: 类别
            complexity: 复杂度
            budget_max: 最大预算
            status: 状态
            created_at: 创建时间戳
        """
        name = settings.milvus_demand_collection
        self.delete_by_expr(name, f'demand_uuid == "{demand_uuid}"')

        data = [
            {
                "demand_uuid": demand_uuid,
                "vector": vector.tolist(),
                "category": category,
                "complexity": complexity,
                "budget_max": budget_max,
                "status": status,
                "created_at": created_at,
            }
        ]
        self.insert_vectors(name, data)

    def insert_knowledge_chunk(
        self,
        doc_id: str,
        embedding: np.ndarray,
        text_chunk: str,
        metadata_json: str,
        collection_type: str,
    ):
        """
        向知识库插入文档片段向量

        Args:
            doc_id: 文档 ID
            embedding: 文档片段向量
            text_chunk: 文本内容
            metadata_json: 元数据 JSON
            collection_type: 知识库类型（project / tech / case）
        """
        name = settings.milvus_knowledge_collection
        data = [
            {
                "doc_id": doc_id,
                "embedding": embedding.tolist(),
                "text_chunk": text_chunk,
                "metadata_json": metadata_json,
                "collection_type": collection_type,
            }
        ]
        self.insert_vectors(name, data)
