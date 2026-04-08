import 'package:flutter/material.dart';

/// KAIZAO 颜色系统 — Notion/Linear 黑白风格 + 紫色强调色
class AppColors {
  AppColors._();

  // ============================================================
  // Semantic surfaces — aligned to DESIGN_SPEC.md
  // ============================================================
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceCanvas = Color(0xFFFEFCFD);
  static const Color surfaceAlt = Color(0xFFF3F3F3);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color surfaceStrong = Color(0xFFE8E8E8);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color textSecondary = Color(0xFF555555);
  static const Color outlineSoft = Color(0xFFC6C6C6);
  static const Color outlineVariant = Color(0x33C6C6C6);
  static const Color tonalHeroEnd = Color(0xFF3C3B3B);

  // ============================================================
  // 品牌强调色（紫色点缀）
  // ============================================================
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFFF3EEFF);
  static const Color accentDark = Color(0xFF5B21B6);
  static const Color accentMuted = Color(0xFFDDD6FE);

  // ============================================================
  // Onboarding Editorial Tokens
  // ============================================================
  static const Color onboardingBackground = Color(0xFFF7F7F5);
  static const Color onboardingSurface = Color(0xFFFFFFFF);
  static const Color onboardingSurfaceMuted = Color(0xFFF3F3F1);
  static const Color onboardingHairline = Color(0xFFE5E7EB);
  static const Color onboardingMutedText = Color(0xFF6B7280);
  static const Color onboardingPrimary = Color(0xFF111111);
  static const Color onboardingPrimaryPressed = Color(0xFF2B2B2B);

  // ============================================================
  // 主色 — 黑白体系
  // ============================================================
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = black;

  // ============================================================
  // 中性色阶 — 浅色模式
  // ============================================================
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ============================================================
  // 语义色 — 浅色模式
  // ============================================================
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // ============================================================
  // 语义色 — 深色模式
  // ============================================================
  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorDark = Color(0xFFF87171);
  static const Color infoDark = Color(0xFF60A5FA);

  // ============================================================
  // 深色模式专用色
  // ============================================================
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkBg2 = Color(0xFF141414);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkCardHover = Color(0xFF222222);
  static const Color darkDivider = Color(0xFF2A2A2A);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // ============================================================
  // 项目状态色
  // ============================================================
  static const Color statusCompleted = Color(0xFF10B981);
  static const Color statusInProgress = Color(0xFF7C3AED);
  static const Color statusPending = Color(0xFFD1D5DB);
  static const Color statusAtRisk = Color(0xFFEF4444);
  static const Color statusOverdue = Color(0xFFEF4444);

  // ============================================================
  // EARS 卡片类型色
  // ============================================================
  static const Color earsUbiquitousStart = Color(0xFF7C5CFC);
  static const Color earsUbiquitousEnd = Color(0xFF6C5CE7);
  static const Color earsEventStart = Color(0xFF0A7AFF);
  static const Color earsEventEnd = Color(0xFF4A6CF7);
  static const Color earsStateStart = Color(0xFFFF9500);
  static const Color earsStateEnd = Color(0xFFF7B731);
  static const Color earsOptionalStart = Color(0xFF34C759);
  static const Color earsOptionalEnd = Color(0xFF7BED9F);
  static const Color earsUnwantedStart = Color(0xFFFF3B30);
  static const Color earsUnwantedEnd = Color(0xFFFC5C65);

  // 向后兼容别名
  static const Color brandPurple = accent;
  static const Color brandIndigo = Color(0xFF6366F1);
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandDarkPurple = accentDark;
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGold = Color(0xFFF59E0B);
}

/// 渐变集合 — 仅保留必要场景
class AppGradients {
  AppGradients._();

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
  );

  static const LinearGradient accentSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3EEFF), Color(0xFFEDE9FE)],
  );

  // EARS 类型渐变
  static const LinearGradient earsUbiquitous = LinearGradient(
    colors: [Color(0xFF7C5CFC), Color(0xFF6C5CE7)],
  );
  static const LinearGradient earsEvent = LinearGradient(
    colors: [Color(0xFF0A7AFF), Color(0xFF4A6CF7)],
  );
  static const LinearGradient earsState = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFF7B731)],
  );
  static const LinearGradient earsOptional = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF7BED9F)],
  );
  static const LinearGradient earsUnwanted = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFFC5C65)],
  );

  // 向后兼容
  static const LinearGradient primary = accent;
  static const LinearGradient primaryButton = accent;
  static const LinearGradient primaryPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
  );
  static const LinearGradient deepSpace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
  );
  static const LinearGradient primaryDark = accent;
  static const LinearGradient aurora = accent;
}

/// 阴影系统 — 极轻阴影，偏 Notion 风格
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> shadow1 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadow2 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> shadow3 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> shadow4 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      offset: Offset(0, 8),
      blurRadius: 32,
    ),
  ];

  static const List<BoxShadow> brandShadow = shadow2;
  static const List<BoxShadow> brandShadowPressed = shadow1;
  static const List<BoxShadow> onboardingLift = [
    BoxShadow(
      color: Color.fromRGBO(49, 51, 44, 0.07),
      offset: Offset(0, 12),
      blurRadius: 30,
    ),
  ];
}

/// 间距系统
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// 圆角系统
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}

/// 动画时长
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration progress = Duration(milliseconds: 600);
}

/// 动画曲线
class AppCurves {
  AppCurves._();

  static const Cubic standard = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
}
