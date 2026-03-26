"""
开造 VibeBuild — 文档写入器
将 Agent 产出的 Markdown 文档写入文件系统
输出结构：outputs/{project_id}/v{n}/{filename}.md
"""

import os
from pathlib import Path
from typing import Optional

import structlog

from app.config import settings

logger = structlog.get_logger()

# 默认输出根目录
OUTPUT_ROOT = Path(os.getenv("VIBEBUILD_OUTPUT_DIR", "outputs"))


class DocumentWriter:
    """文档写入器：管理版本化的文档输出"""

    def __init__(self, output_root: Optional[Path] = None):
        self.root = output_root or OUTPUT_ROOT

    def _project_dir(self, project_id: str) -> Path:
        return self.root / project_id

    def _latest_version(self, project_id: str) -> int:
        """获取项目最新版本号"""
        project_dir = self._project_dir(project_id)
        if not project_dir.exists():
            return 0
        versions = [
            int(d.name[1:])
            for d in project_dir.iterdir()
            if d.is_dir() and d.name.startswith("v") and d.name[1:].isdigit()
        ]
        return max(versions) if versions else 0

    def _version_dir(self, project_id: str, version: Optional[int] = None) -> Path:
        if version is None:
            version = self._latest_version(project_id)
            if version == 0:
                version = 1
        return self._project_dir(project_id) / f"v{version}"

    def save_document(
        self,
        project_id: str,
        filename: str,
        content: str,
        version: Optional[int] = None,
        stage: Optional[str] = None,
    ) -> str:
        """
        保存文档到文件系统，并异步写入 MySQL documents 表

        Args:
            project_id: 项目 ID
            filename: 文件名（如 requirement.md）
            content: Markdown 内容
            version: 版本号，None 则使用最新版本
            stage: 阶段名（如 requirement），用于 MySQL 记录

        Returns:
            写入的文件路径（相对路径）
        """
        ver_dir = self._version_dir(project_id, version)
        ver_dir.mkdir(parents=True, exist_ok=True)

        file_path = ver_dir / filename
        file_path.write_text(content, encoding="utf-8")

        relative_path = str(file_path)
        actual_version = version or self._latest_version(project_id) or 1
        logger.info("document_saved", project_id=project_id, path=relative_path)

        # 异步写入 MySQL documents 表（fire-and-forget）
        self._save_document_to_db(
            project_id=project_id,
            stage=stage or "",
            filename=filename,
            file_path=relative_path,
            version=actual_version,
            size_bytes=len(content.encode("utf-8")),
        )

        return relative_path

    @staticmethod
    def _save_document_to_db(
        project_id: str,
        stage: str,
        filename: str,
        file_path: str,
        version: int,
        size_bytes: int,
    ):
        """尝试将文档元信息写入 MySQL（同步触发异步任务）"""
        import asyncio

        async def _do_save():
            try:
                from app.db.repository import ProjectRepository
                repo = ProjectRepository()
                await repo.save_document_record(
                    project_id=project_id,
                    stage=stage,
                    filename=filename,
                    file_path=file_path,
                    version=version,
                    size_bytes=size_bytes,
                )
            except Exception as e:
                logger.warning(f"MySQL 写入文档记录失败: {e}")

        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_do_save())
        except RuntimeError:
            pass  # 没有事件循环则跳过

    def read_document(
        self,
        project_id: str,
        filename: str,
        version: Optional[int] = None,
    ) -> Optional[str]:
        """读取文档内容"""
        ver_dir = self._version_dir(project_id, version)
        file_path = ver_dir / filename
        if not file_path.exists():
            return None
        return file_path.read_text(encoding="utf-8")

    def new_version(self, project_id: str) -> int:
        """创建新版本，返回版本号"""
        version = self._latest_version(project_id) + 1
        ver_dir = self._version_dir(project_id, version)
        ver_dir.mkdir(parents=True, exist_ok=True)
        return version

    def list_documents(self, project_id: str, version: Optional[int] = None) -> list[str]:
        """列出指定版本的所有文档"""
        ver_dir = self._version_dir(project_id, version)
        if not ver_dir.exists():
            return []
        return [f.name for f in ver_dir.iterdir() if f.is_file()]

    def get_document_path(self, project_id: str, filename: str, version: Optional[int] = None) -> str:
        """获取文档路径"""
        return str(self._version_dir(project_id, version) / filename)
