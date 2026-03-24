"""
v2 Schema 模型单元测试
"""

import pytest
from app.schemas.requirement import EARSTask, PRDDocument, RequirementOutput
from app.schemas.design import APIEndpoint, DataModel, DesignDocument
from app.schemas.task import TaskUnit, TaskDocument
from app.schemas.pm import Milestone, Risk, ProjectPlan
from app.pipeline.project_state import ProjectState, STAGES


class TestEARSTask:
    def test_valid_task(self):
        task = EARSTask(
            task_id="T-001",
            ears_type="event",
            ears_statement="当用户点击登录按钮时，系统应当验证凭据",
            module="认证模块",
            role_tag="backend",
            priority=1,
            acceptance_criteria=["凭据验证通过返回 token", "错误凭据返回 401"],
        )
        assert task.task_id == "T-001"
        assert task.ears_type == "event"
        assert task.priority == 1

    def test_invalid_priority(self):
        with pytest.raises(Exception):
            EARSTask(
                task_id="T-002",
                ears_type="ubiquitous",
                ears_statement="test",
                module="test",
                role_tag="frontend",
                priority=10,  # invalid: must be 1-5
                acceptance_criteria=[],
            )


class TestProjectState:
    def test_create_state(self):
        state = ProjectState(project_id="test-001")
        assert state.current_stage == "requirement"
        assert state.requirement.status == "pending"

    def test_can_start_stage(self):
        state = ProjectState(project_id="test-002")
        ok, _ = state.can_start_stage("requirement")
        assert ok is True

        ok, reason = state.can_start_stage("design")
        assert ok is False
        assert "requirement" in reason

    def test_stage_flow(self):
        state = ProjectState(project_id="test-003")
        state.set_stage_status("requirement", "running")
        assert state.requirement.status == "running"
        assert state.requirement.started_at is not None

        state.set_stage_status("requirement", "confirmed")
        assert state.requirement.completed_at is not None

        ok, _ = state.can_start_stage("design")
        assert ok is True

    def test_advance_stage(self):
        state = ProjectState(project_id="test-004")
        state.set_stage_status("requirement", "confirmed")

        next_stage = state.advance_to_next_stage()
        assert next_stage == "design"
        assert state.current_stage == "design"

    def test_to_summary(self):
        state = ProjectState(project_id="test-005", title="Test Project")
        summary = state.to_summary()
        assert summary["project_id"] == "test-005"
        assert "stages" in summary
        assert len(summary["stages"]) == 4


class TestDesignModels:
    def test_api_endpoint(self):
        endpoint = APIEndpoint(
            method="POST",
            path="/api/users",
            description="创建用户",
            response_body={"id": "string", "name": "string"},
        )
        assert endpoint.method == "POST"

    def test_data_model(self):
        model = DataModel(
            entity_name="User",
            fields=[{"name": "id", "type": "uuid", "required": True}],
            relationships=["User has many Orders"],
        )
        assert model.entity_name == "User"


class TestTaskModels:
    def test_task_unit(self):
        unit = TaskUnit(
            task_id="TASK-001",
            title="实现用户登录",
            description="实现用户名密码登录功能",
            module="认证模块",
            vibe_coding_hours=4,
            traditional_hours=12,
        )
        assert unit.vibe_coding_hours == 4
        assert unit.is_critical is False

    def test_task_document(self):
        doc = TaskDocument(
            modules=[],
            total_tasks=10,
            critical_tasks=["TASK-001"],
            risk_tasks=[],
            total_vibe_hours=40,
            total_traditional_hours=120,
            total_vibe_days=5,
            total_traditional_days=15,
            speedup_ratio=3.0,
        )
        assert doc.speedup_ratio == 3.0


class TestPMModels:
    def test_milestone(self):
        ms = Milestone(
            name="MVP",
            target_day=14,
            deliverables=["核心功能", "基础 UI"],
            quality_gate=["所有 API 测试通过"],
        )
        assert ms.target_day == 14

    def test_risk(self):
        risk = Risk(
            risk_id="R-001",
            description="API 性能不达标",
            probability="medium",
            impact="high",
            mitigation="提前做性能测试",
            contingency="水平扩展",
            owner="后端负责人",
        )
        assert risk.probability == "medium"
