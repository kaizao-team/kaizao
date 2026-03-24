"""
v2 Agent 单元测试
Mock AsyncAnthropic.messages.create() 返回预构造的 Message 对象
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.agents.base_agent import ToolUseBaseAgent, AgentError
from app.outputs.writer import DocumentWriter
from pathlib import Path
import tempfile


# ---- Mock Message 对象 ----

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


# ---- TestAgent: 最小 ToolUseBaseAgent 实现 ----

class TestableAgent(ToolUseBaseAgent):
    agent_name = "test"
    model_tier = "high"

    def __init__(self, llm_router):
        super().__init__(llm_router)
        self.executed_tools = []

    def _get_tools(self):
        return [{
            "name": "test_tool",
            "description": "A test tool",
            "input_schema": {
                "type": "object",
                "properties": {"value": {"type": "string"}},
                "required": ["value"],
            },
        }]

    async def _execute_tool(self, tool_name, tool_input):
        self.executed_tools.append((tool_name, tool_input))
        return f"Executed {tool_name} with {tool_input}"

    def _get_system_prompt(self, **context):
        return "You are a test agent."


@pytest.fixture
def mock_router():
    router = MagicMock()
    router.create_message = AsyncMock()
    return router


@pytest.fixture
def test_agent(mock_router):
    return TestableAgent(mock_router)


class TestToolUseBaseAgent:
    @pytest.mark.asyncio
    async def test_simple_text_response(self, test_agent, mock_router):
        """LLM 直接返回文本，无 tool 调用"""
        mock_router.create_message.return_value = make_message(
            [make_text_block("Hello, I'm here to help!")],
            stop_reason="end_turn",
        )

        messages = [{"role": "user", "content": "Hello"}]
        updated, tool_result = await test_agent.run(messages=messages)

        assert len(updated) == 2  # user + assistant
        assert updated[-1]["role"] == "assistant"
        assert tool_result == {}
        assert len(test_agent.executed_tools) == 0

    @pytest.mark.asyncio
    async def test_tool_use_then_text(self, test_agent, mock_router):
        """LLM 先调用 tool，再返回文本"""
        # 第一次调用：返回 tool_use
        first_response = make_message(
            [
                make_text_block("Let me use a tool."),
                make_tool_use_block("tool-1", "test_tool", {"value": "hello"}),
            ],
            stop_reason="tool_use",
        )

        # 第二次调用：返回纯文本
        second_response = make_message(
            [make_text_block("Done! The tool returned results.")],
            stop_reason="end_turn",
        )

        mock_router.create_message.side_effect = [first_response, second_response]

        messages = [{"role": "user", "content": "Use a tool"}]
        updated, tool_result = await test_agent.run(messages=messages)

        # 验证 tool 被执行
        assert len(test_agent.executed_tools) == 1
        assert test_agent.executed_tools[0] == ("test_tool", {"value": "hello"})

        # 验证消息链：user -> assistant(tool_use) -> user(tool_result) -> assistant(text)
        assert len(updated) == 4
        assert updated[0]["role"] == "user"
        assert updated[1]["role"] == "assistant"
        assert updated[2]["role"] == "user"
        assert updated[3]["role"] == "assistant"

        # 验证 tool_result
        assert tool_result["tool_name"] == "test_tool"
        assert tool_result["value"] == "hello"

    @pytest.mark.asyncio
    async def test_extract_text_response(self, test_agent):
        messages = [
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": [{"type": "text", "text": "Hi there!"}]},
        ]
        text = test_agent.extract_text_response(messages)
        assert text == "Hi there!"

    @pytest.mark.asyncio
    async def test_extract_text_from_string_content(self, test_agent):
        messages = [
            {"role": "assistant", "content": "Direct string"},
        ]
        text = test_agent.extract_text_response(messages)
        assert text == "Direct string"


class TestDocumentWriter:
    def test_save_and_read(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            writer = DocumentWriter(output_root=Path(tmpdir))

            path = writer.save_document("proj-001", "test.md", "# Hello", version=1)
            assert "proj-001" in path
            assert "v1" in path

            content = writer.read_document("proj-001", "test.md", version=1)
            assert content == "# Hello"

    def test_auto_version(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            writer = DocumentWriter(output_root=Path(tmpdir))

            writer.save_document("proj-002", "test.md", "v1 content", version=1)
            v = writer.new_version("proj-002")
            assert v == 2

            writer.save_document("proj-002", "test.md", "v2 content", version=2)
            content = writer.read_document("proj-002", "test.md", version=2)
            assert content == "v2 content"

    def test_list_documents(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            writer = DocumentWriter(output_root=Path(tmpdir))

            writer.save_document("proj-003", "requirement.md", "req", version=1)
            writer.save_document("proj-003", "design.md", "design", version=1)

            docs = writer.list_documents("proj-003", version=1)
            assert set(docs) == {"requirement.md", "design.md"}

    def test_read_nonexistent(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            writer = DocumentWriter(output_root=Path(tmpdir))
            content = writer.read_document("nonexistent", "test.md")
            assert content is None
