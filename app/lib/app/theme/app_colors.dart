import 'package:flutter/material.dart';

/// 开造 VCC 完整颜色系统
/// 所有颜色值从UI原型规范文档精确提取
class AppColors {
  AppColors._();

  // ============================================================
  // 品牌主色（渐变色系）
  // ============================================================
  static const Color brandPurple = Color(0xFF7C3AED);     // 星辉紫，渐变起点
  static const Color brandIndigo = Color(0xFF6366F1);     // 深邃靛，渐变中段
  static const Color brandBlue = Color(0xFF3B82F6);       // 天际蓝，渐变终点
  static const Color brandDarkPurple = Color(0xFF5B21B6); // 暗夜紫，深色变体/按下态

  // ============================================================
  // 辅助色
  // ============================================================
  static const Color accentCyan = Color(0xFF06B6D4);      // 极光青
  static const Color accentGold = Color(0xFFF59E0B);      // 星芒金

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
  // 语义色 — 深色模式（提亮版）
  // ============================================================
  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorDark = Color(0xFFF87171);
  static const Color infoDark = Color(0xFF60A5FA);

  // ============================================================
  // 中性色阶
  // ============================================================
  static const Color gray50 = Color(0xFFF8FAFC);   // 页面底色
  static const Color gray100 = Color(0xFFF1F5F9);  // 输入框背景/骨架屏
  static const Color gray200 = Color(0xFFE2E8F0);  // 分割线/边框
  static const Color gray300 = Color(0xFFCBD5E1);  // 禁用态边框
  static const Color gray400 = Color(0xFF94A3B8);  // 占位文字/次要图标
  static const Color gray500 = Color(0xFF64748B);  // 次要文字/辅助说明
  static const Color gray600 = Color(0xFF475569);  // 副标题
  static const Color gray700 = Color(0xFF334155);  // 正文文字（浅色模式）
  static const Color gray800 = Color(0xFF1E293B);  // 标题文字（浅色模式）
  static const Color gray900 = Color(0xFF0F172A);  // 极深灰

  // ============================================================
  // 深色模式专用色
  // ============================================================
  static const Color darkBg = Color(0xFF0F0B1E);          // 页面背景
  static const Color darkBg2 = Color(0xFF1A1035);         // 二级背景
  static const Color darkCard = Color(0xFF1E1640);        // 卡片背景
  static const Color darkCardHover = Color(0xFF261D52);   // 卡片悬停
  static const Color darkDivider = Color(0xFF2D2650);     // 分割线/边框

  // ============================================================
  // 项目状态色
  // ============================================================
  static const Color statusCompleted = Color(0xFF10B981);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusPending = Color(0xFFCBD5E1);
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

  // ============================================================
  // 第三方登录色
  // ============================================================
  static const Color wechatGreen = Color(0xFF07C160);
  static const Color appleBlack = Color(0xFF000000);
}

/// 品牌渐变集合
class AppGradients {
  AppGradients._();

  // 主渐变：星河紫蓝
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF3B82F6)],
    stops: [0.0, 0.5, 1.0],
  );

  // 按钮用简化渐变（两色）
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
  );

  // 按钮按下态渐变
  static const LinearGradient primaryPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF2563EB)],
  );

  // 极光流转（运营/辅助场景）
  static const LinearGradient aurora = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
  );

  // 深空沉浸（启动页/深色场景）
  static const LinearGradient deepSpace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5B21B6), Color(0xFF3730A3), Color(0xFF1E3A5F)],
    stops: [0.0, 0.5, 1.0],
  );

  // 深色模式主渐变（提亮12%）
  static const LinearGradient primaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF818CF8), Color(0xFF60A5FA)],
    stops: [0.0, 0.5, 1.0],
  );

  // EARS类型渐变
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
}

/// 阴影系统
class AppShadows {
  AppShadows._();

  // Level 1 - 微阴影：输入框、小标签
  static final List<BoxShadow> shadow1 = [
    const BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    const BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  // Level 2 - 轻阴影：通用卡片、列表卡片
  static final List<BoxShadow> shadow2 = [
    const BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    const BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  // Level 3 - 中阴影：悬浮按钮、弹窗、展开态卡片
  static final List<BoxShadow> shadow3 = [
    const BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
    const BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  // Level 4 - 重阴影：全屏Modal
  static final List<BoxShadow> shadow4 = [
    const BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 16),
      blurRadius: 48,
    ),
    const BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];

  // 品牌色阴影：主按钮
  static final List<BoxShadow> brandShadow = [
    BoxShadow(
      color: AppColors.brandPurple.withOpacity(0.35),
      offset: const Offset(0, 4),
      blurRadius: 15,
    ),
  ];

  // 品牌色阴影-按下态
  static final List<BoxShadow> brandShadowPressed = [
    BoxShadow(
      color: AppColors.brandPurple.withOpacity(0.30),
      offset: const Offset(0, 2),
      blurRadius: 8,
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

  static const double xs = 4;     // 标签/Chip/徽章
  static const double sm = 8;     // 输入框、小按钮、Toast
  static const double md = 12;    // 通用卡片、主按钮、EARS卡片
  static const double lg = 16;    // 大卡片、毛玻璃卡片
  static const double xl = 20;    // 底部弹窗顶部
  static const double xxl = 24;   // 全屏Modal顶部
  static const double full = 999; // 头像、胶囊
}

/// 动画时长
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 260);
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
