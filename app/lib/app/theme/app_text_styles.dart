import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 开造 VCC 完整字体样式系统
/// 所有值从UI原型规范精确提取
class AppTextStyles {
  AppTextStyles._();

  // H1 大标题 — 页面主标题
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.21,
    letterSpacing: -0.5,
    color: AppColors.gray800,
  );

  // H2 章节标题 — 分区标题
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: -0.3,
    color: AppColors.gray800,
  );

  // H3 小节标题 — 卡片标题、模块名
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.gray800,
  );

  // Body1 正文 — 正文内容、列表项
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray700,
  );

  // Body2 辅助正文 — 辅助说明、描述
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.gray500,
  );

  // Caption 注释 — 时间戳、标签
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: AppColors.gray400,
  );

  // Overline 极小标注
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.gray400,
  );

  // Num1 大数字 — 核心数据
  static const TextStyle num1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.17,
    color: AppColors.gray800,
  );

  // Num2 中数字 — 卡片数据
  static const TextStyle num2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.gray800,
  );

  // Num3 小数字 — 列表内数字
  static const TextStyle num3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.38,
    color: AppColors.gray800,
  );

  // Button1 主按钮文字
  static const TextStyle button1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.38,
    color: Colors.white,
  );

  // Button2 次按钮/链接文字
  static const TextStyle button2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: AppColors.brandPurple,
  );

  // 输入框文字
  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray800,
  );

  // 输入框标签
  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: AppColors.gray700,
  );

  // 输入框占位
  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray400,
  );

  // TabBar 文字
  static const TextStyle tabLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // 标签/徽章文字
  static const TextStyle tag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: AppColors.gray600,
  );

  // 状态标签文字
  static const TextStyle statusTag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );
}
