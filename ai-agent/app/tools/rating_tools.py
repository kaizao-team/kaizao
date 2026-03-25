"""
开造 VibeBuild — 评分定级 Agent Tool 定义
Anthropic tool use 格式 — vc-T 序列 10 级体系
"""

# ---- RatingAgent Tools ----

PARSE_RESUME_TOOL = {
    "name": "parse_resume",
    "description": "解析造物者的简历/履历文本，提取结构化信息（技能树、项目经历、AI 工具经验、教育背景、评审标签等）。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {
                "type": "string",
                "description": "Agent 对用户的回复文本",
            },
            "parsed_profile": {
                "type": "object",
                "properties": {
                    "display_name": {
                        "type": "string",
                        "description": "姓名或昵称",
                    },
                    "type": {
                        "type": "string",
                        "enum": ["individual", "team"],
                        "description": "个人或团队",
                    },
                    "experience_years": {
                        "type": "integer",
                        "description": "总工作年限",
                    },
                    "skills": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "name": {"type": "string"},
                                "category": {
                                    "type": "string",
                                    "enum": ["language", "framework", "database", "devops", "ai_tool", "other"],
                                },
                                "proficiency": {
                                    "type": "string",
                                    "enum": ["beginner", "intermediate", "advanced", "expert"],
                                },
                                "years": {"type": "number"},
                            },
                            "required": ["name", "category", "proficiency"],
                        },
                        "description": "技能树列表",
                    },
                    "projects": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "name": {"type": "string"},
                                "role": {
                                    "type": "string",
                                    "enum": ["independent", "core", "participant"],
                                },
                                "complexity": {
                                    "type": "string",
                                    "enum": ["low", "medium", "high", "very_high"],
                                },
                                "description": {"type": "string"},
                                "tech_stack": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                },
                                "outcome": {"type": "string"},
                            },
                            "required": ["name", "role", "complexity"],
                        },
                        "description": "项目经历列表",
                    },
                    "ai_tools": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "tool_name": {"type": "string"},
                                "proficiency": {
                                    "type": "string",
                                    "enum": ["beginner", "intermediate", "advanced", "expert"],
                                },
                                "usage_scenario": {"type": "string"},
                            },
                            "required": ["tool_name", "proficiency"],
                        },
                        "description": "AI 工具使用经验",
                    },
                    "education": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "institution": {"type": "string"},
                                "degree": {"type": "string"},
                                "major": {"type": "string"},
                                "is_cs_related": {"type": "boolean"},
                            },
                            "required": ["institution", "degree"],
                        },
                    },
                    "work_history": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "company": {"type": "string"},
                                "title": {"type": "string"},
                                "is_major_company": {"type": "boolean"},
                            },
                            "required": ["company", "title"],
                        },
                    },
                    "achievements": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "获奖记录、开源贡献等",
                    },
                    "github_stars": {
                        "type": "integer",
                        "description": "GitHub 总 star 数（如有）",
                    },
                    "resume_summary": {
                        "type": "string",
                        "description": "简历核心摘要（200 字内）",
                    },
                    "review_tags": {
                        "type": "object",
                        "description": "评审标签，用于定级凭证存档",
                        "properties": {
                            "education_tier": {
                                "type": "string",
                                "enum": ["QS100", "985", "211", "双一流", "普通本科", "专科", "其他"],
                                "description": "学历层次",
                            },
                            "education_school": {
                                "type": "string",
                                "description": "学校名称",
                            },
                            "education_degree": {
                                "type": "string",
                                "enum": ["博士", "硕士", "学士", "专科", "其他"],
                                "description": "学位",
                            },
                            "education_major": {
                                "type": "string",
                                "description": "专业名称",
                            },
                            "is_cs_related": {
                                "type": "boolean",
                                "description": "是否计算机/软件相关专业",
                            },
                            "major_company": {
                                "type": "boolean",
                                "description": "是否有大厂经历",
                            },
                            "major_company_names": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "大厂名称列表",
                            },
                            "work_years": {
                                "type": "integer",
                                "description": "工作年限",
                            },
                            "max_role_level": {
                                "type": "string",
                                "enum": ["junior", "mid", "senior", "staff", "principal", "director"],
                                "description": "最高职级",
                            },
                            "ai_tools_used": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "使用过的 AI 工具列表",
                            },
                            "ai_proficiency_level": {
                                "type": "string",
                                "enum": ["none", "beginner", "intermediate", "advanced", "expert"],
                                "description": "AI 工具综合熟练度",
                            },
                            "project_max_complexity": {
                                "type": "string",
                                "enum": ["low", "medium", "high", "very_high"],
                                "description": "最高项目复杂度",
                            },
                            "independent_projects": {
                                "type": "integer",
                                "description": "独立项目数量",
                            },
                            "has_open_source": {
                                "type": "boolean",
                                "description": "是否有开源贡献",
                            },
                            "github_stars": {
                                "type": "integer",
                                "description": "GitHub 总 star 数",
                            },
                        },
                    },
                },
                "required": ["display_name", "type", "experience_years", "skills", "projects", "ai_tools", "resume_summary", "review_tags"],
            },
        },
        "required": ["agent_message", "parsed_profile"],
    },
}


