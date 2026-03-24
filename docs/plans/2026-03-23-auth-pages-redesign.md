# Auth Pages Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 重设计 Splash / Onboarding / Login 三个页面，实现沉浸式深色纯色设计、全屏无黑边、流畅动效。

**Architecture:** 三页共用深色基调 `#0F172A`，零渐变，CustomPainter 绘制插图，AnimationController 驱动入场动效。Login 底部白色面板从下滑入，形成深色→浅色的视觉叙事。

**Tech Stack:** Flutter, AnimationController, CustomPainter, SystemChrome, MediaQuery

---

## 前置说明

### 黑边修复原理
当前用 `SafeArea` 包裹内容，背景色不会延伸到状态栏/Home Indicator 区域，导致黑边。

**修复方式（每个页面）：**
1. `Scaffold(backgroundColor: const Color(0xFF0F172A))` — 背景色设为深色
2. 移除顶层 `SafeArea`
3. 在需要避开刘海/Home Indicator 的内容上用 `MediaQuery.of(context).padding` 手动加 padding
4. 在 `initState` 加：
```dart
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: Color(0xFF0F172A),
  systemNavigationBarIconBrightness: Brightness.light,
));
```

### 颜色规则（零渐变）
| 用途 | 色值 |
|------|------|
| 深色背景 | `#0F172A` |
| 深色次级背景 | `#1E293B` |
| 插图线条/inactive点 | `#334155` |
| 主文字（深色背景上） | `#FFFFFF` |
| 次级文字（深色背景上） | `#94A3B8` |
| 白色面板 | `#FFFFFF` |
| 主文字（白色面板上） | `#1A1A1A` |
| 次级文字（白色面板上） | `#6B7280` |
| 主按钮（白色面板内） | `#1A1A1A` 底 + `#FFFFFF` 文字 |
| 主按钮（深色背景内） | `#FFFFFF` 底 + `#0F172A` 文字 |
| 输入框背景 | `#F0F1F1` |
| squircle 容器（社交登录）| `#F0F1F1` 底 + `#1A1A1A` 图标 |

---

## Task 1: Splash Page 重写

**Files:**
- Modify: `app/lib/features/auth/pages/splash_page.dart`

**目标效果：**
- 全屏 `#0F172A` 纯色背景（无渐变）
- Logo + VCC + 开造 文字组合，弹簧入场（scale 0.7→1.0 + opacity 0→1）
- Slogan「点亮每一个想法」在 Logo 动画完成后淡入
- 无黑边

**Step 1: 完整替换 splash_page.dart**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/storage/storage_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _sloganController;
  late Animation<double> _scaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _sloganOpacityAnim;

  static const String? _debugForceRoute = kDebugMode ? RoutePaths.onboarding : null;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sloganController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _sloganOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sloganController, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _sloganController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _navigate();
  }

  Future<void> _navigate() async {
    if (kDebugMode && _debugForceRoute != null) {
      context.go(_debugForceRoute!);
      return;
    }
    final storage = StorageService();
    final isFirst = await storage.isFirstLaunch();
    final token = await storage.getAccessToken();
    if (!mounted) return;
    if (isFirst) {
      context.go(RoutePaths.onboarding);
    } else if (token != null && token.isNotEmpty) {
      context.go(RoutePaths.home);
    } else {
      context.go(RoutePaths.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoController, _sloganController]),
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _logoOpacityAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: _buildLogoMark(),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _logoOpacityAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Column(
                      children: [
                        const Text(
                          'VCC',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '开造',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: _sloganOpacityAnim.value,
                  child: const Text(
                    '点亮每一个想法',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoMark() {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _VccLogoPainter(),
      ),
    );
  }
}

class _VccLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // 三角形1（左，白色）
    paint.color = Colors.white;
    final path1 = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w * 0.38, h)
      ..close();
    canvas.drawPath(path1, paint);

    // 三角形2（中，浅灰）
    paint.color = const Color(0xFF94A3B8);
    final path2 = Path()
      ..moveTo(w * 0.35, h)
      ..lineTo(w * 0.65, h)
      ..lineTo(w * 0.5, h * 0.3)
      ..close();
    canvas.drawPath(path2, paint);

    // 三角形3（右，白色淡）
    paint.color = const Color(0xFF64748B);
    final path3 = Path()
      ..moveTo(w * 0.62, h)
      ..lineTo(w, h)
      ..lineTo(w * 0.5, 0)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

**Step 2: 验证**
```bash
cd app && flutter analyze lib/features/auth/pages/splash_page.dart
```
Expected: 0 errors

**Step 3: Commit**
```bash
git add app/lib/features/auth/pages/splash_page.dart
git commit -m "feat: redesign splash page — pure dark, no gradient, spring animation"
```

---

## Task 2: Onboarding Page 重写

**Files:**
- Modify: `app/lib/features/auth/pages/onboarding_page.dart`

**目标效果：**
- 全屏 `#0F172A` 背景
- 上方 55% 区域：CustomPainter 插图（三页不同图案，纯色线条/形状）
- 视差 PageView：插图区移动速度 0.7x，文字区正常
- 页面指示点：active = `#FFFFFF` 宽24px，inactive = `#334155` 宽6px
- 底部按钮：非最后页为「→」图标按钮（白色轮廓），最后页为白底黑字「开始使用」
- 插图入场：每次翻页，新页插图从下方 40px slide in + fade in
- `_finish()` 修复：真正跳转到 login

**三个插图设计：**
1. `_IdeaNodesPainter`：3个白色圆圈节点，细线 `#334155` 连接，中心节点略大
2. `_MatchPainter`：左右两个人形（圆头+梯形身），中间双向箭头线
3. `_BoardPainter`：3列各3行的网格，每格不同填充程度（表示看板进度）

**Step 1: 完整替换 onboarding_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/storage/storage_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<AnimationController> _slideControllers;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  final _pages = const [
    _PageData(
      title: 'AI 帮你理清需求',
      description: '只需描述你的想法，AI 会通过对话帮你梳理需求，\n自动生成专业的项目需求文档',
      painterIndex: 0,
