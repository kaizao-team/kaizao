"""
开造 VibeBuild — 文档类 Tool 定义
Anthropic tool use 格式，供所有 Agent 共用
"""


SAVE_DOCUMENT_TOOL = {
    "name": "save_document",
    "description": "将 Markdown 文档保存到文件系统。在文档内容确认后调用。",
    "input_schema": {
        "type": "object",
        "properties": {
            "filename": {
                "type": "string",
                "description": "文件名，如 requirement.md、design.md、task.md、project-plan.md",
            },
            "content": {
                "type": "string",
                "description": "完整的 Markdown 文档内容",
            },
        },
        "required": ["filename", "content"],
    },
}


READ_DOCUMENT_TOOL = {
    "name": "read_document",
    "description": "从文件系统读取已保存的文档内容。",
    "input_schema": {
        "type": "object",
        "properties": {
            "filename": {
                "type": "string",
                "description": "要读取的文件名",
            },
        },
        "required": ["filename"],
    },
}
