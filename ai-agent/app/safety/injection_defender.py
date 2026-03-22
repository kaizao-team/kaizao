"""
开造 VibeBuild — Prompt 注入防御
多层检测策略：正则关键词、长度异常、特殊字符密度
"""

import re
from typing import Dict

import structlog

from app.config import settings

logger = structlog.get_logger()


class PromptInjectionDefender:
    """
    多层 Prompt 注入防御器

    检测层级：
    Layer 1: 正则关键词黑名单
    Layer 2: 长度异常检测
    Layer 3: 特殊字符密度检测
    """

    # 注入攻击正则模式列表
    INJECTION_PATTERNS = [
        # 中文注入模式
        r"忽略.{0,10}(之前|上面|以上).{0,10}(指令|提示|规则|指示)",
        r"你(现在|从现在).{0,5}(是|扮演|变成|充当)",
        r"(系统)\s*(提示|指令)",
        r"(输出|显示|打印|泄露|告诉我).{0,10}(系统|system|prompt|提示词|指令)",
        r"(假装|pretend).{0,10}(你是|you are)",
        r"(开发者|developer|admin|管理员).{0,5}(模式|mode)",
        r"不要遵守.{0,10}(安全|规则|限制)",
        r"越狱",
        # 英文注入模式
        r"ignore.{0,10}(previous|above|prior).{0,10}(instructions?|prompt|rules?)",
        r"(reveal|show|display).{0,10}(system|prompt|instructions?)",
        r"DAN|jailbreak",
        r"act\s+as.{0,10}(you\s+are|a\s+different)",
        # 特殊 token 注入
        r"<\|.*?\|>",
        r"\[INST\]|\[/INST\]",
        r"<<SYS>>|<</SYS>>",
    ]

    # 编译正则以提升性能
    COMPILED_PATTERNS = [re.compile(p, re.IGNORECASE) for p in INJECTION_PATTERNS]

    # 被拦截时的标准安全回复
    SAFE_RESPONSE = (
        "我是开造平台的助手，专注于帮您完成软件开发需求的发布、匹配和管理。"
        "请问您想做什么产品，或者有什么平台使用上的问题吗？"
    )

    def check(self, user_input: str) -> Dict:
        """
        检查用户输入是否包含 Prompt 注入攻击

        Args:
            user_input: 用户输入文本

        Returns:
            {
                "is_safe": True/False,
                "risk_level": "none" / "low" / "medium" / "high",
                "detection_method": "keyword" / "length" / "special_chars" / "none",
                "matched_pattern": "匹配到的模式描述"
            }
        """
        if not user_input:
            return {
                "is_safe": True,
                "risk_level": "none",
                "detection_method": "none",
                "matched_pattern": "",
            }

        # Layer 1: 正则关键词检测
        for i, pattern in enumerate(self.COMPILED_PATTERNS):
            match = pattern.search(user_input)
            if match:
                logger.warning(
                    "prompt_injection_detected",
                    method="keyword",
                    pattern_index=i,
                    matched_text=match.group()[:50],
                )
                return {
                    "is_safe": False,
                    "risk_level": "high",
                    "detection_method": "keyword",
                    "matched_pattern": self.INJECTION_PATTERNS[i],
                }

        # Layer 2: 长度异常检测
        if len(user_input) > settings.injection_length_threshold:
            logger.warning(
                "prompt_injection_detected",
                method="length",
                input_length=len(user_input),
            )
            return {
                "is_safe": False,
                "risk_level": "medium",
                "detection_method": "length",
                "matched_pattern": (
                    f"输入长度 {len(user_input)} 超过阈值 "
                    f"{settings.injection_length_threshold}"
                ),
            }

        # Layer 3: 特殊字符密度检测
        special_chars = sum(1 for c in user_input if c in "{}[]<>|\\`~")
        char_ratio = special_chars / len(user_input) if len(user_input) > 0 else 0
        if char_ratio > settings.special_char_ratio_threshold:
            logger.warning(
                "prompt_injection_detected",
                method="special_chars",
                ratio=round(char_ratio, 4),
            )
            return {
                "is_safe": False,
                "risk_level": "medium",
                "detection_method": "special_chars",
                "matched_pattern": (
                    f"特殊字符比率 {char_ratio:.2f} 超过阈值 "
                    f"{settings.special_char_ratio_threshold}"
                ),
            }

        return {
            "is_safe": True,
            "risk_level": "none",
            "detection_method": "none",
            "matched_pattern": "",
        }

    def get_safe_response(self) -> str:
        """获取被拦截时的标准安全回复"""
        return self.SAFE_RESPONSE

    def sanitize_output(self, text: str) -> str:
        """
        过滤 AI 输出中的敏感信息

        Args:
            text: AI 生成的文本

        Returns:
            脱敏后的文本
        """
        # 脱敏手机号
        text = re.sub(r"1[3-9]\d{9}", "1XX****XXXX", text)
        # 脱敏身份证号
        text = re.sub(r"\d{17}[\dXx]", "****", text)
        # 脱敏邮箱
        text = re.sub(r"[\w.]+@[\w.]+\.\w+", "***@***.com", text)
        return text