EVALUATE_SKILLS_TOOL = {
    "name": "evaluate_skills",
    "description": "对造物者进行五维度能力评分（0-100 每维度），计算 VibePower 总积分（满分 750）。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {
                "type": "string",
                "description": "Agent 对用户的回复文本",
            },
            "scores": {
                "type": "object",
                "properties": {
                    "tech_depth": {
                        "type": "object",
                        "properties": {
                            "score": {"type": "integer", "minimum": 0, "maximum": 100},
                            "reasoning": {"type": "string"},
                        },
                        "required": ["score", "reasoning"],
                    },
                    "project_exp": {
                        "type": "object",
                        "properties": {
                            "score": {"type": "integer", "minimum": 0, "maximum": 100},
                            "reasoning": {"type": "string"},
                        },
                        "required": ["score", "reasoning"],
                    },
                    "ai_proficiency": {
                        "type": "object",
                        "properties": {
                            "score": {"type": "integer", "minimum": 0, "maximum": 100},
                            "reasoning": {"type": "string"},
                        },
                        "required": ["score", "reasoning"],
                    },
                    "portfolio": {
                        "type": "object",
                        "properties": {
                            "score": {"type": "integer", "minimum": 0, "maximum": 100},
                            "reasoning": {"type": "string"},
                        },
                        "required": ["score", "reasoning"],
                    },
                    "background": {
                        "type": "object",
                        "properties": {
                            "score": {"type": "integer", "minimum": 0, "maximum": 100},
                            "reasoning": {"type": "string"},
                        },
                        "required": ["score", "reasoning"],
                    },
                },
                "required": ["tech_depth", "project_exp", "ai_proficiency", "portfolio", "background"],
            },
            "vibe_power": {
                "type": "integer",
                "description": "加权计算后的 VibePower 总积分（满分 750，上限 749）",
                "minimum": 0,
                "maximum": 750,
            },
        },
        "required": ["agent_message", "scores", "vibe_power"],
    },
}


GENERATE_REPORT_TOOL = {
    "name": "generate_report",
    "description": "生成最终的评估报告，包含 vc-T 等级定级、各维度评分详情和个性化提升建议。",
    "input_schema": {
        "type": "object",
        "properties": {
            "agent_message": {
                "type": "string",
                "description": "Agent 对用户的总结回复",
            },
            "report": {
                "type": "object",
                "properties": {
                    "vibe_power": {
                        "type": "integer",
                        "description": "VibePower 总积分（满分 750，上限 749）",
                    },
                    "vibe_level": {
                        "type": "string",
                        "enum": ["vc-T1", "vc-T2", "vc-T3", "vc-T4", "vc-T5"],
                        "description": "等级编码（初始化最高 vc-T5）",
                    },
                    "level_icon": {
                        "type": "string",
                        "description": "等级图标 emoji",
                    },
                    "level_weight": {
                        "type": "number",
                        "description": "推荐权重系数",
                    },
                    "scores": {
                        "type": "object",
                        "properties": {
                            "tech_depth": {"type": "integer"},
                            "project_exp": {"type": "integer"},
                            "ai_proficiency": {"type": "integer"},
                            "portfolio": {"type": "integer"},
                            "background": {"type": "integer"},
                        },
                        "required": ["tech_depth", "project_exp", "ai_proficiency", "portfolio", "background"],
                    },
                    "score_details": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "dimension": {"type": "string"},
                                "score": {"type": "integer"},
                                "weight": {"type": "string"},
                                "weighted_score": {"type": "number"},
                                "reasoning": {"type": "string"},
                            },
                            "required": ["dimension", "score", "weight", "weighted_score", "reasoning"],
                        },
                    },
                    "strengths": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "核心优势（2-4 条）",
                    },
                    "improvements": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "area": {"type": "string"},
                                "suggestion": {"type": "string"},
                                "potential_points": {"type": "integer"},
                            },
                            "required": ["area", "suggestion", "potential_points"],
                        },
                        "description": "提升建议（2-4 条，含预期可提升积分）",
                    },
                    "next_level": {
                        "type": "object",
                        "properties": {
                            "level": {"type": "string"},
                            "points_needed": {"type": "integer"},
                            "tips": {"type": "string"},
                        },
                        "required": ["level", "points_needed", "tips"],
                    },
                },
                "required": ["vibe_power", "vibe_level", "level_icon", "level_weight", "scores", "score_details", "strengths", "improvements", "next_level"],
            },
        },
        "required": ["agent_message", "report"],
    },
}
