"""
开造 VibeBuild — 异步 CRUD 操作封装
ProjectRepository: 读写 Go 后端 kaizao.projects + AI 独有的 ai_* 表
RatingRepository: 读写 ai_provider_profiles / ai_vibe_power_logs
"""

import json
from datetime import datetime
from typing import Optional

import structlog
from sqlalchemy import select, delete, update
from sqlalchemy.dialects.mysql import insert as mysql_insert

from app.db.engine import get_session_factory
from app.db.models import (
    AIConversationMessage,
    AIDocument,
    AIEarsTask,
    AIMilestone,
    AIMatchResult,
    AIPrdItem,
    AIProjectStage,
    AIProviderProfile,
    AIVibePowerLog,
    Project,
    User,
)

logger = structlog.get_logger()


class ProjectRepository:
    """项目持久化仓库 — 以 Go 后端 projects.uuid 为关联键"""

    # ---- 项目 CRUD ----

    async def save_project(self, project_id: str, state: dict) -> None:
        """
        保存/更新项目的 AI 流水线状态。

        project_id 是 Go 后端 projects.uuid。
        - 对 projects 表：仅 UPDATE ai_prd / ai_estimate / confirmed_prd
        - 对 ai_project_stages 表：upsert 各阶段状态
        """
        async with get_session_factory()() as session:
            async with session.begin():
                # UPDATE Go 后端 projects 表的 AI 字段（如果有数据）
                ai_updates = {}
                if state.get("ai_prd"):
                    ai_updates["ai_prd"] = state["ai_prd"]
                if state.get("ai_estimate"):
                    ai_updates["ai_estimate"] = state["ai_estimate"]
                if state.get("confirmed_prd"):
                    ai_updates["confirmed_prd"] = state["confirmed_prd"]

                if ai_updates:
                    ai_updates["updated_at"] = datetime.now()
                    await session.execute(
                        update(Project)
                        .where(Project.uuid == project_id)
                        .values(**ai_updates)
                    )

                # upsert 各阶段状态到 ai_project_stages
                for stage_name in ("requirement", "design", "task", "pm"):
                    stage_data = state.get(stage_name, {})
                    if isinstance(stage_data, dict):
                        stage_stmt = mysql_insert(AIProjectStage).values(
                            project_id=project_id,
                            stage_name=stage_name,
                            status=stage_data.get("status", "pending"),
                            sub_stage=stage_data.get("sub_stage"),
                            document_path=stage_data.get("document_path"),
                            error_message=stage_data.get("error_message"),
                            started_at=_parse_dt(stage_data.get("started_at")),
                            completed_at=_parse_dt(stage_data.get("completed_at")),
                        )
                        stage_stmt = stage_stmt.on_duplicate_key_update(
                            status=stage_stmt.inserted.status,
                            sub_stage=stage_stmt.inserted.sub_stage,
                            document_path=stage_stmt.inserted.document_path,
                            error_message=stage_stmt.inserted.error_message,
                            started_at=stage_stmt.inserted.started_at,
                            completed_at=stage_stmt.inserted.completed_at,
                        )
                        await session.execute(stage_stmt)

    async def get_project(self, project_id: str) -> Optional[dict]:
        """
        从 kaizao.projects 按 uuid 查找项目，合并 ai_project_stages 数据，
        返回 ProjectState 格式的 dict。
        """
        async with get_session_factory()() as session:
            # 按 uuid 查找 Go 后端的 project
            q = await session.execute(
                select(Project).where(Project.uuid == project_id)
            )
            project = q.scalars().first()
            if not project:
                return None

            result = {
                "project_id": project.uuid,  # AI 侧统一用 uuid 作为 project_id
                "title": project.title or "",
                "current_stage": "requirement",  # 默认值，下面从 stages 推断
                "version": 1,
                "session_id": None,
                "created_at": project.created_at.isoformat() if project.created_at else None,
                "updated_at": project.updated_at.isoformat() if project.updated_at else None,
            }

            # 读取 AI 阶段状态
            stages_q = await session.execute(
                select(AIProjectStage).where(AIProjectStage.project_id == project_id)
            )
            last_active_stage = "requirement"
            for stage in stages_q.scalars().all():
                result[stage.stage_name] = {
                    "status": stage.status,
                    "sub_stage": stage.sub_stage,
                    "document_path": stage.document_path,
                    "error_message": stage.error_message,
                    "started_at": stage.started_at.isoformat() if stage.started_at else None,
                    "completed_at": stage.completed_at.isoformat() if stage.completed_at else None,
                }
                if stage.status in ("running", "awaiting_confirmation", "confirmed"):
                    last_active_stage = stage.stage_name

            result["current_stage"] = last_active_stage
            return result

    async def verify_project_exists(self, project_id: str) -> bool:
        """验证 Go 后端 projects 表中是否存在指定 uuid 的项目"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(Project.uuid).where(Project.uuid == project_id)
            )
            return q.scalars().first() is not None

    async def delete_project(self, project_id: str) -> None:
        """只删除 AI 阶段数据，不动 Go 后端的 projects 行"""
        async with get_session_factory()() as session:
            async with session.begin():
                await session.execute(
                    delete(AIProjectStage).where(AIProjectStage.project_id == project_id)
                )

    # ---- 文档记录 ----

    async def save_document_record(
        self,
        project_id: str,
        stage: str,
        filename: str,
        file_path: str,
        version: int = 1,
        size_bytes: int = 0,
    ) -> None:
        """保存文档元信息"""
        async with get_session_factory()() as session:
            async with session.begin():
                stmt = mysql_insert(AIDocument).values(
                    project_id=project_id,
                    stage=stage,
                    filename=filename,
                    file_path=file_path,
                    version=version,
                    size_bytes=size_bytes,
                )
                stmt = stmt.on_duplicate_key_update(
                    file_path=stmt.inserted.file_path,
                    size_bytes=stmt.inserted.size_bytes,
                    stage=stmt.inserted.stage,
                )
                await session.execute(stmt)

    async def get_documents(self, project_id: str) -> list[dict]:
        """获取项目所有文档记录"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIDocument).where(AIDocument.project_id == project_id)
            )
            return [
                {
                    "id": doc.id,
                    "stage": doc.stage,
                    "filename": doc.filename,
                    "file_path": doc.file_path,
                    "version": doc.version,
                    "size_bytes": doc.size_bytes,
                    "created_at": doc.created_at.isoformat() if doc.created_at else None,
                }
                for doc in q.scalars().all()
            ]

    # ---- 智能撮合查询 ----

    async def get_project_for_matching(self, project_uuid: str) -> Optional[dict]:
        """
        读取项目详情供智能撮合使用。
        返回需求侧关键字段：title, description, category, complexity,
        tech_requirements, budget_min, budget_max, match_mode。
        """
        async with get_session_factory()() as session:
            q = await session.execute(
                select(Project).where(Project.uuid == project_uuid)
            )
            p = q.scalars().first()
            if not p:
                return None

            tech_stack = []
            if p.tech_requirements:
                try:
                    raw = p.tech_requirements
                    if isinstance(raw, str):
                        tech_stack = json.loads(raw)
                    elif isinstance(raw, list):
                        tech_stack = raw
                except (json.JSONDecodeError, TypeError):
                    pass

            return {
                "demand_id": p.uuid,
                "title": p.title or "",
                "description": p.description or "",
                "category": p.category or "",
                "complexity": p.complexity or "M",
                "tech_stack": tech_stack,
                "budget_min": float(p.budget_min) if p.budget_min is not None else 0,
                "budget_max": float(p.budget_max) if p.budget_max is not None else 0,
                "match_mode": p.match_mode,
            }

    async def batch_get_users_by_uuids(self, uuids: list[str]) -> dict[str, dict]:
        """
        批量查询用户信息，供撮合评分时丰富供给方数据。
        返回 {uuid: user_dict} 映射。
        """
        if not uuids:
            return {}
        async with get_session_factory()() as session:
            q = await session.execute(
                select(User).where(User.uuid.in_(uuids))
            )
            result = {}
            for u in q.scalars().all():
                result[u.uuid] = {
                    "user_uuid": u.uuid,
                    "nickname": u.nickname,
                    "avatar_url": u.avatar_url,
                    "role": u.role,
                    "is_verified": u.is_verified,
                    "hourly_rate": float(u.hourly_rate) if u.hourly_rate is not None else 0,
                    "response_time_avg": u.response_time_avg,
                    "credit_score": u.credit_score,
                    "level": u.level,
                    "total_orders": u.total_orders,
                    "completed_orders": u.completed_orders,
                    "completion_rate": float(u.completion_rate),
                    "avg_rating": float(u.avg_rating),
                    "available_status": u.available_status,
                    "onboarding_status": u.onboarding_status,
                    "created_at": u.created_at.isoformat() if u.created_at else None,
                }
            return result

    # ---- 对话消息 ----

    async def save_messages(
        self,
        session_id: str,
        messages: list[dict],
        project_id: Optional[str] = None,
    ) -> None:
        """批量保存对话消息（全量覆盖写入）"""
        async with get_session_factory()() as session:
            async with session.begin():
                await session.execute(
                    delete(AIConversationMessage).where(
                        AIConversationMessage.session_id == session_id
                    )
                )
                for idx, msg in enumerate(messages):
                    content = msg.get("content", "")
                    if not isinstance(content, str):
                        content = json.dumps(content, ensure_ascii=False, default=str)
                    session.add(AIConversationMessage(
                        session_id=session_id,
                        project_id=project_id,
                        role=msg.get("role", "unknown"),
                        content=content,
                        message_index=idx,
                    ))

    async def get_messages(self, session_id: str) -> list[dict]:
        """读取对话消息"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIConversationMessage)
                .where(AIConversationMessage.session_id == session_id)
                .order_by(AIConversationMessage.message_index)
            )
            results = []
            for msg in q.scalars().all():
                content = msg.content
                try:
                    content = json.loads(content)
                except (json.JSONDecodeError, TypeError):
                    pass
                results.append({"role": msg.role, "content": content})
            return results

    # ---- 撮合结果 ----

    async def save_match_results(
        self, project_id: str, recommendations: list[dict], match_type: str = "recommend_providers"
    ) -> None:
        """批量写入撮合推荐结果"""
        async with get_session_factory()() as session:
            async with session.begin():
                for rec in recommendations:
                    session.add(AIMatchResult(
                        project_id=project_id,
                        provider_user_uuid=rec.get("provider_id", ""),
                        rank=rec.get("rank", 0),
                        match_score=rec.get("match_score", 0),
                        dimension_scores=rec.get("dimension_scores"),
                        recommendation_reason=rec.get("recommendation_reason", ""),
                        highlight_skills=rec.get("highlight_skills"),
                        match_type=match_type,
                    ))

    async def get_match_results(self, project_id: str) -> list[dict]:
        """查询历史撮合结果"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIMatchResult)
                .where(AIMatchResult.project_id == project_id)
                .order_by(AIMatchResult.created_at.desc())
            )
            return [
                {
                    "id": r.id,
                    "project_id": r.project_id,
                    "provider_user_uuid": r.provider_user_uuid,
                    "rank": r.rank,
                    "match_score": float(r.match_score),
                    "dimension_scores": r.dimension_scores,
                    "recommendation_reason": r.recommendation_reason,
                    "highlight_skills": r.highlight_skills,
                    "match_type": r.match_type,
                    "created_at": r.created_at.isoformat() if r.created_at else None,
                }
                for r in q.scalars().all()
            ]

    # ---- PRD 条目 ----

    async def save_prd_items(self, project_id: str, items: list[dict], version: int = 1) -> None:
        """批量写入 PRD 需求条目"""
        async with get_session_factory()() as session:
            async with session.begin():
                for item in items:
                    stmt = mysql_insert(AIPrdItem).values(
                        project_id=project_id,
                        item_id=item.get("item_id", ""),
                        module_name=item.get("module_name", ""),
                        title=item.get("title", ""),
                        description=item.get("description", ""),
                        priority=item.get("priority", "P1"),
                        acceptance_summary=item.get("acceptance_summary", ""),
                        version=version,
                    )
                    stmt = stmt.on_duplicate_key_update(
                        title=stmt.inserted.title,
                        description=stmt.inserted.description,
                        priority=stmt.inserted.priority,
                        acceptance_summary=stmt.inserted.acceptance_summary,
                        module_name=stmt.inserted.module_name,
                    )
                    await session.execute(stmt)

    async def get_prd_items(self, project_id: str) -> list[dict]:
        """查询 PRD 需求条目"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIPrdItem)
                .where(AIPrdItem.project_id == project_id)
                .order_by(AIPrdItem.item_id)
            )
            return [
                {
                    "id": r.id,
                    "project_id": r.project_id,
                    "item_id": r.item_id,
                    "module_name": r.module_name,
                    "title": r.title,
                    "description": r.description,
                    "priority": r.priority,
                    "acceptance_summary": r.acceptance_summary,
                    "version": r.version,
                    "created_at": r.created_at.isoformat() if r.created_at else None,
                }
                for r in q.scalars().all()
            ]

    # ---- EARS 任务卡片 ----

    async def save_ears_tasks(self, project_id: str, tasks: list[dict], version: int = 1) -> None:
        """批量写入 EARS 任务卡片"""
        async with get_session_factory()() as session:
            async with session.begin():
                for task in tasks:
                    stmt = mysql_insert(AIEarsTask).values(
                        project_id=project_id,
                        task_id=task.get("task_id", ""),
                        feature_item_id=task.get("feature_item_id", ""),
                        ears_type=task.get("ears_type", ""),
                        ears_statement=task.get("ears_statement", ""),
                        module=task.get("module", ""),
                        role_tag=task.get("role_tag", "fullstack"),
                        priority=task.get("priority", 3),
                        estimated_hours=task.get("estimated_hours"),
                        acceptance_criteria=task.get("acceptance_criteria"),
                        dependencies=task.get("dependencies"),
                        version=version,
                    )
                    stmt = stmt.on_duplicate_key_update(
                        ears_type=stmt.inserted.ears_type,
                        ears_statement=stmt.inserted.ears_statement,
                        module=stmt.inserted.module,
                        role_tag=stmt.inserted.role_tag,
                        priority=stmt.inserted.priority,
                        estimated_hours=stmt.inserted.estimated_hours,
                        acceptance_criteria=stmt.inserted.acceptance_criteria,
                        dependencies=stmt.inserted.dependencies,
                    )
                    await session.execute(stmt)

    async def get_ears_tasks(self, project_id: str) -> list[dict]:
        """查询 EARS 任务卡片"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIEarsTask)
                .where(AIEarsTask.project_id == project_id)
                .order_by(AIEarsTask.task_id)
            )
            return [
                {
                    "id": r.id,
                    "project_id": r.project_id,
                    "task_id": r.task_id,
                    "feature_item_id": r.feature_item_id,
                    "ears_type": r.ears_type,
                    "ears_statement": r.ears_statement,
                    "module": r.module,
                    "role_tag": r.role_tag,
                    "priority": r.priority,
                    "estimated_hours": float(r.estimated_hours) if r.estimated_hours else None,
                    "acceptance_criteria": r.acceptance_criteria,
                    "dependencies": r.dependencies,
                    "adjustment_count": r.adjustment_count,
                    "version": r.version,
                    "created_at": r.created_at.isoformat() if r.created_at else None,
                }
                for r in q.scalars().all()
            ]

    async def get_ears_task(self, project_id: str, task_id: str) -> Optional[dict]:
        """查询单个 EARS 卡片"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIEarsTask)
                .where(AIEarsTask.project_id == project_id, AIEarsTask.task_id == task_id)
                .order_by(AIEarsTask.version.desc())
                .limit(1)
            )
            r = q.scalars().first()
            if not r:
                return None
            return {
                "id": r.id,
                "project_id": r.project_id,
                "task_id": r.task_id,
                "feature_item_id": r.feature_item_id,
                "ears_type": r.ears_type,
                "ears_statement": r.ears_statement,
                "module": r.module,
                "role_tag": r.role_tag,
                "priority": r.priority,
                "estimated_hours": float(r.estimated_hours) if r.estimated_hours else None,
                "acceptance_criteria": r.acceptance_criteria,
                "dependencies": r.dependencies,
                "adjustment_count": r.adjustment_count,
                "version": r.version,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }

    async def update_ears_task(self, project_id: str, task_id: str, changes: dict) -> dict:
        """
        更新单个 EARS 卡片，含 adjustment_count++ 检查（上限 3 次）。
        返回更新后的卡片或 error dict。
        """
        allowed_fields = {"ears_statement", "priority", "estimated_hours", "acceptance_criteria"}
        async with get_session_factory()() as session:
            async with session.begin():
                q = await session.execute(
                    select(AIEarsTask)
                    .where(AIEarsTask.project_id == project_id, AIEarsTask.task_id == task_id)
                    .order_by(AIEarsTask.version.desc())
                    .limit(1)
                    .with_for_update()
                )
                task = q.scalars().first()
                if not task:
                    return {"error": f"EARS task {task_id} not found"}
                if task.adjustment_count >= 3:
                    return {"error": f"EARS task {task_id} has reached adjustment limit (3)"}

                for field, value in changes.items():
                    if field in allowed_fields:
                        setattr(task, field, value)
                task.adjustment_count += 1

                return {
                    "task_id": task.task_id,
                    "adjustment_count": task.adjustment_count,
                    "status": "updated",
                }

    # ---- 里程碑 ----

    async def save_milestones(self, project_id: str, milestones: list[dict]) -> None:
        """批量写入里程碑"""
        async with get_session_factory()() as session:
            async with session.begin():
                for idx, ms in enumerate(milestones):
                    stmt = mysql_insert(AIMilestone).values(
                        project_id=project_id,
                        milestone_index=idx + 1,
                        title=ms.get("title", f"里程碑 {idx + 1}"),
                        duration_days=ms.get("duration_days"),
                        payment_ratio=ms.get("payment_ratio"),
                        deliverables=ms.get("deliverables"),
                        status="pending",
                    )
                    stmt = stmt.on_duplicate_key_update(
                        title=stmt.inserted.title,
                        duration_days=stmt.inserted.duration_days,
                        payment_ratio=stmt.inserted.payment_ratio,
                        deliverables=stmt.inserted.deliverables,
                    )
                    await session.execute(stmt)

    async def get_milestones(self, project_id: str) -> list[dict]:
        """查询里程碑列表"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIMilestone)
                .where(AIMilestone.project_id == project_id)
                .order_by(AIMilestone.milestone_index)
            )
            return [
                {
                    "id": r.id,
                    "project_id": r.project_id,
                    "milestone_index": r.milestone_index,
                    "title": r.title,
                    "duration_days": r.duration_days,
                    "payment_ratio": float(r.payment_ratio) if r.payment_ratio else None,
                    "deliverables": r.deliverables,
                    "status": r.status,
                    "started_at": r.started_at.isoformat() if r.started_at else None,
                    "completed_at": r.completed_at.isoformat() if r.completed_at else None,
                    "created_at": r.created_at.isoformat() if r.created_at else None,
                }
                for r in q.scalars().all()
            ]


