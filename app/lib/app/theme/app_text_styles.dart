import 'package:flutter/material.dart';
import 'app_colors.dart';

/// KAIZAO 字体样式系统 — Notion/Linear 风格
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.21,
    letterSpacing: -0.5,
    color: AppColors.black,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: -0.3,
    color: AppColors.black,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.black,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray700,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.gray500,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: AppColors.gray400,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.gray400,
  );

  static const TextStyle num1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.17,
    color: AppColors.black,
  );

  static const TextStyle num2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.black,
  );

  static const TextStyle num3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.38,
    color: AppColors.black,
  );

  static const TextStyle button1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.38,
    color: Colors.white,
  );

  static const TextStyle button2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: AppColors.accent,
  );

  static const TextStyle onboardingWordmark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -0.8,
    fontStyle: FontStyle.italic,
    color: AppColors.black,
  );

  static const TextStyle onboardingTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -1.0,
    color: AppColors.black,
  );

  static const TextStyle onboardingBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.65,
    color: AppColors.onboardingMutedText,
  );

  static const TextStyle onboardingMeta = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.6,
    color: AppColors.gray400,
  );

  static const TextStyle onboardingSectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.4,
    color: AppColors.gray700,
  );

  static const TextStyle onboardingValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.black,
  );

  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.black,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: AppColors.gray700,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray400,
  );

  static const TextStyle tabLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle tag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: AppColors.gray600,
  );

  static const TextStyle statusTag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );
}
