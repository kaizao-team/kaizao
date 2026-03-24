"""
开造 VibeBuild — 各 Agent 专用 Tool 定义
Anthropic tool use 格式
"""

# ---- RequirementAgent Tools ----

ASK_CLARIFICATION_TOOL = {
    "name": "ask_clarification",
    "description": "向用户提出结构化澄清问题，帮助补全需求。包含完整度评分。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {
                "type": "string",
                "description": "Agent 对用户的回复文本",
            },
            "completeness_score": {
                "type": "integer",
                "description": "当前需求完整度评分 0-100",
                "minimum": 0,
                "maximum": 100,
            },
            "questions": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "question": {"type": "string"},
                        "category": {
                            "type": "string",
                            "enum": ["scope", "user", "tech", "business", "priority"],
                        },
                        "options": {
                            "type": "array",
                            "items": {"type": "string"},
                        },
                    },
                    "required": ["question", "category"],
                },
            },
        },
        "required": ["agent_message", "completeness_score", "questions"],
    },
}


GENERATE_PRD_TOOL = {
    "name": "generate_prd",
    "description": "根据已收集的需求信息，生成结构化 PRD 文档及 Markdown 预览。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {
                "type": "string",
                "description": "Agent 对用户的回复",
            },
            "completeness_score": {
                "type": "integer",
                "minimum": 0,
                "maximum": 100,
            },
            "prd": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "summary": {"type": "string"},
                    "target_users": {"type": "array", "items": {"type": "object"}},
                    "feature_modules": {"type": "array", "items": {"type": "object"}},
                    "tech_requirements": {"type": "object"},
                    "non_functional_requirements": {"type": "object"},
                },
                "required": ["title", "summary", "target_users", "feature_modules", "tech_requirements", "non_functional_requirements"],
            },
            "markdown_preview": {
                "type": "string",
                "description": "完整的 Markdown 格式 PRD 文档预览",
            },
        },
        "required": ["agent_message", "completeness_score", "prd", "markdown_preview"],
    },
}


DECOMPOSE_TO_EARS_TOOL = {
    "name": "decompose_to_ears",
    "description": "将确认的 PRD 拆解为 EARS 最小任务单元列表。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {
                "type": "string",
            },
            "ears_tasks": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "task_id": {"type": "string"},
                        "ears_type": {
                            "type": "string",
                            "enum": ["ubiquitous", "event", "state", "optional", "unwanted"],
                        },
                        "ears_statement": {"type": "string"},
                        "module": {"type": "string"},
                        "role_tag": {
                            "type": "string",
                            "enum": ["frontend", "backend", "fullstack", "design", "testing"],
                        },
                        "priority": {"type": "integer", "minimum": 1, "maximum": 5},
                        "acceptance_criteria": {"type": "array", "items": {"type": "string"}},
                        "dependencies": {"type": "array", "items": {"type": "string"}},
                    },
                    "required": ["task_id", "ears_type", "ears_statement", "module", "role_tag", "priority", "acceptance_criteria"],
                },
            },
            "markdown_preview": {
                "type": "string",
                "description": "包含 PRD + EARS 的完整 requirement.md 内容",
            },
        },
        "required": ["agent_message", "ears_tasks", "markdown_preview"],
    },
}


# ---- DesignAgent Tools ----

PRODUCE_DESIGN_TOOL = {
    "name": "produce_design",
    "description": "基于需求文档，输出完整的架构设计方案。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {"type": "string"},
            "design": {
                "type": "object",
                "properties": {
                    "system_architecture": {"type": "object"},
                    "frontend_modules": {"type": "array", "items": {"type": "object"}},
                    "backend_modules": {"type": "array", "items": {"type": "object"}},
                    "api_design": {"type": "array", "items": {"type": "object"}},
                    "data_models": {"type": "array", "items": {"type": "object"}},
                    "non_functional": {"type": "object"},
                    "tech_decisions": {"type": "array", "items": {"type": "object"}},
                },
                "required": ["system_architecture", "frontend_modules", "backend_modules", "api_design", "data_models", "non_functional", "tech_decisions"],
            },
            "markdown_preview": {"type": "string"},
        },
        "required": ["agent_message", "design", "markdown_preview"],
    },
}


# ---- TaskAgent Tools ----

PRODUCE_TASK_BREAKDOWN_TOOL = {
    "name": "produce_task_breakdown",
    "description": "按模块输出任务分解，含双节奏估时。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {"type": "string"},
            "task_document": {
                "type": "object",
                "properties": {
                    "modules": {"type": "array", "items": {"type": "object"}},
                    "total_tasks": {"type": "integer"},
                    "critical_tasks": {"type": "array", "items": {"type": "string"}},
                    "risk_tasks": {"type": "array", "items": {"type": "object"}},
                    "total_vibe_hours": {"type": "number"},
                    "total_traditional_hours": {"type": "number"},
                    "total_vibe_days": {"type": "number"},
                    "total_traditional_days": {"type": "number"},
                    "speedup_ratio": {"type": "number"},
                },
                "required": ["modules", "total_tasks", "critical_tasks", "risk_tasks", "total_vibe_hours", "total_traditional_hours", "total_vibe_days", "total_traditional_days", "speedup_ratio"],
            },
            "markdown_preview": {"type": "string"},
        },
        "required": ["agent_message", "task_document", "markdown_preview"],
    },
}

MARK_CRITICAL_RISKS_TOOL = {
    "name": "mark_critical_risks",
    "description": "标注关键任务和风险点，更新任务文档中的风险信息。",
    "input_schema": {
        "type": "object",
        "properties": {
            "critical_tasks": {"type": "array", "items": {"type": "string"}},
            "risk_tasks": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "task_id": {"type": "string"},
                        "risk_level": {"type": "string", "enum": ["low", "medium", "high"]},
                        "risk_description": {"type": "string"},
                    },
                    "required": ["task_id", "risk_level", "risk_description"],
                },
            },
        },
        "required": ["critical_tasks", "risk_tasks"],
    },
}


# ---- PMAgent Tools ----

PRODUCE_PROJECT_PLAN_TOOL = {
    "name": "produce_project_plan",
    "description": "基于所有前序文档，输出完整的项目管理方案。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {"type": "string"},
            "project_plan": {
                "type": "object",
                "properties": {
                    "executive_summary": {"type": "string"},
                    "milestones": {"type": "array", "items": {"type": "object"}},
                    "critical_path": {"type": "array", "items": {"type": "string"}},
                    "critical_path_duration_days": {"type": "integer"},
                    "risk_register": {"type": "array", "items": {"type": "object"}},
                    "resource_plan": {"type": "array", "items": {"type": "object"}},
                    "quality_gates": {"type": "array", "items": {"type": "object"}},
                    "acceptance_criteria": {"type": "array", "items": {"type": "string"}},
                    "communication_plan": {"type": "object"},
                    "change_management": {"type": "string"},
                    "tracking_framework": {"type": "object"},
                    "vibe_timeline_days": {"type": "integer"},
                    "traditional_timeline_days": {"type": "integer"},
                    "recommended_approach": {"type": "string"},
                },
                "required": ["executive_summary", "milestones", "critical_path", "critical_path_duration_days", "risk_register", "resource_plan", "quality_gates", "acceptance_criteria", "communication_plan", "change_management", "tracking_framework", "vibe_timeline_days", "traditional_timeline_days", "recommended_approach"],
            },
            "markdown_preview": {"type": "string"},
        },
        "required": ["agent_message", "project_plan", "markdown_preview"],
    },
}