class RatingRepository:
    """评分定级持久化仓库"""

    async def save_provider_profile(self, profile_data: dict) -> None:
        """保存/更新供给方档案"""
        async with get_session_factory()() as session:
            async with session.begin():
                stmt = mysql_insert(AIProviderProfile).values(**profile_data)
                update_fields = {
                    k: stmt.inserted[k]
                    for k in profile_data
                    if k != "id"
                }
                update_fields["updated_at"] = datetime.now()
                stmt = stmt.on_duplicate_key_update(**update_fields)
                await session.execute(stmt)

    async def get_provider_profile(self, provider_id: str) -> Optional[dict]:
        """获取供给方档案"""
        async with get_session_factory()() as session:
            profile = await session.get(AIProviderProfile, provider_id)
            if not profile:
                return None
            return {
                "id": profile.id,
                "user_id": profile.user_id,
                "type": profile.type,
                "display_name": profile.display_name,
                "vibe_power": profile.vibe_power,
                "vibe_level": profile.vibe_level,
                "level_weight": float(profile.level_weight),
                "skills": profile.skills,
                "experience_years": profile.experience_years,
                "ai_tools": profile.ai_tools,
                "resume_summary": profile.resume_summary,
                "review_tags": profile.review_tags,
                "score_tech_depth": profile.score_tech_depth,
                "score_project_exp": profile.score_project_exp,
                "score_ai_proficiency": profile.score_ai_proficiency,
                "score_portfolio": profile.score_portfolio,
                "score_background": profile.score_background,
                "total_projects": profile.total_projects,
                "completed_projects": profile.completed_projects,
                "avg_rating": float(profile.avg_rating),
                "on_time_rate": float(profile.on_time_rate),
                "created_at": profile.created_at.isoformat() if profile.created_at else None,
                "updated_at": profile.updated_at.isoformat() if profile.updated_at else None,
            }

    async def get_provider_by_user_id(self, user_id: str) -> Optional[dict]:
        """通过 user_id 获取供给方档案"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIProviderProfile).where(AIProviderProfile.user_id == user_id)
            )
            profile = q.scalars().first()
            if not profile:
                return None
            return await self.get_provider_profile(profile.id)

    async def update_vibe_power(
        self,
        provider_id: str,
        points_delta: int,
        new_level: str,
        new_weight: float,
    ) -> None:
        """更新供给方的积分和等级"""
        async with get_session_factory()() as session:
            async with session.begin():
                profile = await session.get(AIProviderProfile, provider_id)
                if profile:
                    profile.vibe_power = max(0, profile.vibe_power + points_delta)
                    profile.vibe_level = new_level
                    profile.level_weight = new_weight

    async def add_power_log(
        self,
        provider_id: str,
        action: str,
        points: int,
        reason: str = "",
        project_id: Optional[str] = None,
    ) -> None:
        """添加积分变动记录"""
        async with get_session_factory()() as session:
            async with session.begin():
                session.add(AIVibePowerLog(
                    provider_id=provider_id,
                    action=action,
                    points=points,
                    reason=reason,
                    project_id=project_id,
                ))

    async def get_power_logs(
        self,
        provider_id: str,
        limit: int = 50,
        offset: int = 0,
    ) -> list[dict]:
        """获取积分变动历史"""
        async with get_session_factory()() as session:
            q = await session.execute(
                select(AIVibePowerLog)
                .where(AIVibePowerLog.provider_id == provider_id)
                .order_by(AIVibePowerLog.created_at.desc())
                .offset(offset)
                .limit(limit)
            )
            return [
                {
                    "id": log.id,
                    "provider_id": log.provider_id,
                    "action": log.action,
                    "points": log.points,
                    "reason": log.reason,
                    "project_id": log.project_id,
                    "created_at": log.created_at.isoformat() if log.created_at else None,
                }
                for log in q.scalars().all()
            ]


def _parse_dt(val) -> Optional[datetime]:
    """安全解析 ISO 格式日期字符串"""
    if val is None:
        return None
    if isinstance(val, datetime):
        return val
    try:
        return datetime.fromisoformat(val)
    except (ValueError, TypeError):
        return None
