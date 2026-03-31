"""
开造 VibeBuild — 各 Agent 专用 Tool 定义
Anthropic tool use 格式
"""

# ---- RequirementAgent Tools ----

ASK_CLARIFICATION_TOOL = {
    "name": "ask_clarification",
    "description": "向用户提出结构化澄清问题，帮助补全需求。支持选择题和文本输入等多种交互方式，包含完整度评分和各维度覆盖度。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {
                "type": "string",
                "description": "Agent 对用户的回复文本",
            },
            "completeness_score": {
                "type": "integer",
                "description": "当前需求完整度评分 0-100，计算公式: sum(dimension_i × weight_i)，所有维度 ≥ 60% 且总分 ≥ 80 才触发 PRD",
                "minimum": 0,
                "maximum": 100,
            },
            "questions": {
                "type": "array",
                "description": "结构化问题列表，每轮 2-4 个问题，不超过 4 个",
                "items": {
                    "type": "object",
                    "properties": {
                        "id": {
                            "type": "string",
                            "description": "问题唯一标识，如 q1, q2",
                        },
                        "question": {
                            "type": "string",
                            "description": "问题文本",
                        },
                        "category": {
                            "type": "string",
                            "enum": [
                                "product_scope",
                                "target_users",
                                "core_features",
                                "tech_preference",
                                "business_goal",
                                "mvp_scope",
                                "constraints",
                            ],
                            "description": "问题所属需求维度",
                        },
                        "input_type": {
                            "type": "string",
                            "enum": ["single_choice", "multi_choice", "text", "number"],
                            "description": "交互类型: single_choice=单选, multi_choice=多选, text=文本输入, number=数字输入",
                        },
                        "options": {
                            "type": "array",
                            "description": "选择题选项列表（input_type 为 single_choice 或 multi_choice 时必填）",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "label": {
                                        "type": "string",
                                        "description": "选项显示文本",
                                    },
                                    "value": {
                                        "type": "string",
                                        "description": "选项提交值",
                                    },
                                    "description": {
                                        "type": "string",
                                        "description": "选项补充说明（可选）",
                                    },
                                },
                                "required": ["label", "value"],
                            },
                        },
                        "allow_custom": {
                            "type": "boolean",
                            "description": "选择题是否允许用户自定义输入（默认 true）",
                        },
                        "placeholder": {
                            "type": "string",
                            "description": "text/number 类型的输入提示语",
                        },
                        "required": {
                            "type": "boolean",
                            "description": "是否必填",
                        },
                    },
                    "required": ["id", "question", "category", "input_type", "required"],
                },
            },
            "dimension_coverage": {
                "type": "object",
                "description": "各需求维度的覆盖度（0-100），用于展示进度",
                "properties": {
                    "product_scope": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "产品定位与边界（权重 20%）",
                    },
                    "target_users": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "用户画像（权重 15%）",
                    },
                    "core_features": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "核心功能列表（权重 20%）",
                    },
                    "tech_preference": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "技术偏好（权重 10%）",
                    },
                    "business_goal": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "商业目标（权重 10%）",
                    },
                    "mvp_scope": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "MVP 范围与优先级（权重 15%）",
                    },
                    "constraints": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "约束条件（权重 10%）",
                    },
                },
            },
        },
        "required": ["agent_message", "completeness_score", "questions", "dimension_coverage"],
    },
}


GENERATE_PRD_TOOL = {
    "name": "generate_prd",
    "description": "根据已收集的需求信息，生成结构化 PRD 文档。包含项目复杂度定级和需求条目（Feature Items）列表。",
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
            "complexity": {
                "type": "string",
                "enum": ["S", "M", "L", "XL"],
                "description": "项目复杂度等级: S(1-3天) / M(3-7天) / L(7-15天) / XL(15-30天)",
            },
            "prd": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "summary": {"type": "string"},
                    "target_users": {"type": "array", "items": {"type": "object"}},
                    "feature_modules": {
                        "type": "array",
                        "description": "功能模块列表，每个模块包含需求条目",
                        "items": {
                            "type": "object",
                            "properties": {
                                "module_name": {"type": "string"},
                                "description": {"type": "string"},
                                "feature_items": {
                                    "type": "array",
                                    "description": "需求条目列表（发起人可感知的进度单元）",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "item_id": {"type": "string", "description": "编号如 F-1.1"},
                                            "title": {"type": "string"},
                                            "description": {"type": "string"},
                                            "priority": {"type": "string", "enum": ["P0", "P1", "P2"]},
                                            "acceptance_summary": {"type": "string", "description": "用户视角的验收标准"},
                                        },
                                        "required": ["item_id", "title", "description", "priority", "acceptance_summary"],
                                    },
                                },
                            },
                        },
                    },
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
        "required": ["agent_message", "completeness_score", "complexity", "prd", "markdown_preview"],
    },
}


DECOMPOSE_TO_EARS_TOOL = {
    "name": "decompose_to_ears",
    "description": "将确认的 PRD 拆解为 EARS 任务单元。每个 EARS 卡片必须归属于一个需求条目（feature_item_id）。",
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
                        "task_id": {"type": "string", "description": "如 T-001"},
                        "feature_item_id": {"type": "string", "description": "归属的需求条目 ID，如 F-1.1"},
                        "ears_type": {
                            "type": "string",
                            "enum": ["ubiquitous", "event", "state", "optional", "unwanted"],
                        },
                        "ears_statement": {"type": "string", "description": "EARS 完整语句"},
                        "module": {"type": "string"},
                        "role_tag": {
                            "type": "string",
                            "enum": ["frontend", "backend", "fullstack", "design", "testing"],
                        },
                        "priority": {"type": "integer", "minimum": 1, "maximum": 5},
                        "estimated_hours": {"type": "number", "description": "预估工时（Vibe Coding 模式）"},
                        "acceptance_criteria": {"type": "array", "items": {"type": "string"}},
                        "dependencies": {"type": "array", "items": {"type": "string"}},
                    },
                    "required": ["task_id", "feature_item_id", "ears_type", "ears_statement", "module", "role_tag", "priority", "acceptance_criteria"],
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
