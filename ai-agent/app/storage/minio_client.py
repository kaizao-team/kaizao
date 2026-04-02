"""
开造 VibeBuild — Minio 对象存储客户端
AI 文档持久化存储，bucket = 'ai-documents'
"""

from io import BytesIO
from typing import Optional

import structlog
from minio import Minio
from minio.error import S3Error

from app.config import settings

logger = structlog.get_logger()


class MinioDocStore:
    """AI 文档对象存储"""

    def __init__(self):
        self._client: Optional[Minio] = None
        self._bucket = settings.minio_bucket

    def connect(self) -> None:
        """连接 Minio，确保 bucket 存在"""
        self._client = Minio(
            endpoint=settings.minio_endpoint,
            access_key=settings.minio_access_key,
            secret_key=settings.minio_secret_key,
            secure=settings.minio_use_ssl,
        )
        if not self._client.bucket_exists(self._bucket):
            self._client.make_bucket(self._bucket)
            logger.info("minio_bucket_created", bucket=self._bucket)
        logger.info("minio_connected", endpoint=settings.minio_endpoint, bucket=self._bucket)

    def _ensure_client(self) -> Minio:
        if self._client is None:
            raise RuntimeError("MinioDocStore 未连接，请先调用 connect()")
        return self._client

    def upload(self, project_id: str, filename: str, content: str, version: int = 1) -> str:
        """
        上传文档内容到 Minio。

        Args:
            project_id: 项目 UUID
            filename: 文件名
            content: 文档文本内容
            version: 版本号

        Returns:
            object_key (e.g. projects/{project_id}/v{n}/{filename})
        """
        client = self._ensure_client()
        object_key = f"projects/{project_id}/v{version}/{filename}"
        data = content.encode("utf-8")
        stream = BytesIO(data)

        try:
            client.put_object(
                bucket_name=self._bucket,
                object_name=object_key,
                data=stream,
                length=len(data),
                content_type="text/markdown; charset=utf-8",
            )
            logger.info("minio_upload_ok", object_key=object_key, size=len(data))
            return object_key
        except S3Error as e:
            logger.error("minio_upload_failed", object_key=object_key, error=str(e))
            raise

    def download_url(self, object_key: str, expires_hours: int = 1) -> str:
        """返回预签名下载 URL"""
        from datetime import timedelta
        client = self._ensure_client()
        return client.presigned_get_object(
            bucket_name=self._bucket,
            object_name=object_key,
            expires=timedelta(hours=expires_hours),
        )

    def get_object(self, object_key: str) -> bytes:
        """直接获取对象内容"""
        client = self._ensure_client()
        try:
            response = client.get_object(self._bucket, object_key)
            return response.read()
        finally:
            if 'response' in locals():
                response.close()
                response.release_conn()
