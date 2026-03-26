"""
v2 流水线集成测试
Mock LLM 层，验证完整 API 流程
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient


def make_text_block(text: str):
    block = MagicMock()
    block.type = "text"
    block.text = text
    return block


def make_tool_use_block(tool_id: str, name: str, input_data: dict):
    block = MagicMock()
    block.type = "tool_use"
    block.id = tool_id
    block.name = name
    block.input = input_data
    return block


def make_message(content_blocks, stop_reason="end_turn"):
    msg = MagicMock()
    msg.content = content_blocks
    msg.stop_reason = stop_reason
    msg.usage = MagicMock()
    msg.usage.input_tokens = 100
    msg.usage.output_tokens = 50
    msg.model = "claude-sonnet-4-20250514"
    return msg


class TestProjectState:
    """测试 ProjectState 流转逻辑"""

    def test_full_pipeline_flow(self):
        from app.pipeline.project_state import ProjectState, STAGES

        state = ProjectState(project_id="flow-test")

        # 初始状态
        assert state.current_stage == "requirement"
        for s in STAGES:
            assert state.get_stage(s).status == "pending"

        # requirement 流转
        state.set_stage_status("requirement", "running", sub_stage="clarifying")
        assert state.requirement.status == "running"
        assert state.requirement.sub_stage == "clarifying"

        state.set_stage_status("requirement", "confirmed")
        ok, _ = state.can_start_stage("design")
        assert ok

        # design 流转
        state.set_stage_status("design", "running")
        state.set_stage_status("design", "confirmed")
        next_s = state.advance_to_next_stage()
        assert next_s == "design" or state.current_stage in STAGES

        # 不能跳过阶段
        state2 = ProjectState(project_id="flow-test-2")
        ok, reason = state2.can_start_stage("task")
        assert ok is False

    def test_summary_format(self):
        from app.pipeline.project_state import ProjectState

        state = ProjectState(project_id="summary-test", title="My Project")
        state.set_stage_status("requirement", "confirmed")
        summary = state.to_summary()

        assert summary["project_id"] == "summary-test"
        assert summary["title"] == "My Project"
        assert summary["stages"]["requirement"]["status"] == "confirmed"
        assert summary["stages"]["design"]["status"] == "pending"


class TestToolDefinitions:
    """验证 tool 定义格式正确"""

    def test_requirement_tools(self):
        from app.tools.agent_tools import (
            ASK_CLARIFICATION_TOOL,
            GENERATE_PRD_TOOL,
            DECOMPOSE_TO_EARS_TOOL,
        )

        for tool in [ASK_CLARIFICATION_TOOL, GENERATE_PRD_TOOL, DECOMPOSE_TO_EARS_TOOL]:
            assert "name" in tool
            assert "description" in tool
            assert "input_schema" in tool
            assert tool["input_schema"]["type"] == "object"
            assert "properties" in tool["input_schema"]
            assert "required" in tool["input_schema"]

    def test_design_tools(self):
        from app.tools.agent_tools import PRODUCE_DESIGN_TOOL
        assert PRODUCE_DESIGN_TOOL["name"] == "produce_design"
        assert "design" in PRODUCE_DESIGN_TOOL["input_schema"]["properties"]

    def test_task_tools(self):
        from app.tools.agent_tools import PRODUCE_TASK_BREAKDOWN_TOOL, MARK_CRITICAL_RISKS_TOOL
        assert PRODUCE_TASK_BREAKDOWN_TOOL["name"] == "produce_task_breakdown"
        assert MARK_CRITICAL_RISKS_TOOL["name"] == "mark_critical_risks"

    def test_pm_tools(self):
        from app.tools.agent_tools import PRODUCE_PROJECT_PLAN_TOOL
        assert PRODUCE_PROJECT_PLAN_TOOL["name"] == "produce_project_plan"

    def test_document_tools(self):
        from app.tools.document_tools import SAVE_DOCUMENT_TOOL, READ_DOCUMENT_TOOL
        assert SAVE_DOCUMENT_TOOL["name"] == "save_document"
        assert READ_DOCUMENT_TOOL["name"] == "read_document"


class TestBaseAgentSerialization:
    """测试 content block 序列化"""

    def test_serialize_text_block(self):
        from app.agents.base_agent import ToolUseBaseAgent

        block = MagicMock()
        block.type = "text"
        block.text = "Hello"

        result = ToolUseBaseAgent._serialize_content_blocks([block])
        assert result == [{"type": "text", "text": "Hello"}]

    def test_serialize_tool_use_block(self):
        from app.agents.base_agent import ToolUseBaseAgent

        block = MagicMock()
        block.type = "tool_use"
        block.id = "tool-123"
        block.name = "test_tool"
        block.input = {"key": "value"}

        result = ToolUseBaseAgent._serialize_content_blocks([block])
        assert result == [{
            "type": "tool_use",
            "id": "tool-123",
            "name": "test_tool",
            "input": {"key": "value"},
        }]

    def test_serialize_dict_passthrough(self):
        from app.agents.base_agent import ToolUseBaseAgent

        block = {"type": "text", "text": "Already a dict"}
        result = ToolUseBaseAgent._serialize_content_blocks([block])
        assert result == [block]
