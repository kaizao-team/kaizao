"""
开造 VibeBuild — Embedding 向量化客户端
支持 DashScope Embedding API（MVP 阶段）和本地 BGE-M3 模型
"""

from typing import List, Optional

import numpy as np
import structlog

from app.config import settings

logger = structlog.get_logger()


class EmbeddingClient:
    """
    Embedding 向量化客户端
    - MVP 阶段使用 DashScope Embedding API（无需 GPU）
    - 后期可切换到本地部署的 BGE-M3
    """

    def __init__(self):
        self.provider = settings.embedding_provider
        self.dimension = settings.embedding_dimension
        self._local_model = None

        if self.provider == "local":
            self._load_local_model()

        logger.info(
            "EmbeddingClient 初始化完成",
            provider=self.provider,
            dimension=self.dimension,
        )

    def _load_local_model(self):
        """加载本地 BGE-M3 模型"""
        try:
            from sentence_transformers import SentenceTransformer

            self._local_model = SentenceTransformer(settings.local_embedding_model_path)
            logger.info("本地 BGE-M3 模型加载完成")
        except Exception as e:
            logger.error("本地 BGE-M3 模型加载失败", error=str(e))
            raise

    def encode(self, text: str) -> np.ndarray:
        """
        将单条文本编码为向量

        Args:
            text: 输入文本

        Returns:
            768 维 numpy 向量
        """
        if self.provider == "local":
            return self._encode_local(text)
        return self._encode_dashscope([text])[0]

    def encode_batch(self, texts: List[str], batch_size: int = 32) -> List[np.ndarray]:
        """
        批量文本编码

        Args:
            texts: 文本列表
            batch_size: 批处理大小

        Returns:
            向量列表
        """
        if not texts:
            return []

        if self.provider == "local":
            return self._encode_local_batch(texts, batch_size)

        all_vectors = []
        for i in range(0, len(texts), batch_size):
            batch = texts[i: i + batch_size]
            vectors = self._encode_dashscope(batch)
            all_vectors.extend(vectors)

        return all_vectors

    def _encode_local(self, text: str) -> np.ndarray:
        """使用本地 BGE-M3 模型编码"""
        if self._local_model is None:
            raise RuntimeError("本地模型未加载")
        vector = self._local_model.encode(text, normalize_embeddings=True)
        # 如果维度超过目标维度，截断（Matryoshka 降维）
        if len(vector) > self.dimension:
            vector = vector[: self.dimension]
        return np.array(vector, dtype=np.float32)

    def _encode_local_batch(self, texts: List[str], batch_size: int = 32) -> List[np.ndarray]:
        """使用本地模型批量编码"""
        if self._local_model is None:
            raise RuntimeError("本地模型未加载")
        vectors = self._local_model.encode(
            texts, batch_size=batch_size, normalize_embeddings=True
        )
        result = []
        for v in vectors:
            if len(v) > self.dimension:
                v = v[: self.dimension]
            result.append(np.array(v, dtype=np.float32))
        return result

    def _encode_dashscope(self, texts: List[str]) -> List[np.ndarray]:
        """
        调用 DashScope Embedding API

        Args:
            texts: 文本列表

        Returns:
            向量列表
        """
        import dashscope
        from dashscope import TextEmbedding

        dashscope.api_key = settings.dashscope_api_key

        response = TextEmbedding.call(
            model=settings.dashscope_embedding_model,
            input=texts,
            dimension=self.dimension,
        )

        if response.status_code != 200:
            raise RuntimeError(
                f"DashScope Embedding API 错误: status={response.status_code}, "
                f"code={response.code}, message={response.message}"
            )

        vectors = []
        for item in response.output["embeddings"]:
            vectors.append(np.array(item["embedding"], dtype=np.float32))

        return vectors

    def compute_similarity(self, vec_a: np.ndarray, vec_b: np.ndarray) -> float:
        """
        计算两个向量的余弦相似度

        Args:
            vec_a: 向量 A
            vec_b: 向量 B

        Returns:
            相似度分数 [0, 1]
        """
        dot_product = np.dot(vec_a, vec_b)
        norm_a = np.linalg.norm(vec_a) + 1e-8
        norm_b = np.linalg.norm(vec_b) + 1e-8
        cosine_sim = dot_product / (norm_a * norm_b)
        # 归一化到 [0, 1]
        return float((cosine_sim + 1) / 2)
