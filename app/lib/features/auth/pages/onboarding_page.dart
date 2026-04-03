import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _pageOffset = 0.0;
  int _currentPage = 0;

  late AnimationController _btnController;
  late Animation<double> _btnScale;

  static const _pages = [
    _PageData(
      title: 'AI 帮你理清需求',
      description: '只需描述你的想法，AI 会通过对话\n帮你梳理需求，自动生成专业的\n项目需求文档',
    ),
    _PageData(
      title: '智能匹配团队',
      description: '基于技能、评价、作品多维度分析，\n为你精准推荐最合适的\n开发者或团队',
    ),
    _PageData(
      title: '透明管理全流程',
      description: '可视化看板追踪每个任务进度，\nAI 智能预警风险，\n担保交易安心付款',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF6F6F6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _btnController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _btnController,
        curve: Curves.easeOut,
      ),
    );

    _pageController.addListener(() {
      final page = _pageController.page ?? 0.0;
      setState(() {
        _pageOffset = page;
        _currentPage = page.round();
      });
      // Right-swipe on page 0 → back to splash
      if (page < -0.25 && mounted) {
        context.go(RoutePaths.splash);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (mounted) context.go(RoutePaths.login);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          // Full-screen illustration — continuous morphing, light bg
          Positioned.fill(
            child: CustomPaint(
              painter: _ContinuousMorphPainter(pageOffset: _pageOffset),
            ),
          ),

          // Bottom frosted area — soft edge, blur fades in gradually
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 340,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white],
                stops: [0.0, 0.42],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFF6F6F6).withValues(alpha: 0.0),
                          const Color(0xFFF6F6F6).withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),

          // Invisible PageView captures swipe
          // BouncingScrollPhysics lets page 0 drag negative → triggers back
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Text content — directly over illustration
          Positioned(
            left: 28,
            right: 28,
            bottom: padding.bottom + 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page dots
                Row(
                  children: List.generate(_pages.length, (i) {
                    final active = (i - _pageOffset).abs() < 0.5;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 6),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFD4D4D4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Title cross-fade
                SizedBox(
                  height: 56,
                  child: Stack(
                    children: List.generate(_pages.length, (i) {
                      final rel = (_pageOffset - i).abs();
                      final opacity = (1.0 - rel * 1.5).clamp(0.0, 1.0);
                      final dy = (rel * 10).clamp(0.0, 10.0);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, dy),
                          child: Text(
                            _pages[i].title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),

                // Description cross-fade
                SizedBox(
                  height: 72,
                  child: Stack(
                    children: List.generate(_pages.length, (i) {
                      final rel = (_pageOffset - i).abs();
                      final opacity = (1.0 - rel * 1.5).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: opacity,
                        child: Text(
                          _pages[i].description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.65,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons row: next (3/4) + skip (1/4)
                ScaleTransition(
                  scale: _btnScale,
                  child: Row(
                    children: [
                      // Next / 开始使用 button
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTapDown: (_) => _btnController.forward(),
                          onTapUp: (_) {
                            _btnController.reverse();
                            _next();
                          },
                          onTapCancel: () => _btnController.reverse(),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            alignment: Alignment.center,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                isLast ? '开始使用' : '下一步',
                                key: ValueKey(isLast),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF6F6F6),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Skip button
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: _skip,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A)
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '跳过',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final String title;
  final String description;
  const _PageData({required this.title, required this.description});
}

// ---------------------------------------------------------------------------
// Continuous morphing painter — nodes persist across all 3 pages
// pageOffset: 0.0 (page0) → 1.0 (page1) → 2.0 (page2)
// ---------------------------------------------------------------------------
class _ContinuousMorphPainter extends CustomPainter {
  final double pageOffset;
  const _ContinuousMorphPainter({required this.pageOffset});

  // Smooth ease-in-out for interpolation
  static double _ease(double t) {
    final c = t.clamp(0.0, 1.0);
    return c * c * (3.0 - 2.0 * c);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Light background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFF6F6F6),
    );

    // Segment and ease
    final seg = pageOffset.clamp(0.0, 2.0);
    final seg0 = seg.clamp(0.0, 1.0); // 0→1
    final seg1 = (seg - 1.0).clamp(0.0, 1.0); // 1→2
    final t0 = _ease(seg0);
    final t1 = _ease(seg1);

    // ---------------------------------------------------------------
    // 6 nodes, each with 3 keyframe positions (page0, page1, page2)
    // [x0,y0, x1,y1, x2,y2, r0,r1,r2, color]
    // ---------------------------------------------------------------
    final nodes = <_Node>[
      // Node 0: large hero node — center-left → top-left avatar → left kanban header
      _Node(
        kx: [w * 0.25, w * 0.18, w * 0.12],
        ky: [h * 0.28, h * 0.24, h * 0.20],
        kr: [56.0, 22.0, 8.0],
        color: const Color(0xFF1A1A1A),
      ),
      // Node 1: medium purple — top-right → mid avatar → mid kanban header
      _Node(
        kx: [w * 0.72, w * 0.18, w * 0.44],
        ky: [h * 0.22, h * 0.42, h * 0.20],
        kr: [36.0, 18.0, 8.0],
        color: const Color(0xFF7C3AED),
      ),
      // Node 2: small gray — bottom-center → bottom avatar → right kanban header
      _Node(
        kx: [w * 0.55, w * 0.18, w * 0.76],
        ky: [h * 0.52, h * 0.60, h * 0.20],
        kr: [24.0, 14.0, 8.0],
        color: const Color(0xFF9CA3AF),
      ),
      // Node 3: tiny dark — scattered → skill bar → kanban card accent
      _Node(
        kx: [w * 0.15, w * 0.54, w * 0.12],
        ky: [h * 0.62, h * 0.28, h * 0.30],
        kr: [14.0, 6.0, 4.0],
        color: const Color(0xFF1A1A1A),
      ),
      // Node 4: tiny purple — scattered → skill bar fill → kanban card accent
      _Node(
        kx: [w * 0.82, w * 0.54, w * 0.44],
        ky: [h * 0.45, h * 0.46, h * 0.30],
        kr: [18.0, 6.0, 4.0],
        color: const Color(0xFF7C3AED),
      ),
      // Node 5: small gray ring → label → kanban card
      _Node(
        kx: [w * 0.42, w * 0.54, w * 0.76],
        ky: [h * 0.70, h * 0.64, h * 0.30],
        kr: [10.0, 6.0, 4.0],
        color: const Color(0xFFD4D4D4),
      ),
    ];

    final paint = Paint()..style = PaintingStyle.fill;

    // --- Connecting lines (page0 dominant, fade by t0) ---
    final lineAlpha = (1.0 - t0) * 0.13;
    if (lineAlpha > 0.01) {
      final linePaint = Paint()
        ..color = const Color(0xFF1A1A1A).withValues(alpha: lineAlpha)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      final connections = [
        [0, 1],
        [0, 2],
        [1, 2],
        [1, 3],
        [2, 4],
        [3, 5],
      ];
      for (final c in connections) {
        final a = nodes[c[0]];
        final b = nodes[c[1]];
        canvas.drawLine(
          Offset(a.nx(t0, t1), a.ny(t0, t1)),
          Offset(b.nx(t0, t1), b.ny(t0, t1)),
          linePaint,
        );
      }
    }

    // --- Page1 skill bars (fade in t0, fade out t1) ---
    final barAlpha = t0 * (1.0 - t1);
    if (barAlpha > 0.02) {
      _drawSkillBars(canvas, size, barAlpha, nodes, t0, t1);
    }

    // --- Page2 kanban connections (fade in t1) ---
    if (t1 > 0.02) {
      _drawKanbanLinks(canvas, size, t1, nodes, t0, t1);
    }

    // --- Draw all nodes always ---
    for (final n in nodes) {
      final x = n.nx(t0, t1);
      final y = n.ny(t0, t1);
      final r = n.nr(t0, t1);
      if (r < 0.5) continue;
      paint.color = n.color;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawSkillBars(
    Canvas canvas,
    Size size,
    double alpha,
    List<_Node> nodes,
    double t0,
    double t1,
  ) {
    final w = size.width;
    final paint = Paint()..style = PaintingStyle.fill;
    final rows = [
      [nodes[0], 0.82, const Color(0xFF1A1A1A)],
      [nodes[1], 0.65, const Color(0xFF7C3AED)],
      [nodes[2], 0.50, const Color(0xFF9CA3AF)],
    ];
    for (final row in rows) {
      final node = row[0] as _Node;
      final fill = row[1] as double;
      final color = row[2] as Color;
      final nx = node.nx(t0, t1);
      final ny = node.ny(t0, t1);

      // Bar bg
      paint.color = const Color(0xFF1A1A1A).withValues(alpha: alpha * 0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(nx + 30, ny - 5, w * 0.52, 8),
          const Radius.circular(4),
        ),
        paint,
      );
      // Bar fill
      paint.color = color.withValues(alpha: alpha * 0.55);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(nx + 30, ny - 5, w * 0.52 * fill, 8),
          const Radius.circular(4),
        ),
        paint,
      );
      // Label stub
      paint.color = const Color(0xFF1A1A1A).withValues(alpha: alpha * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(nx + 30, ny + 9, w * 0.22, 6),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void _drawKanbanLinks(
    Canvas canvas,
    Size size,
    double alpha,
    List<_Node> nodes,
    double t0,
    double t1,
  ) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    final boardLeft = w * 0.06;
    final boardW = w * 0.88;
    final colW = boardW / 3 - 6;
    const colGap = 9.0;
    final boardTop = h * 0.14;
    final boardH = h * 0.52;

    final colColors = [
      const Color(0xFF1A1A1A),
      const Color(0xFF7C3AED),
      const Color(0xFF22C55E),
    ];
    final colLabels = [3, 2, 4];
    final progressSets = [
      [0.0, 0.0, 0.0],
      [0.35, 0.72, 0.55],
      [1.0, 1.0, 1.0],
    ];

    // Board background — large rounded container
    paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boardLeft - 8, boardTop - 10, boardW + 16, boardH + 20),
        const Radius.circular(18),
      ),
      paint,
    );

    // Board border
    final borderPaint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: alpha * 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boardLeft - 8, boardTop - 10, boardW + 16, boardH + 20),
        const Radius.circular(18),
      ),
      borderPaint,
    );

    for (int i = 0; i < 3; i++) {
      final cx = boardLeft + i * (colW + colGap);
      final color = colColors[i];

      // Column lane bg
      paint.color = const Color(0xFFF6F6F6).withValues(alpha: alpha * 0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, boardTop, colW, boardH),
          const Radius.circular(12),
        ),
        paint,
      );

      // Column header bar
      paint.color = color.withValues(alpha: alpha * 0.12);
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          cx, boardTop, cx + colW, boardTop + 28,
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
        ),
        paint,
      );

      // Header label skeleton
      paint.color = color.withValues(alpha: alpha * 0.4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 10, boardTop + 9, colW * 0.4, 8),
          const Radius.circular(4),
        ),
        paint,
      );

      // Count badge
      paint.color = color.withValues(alpha: alpha * 0.2);
      final badgeCx = cx + colW - 18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeCx - 6, boardTop + 6, 16, 14),
          const Radius.circular(4),
        ),
        paint,
      );

      // Cards — 3 per column with varying detail
      final cardCount = colLabels[i];
      final availableH = boardH - 40;
      final cardH = (availableH - (cardCount - 1) * 8) / cardCount;
      final maxCards = cardCount.clamp(0, 3);

      for (int j = 0; j < maxCards; j++) {
        final cy = boardTop + 34 + j * (cardH + 8);
        final ch = cardH.clamp(30.0, 100.0);
        final stagger = alpha * (1.0 - j * 0.1).clamp(0.5, 1.0);

        // Card shadow
        paint.color =
            const Color(0xFF000000).withValues(alpha: stagger * 0.035);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 5, cy + 3, colW - 14, ch),
            const Radius.circular(8),
          ),
          paint,
        );

        // Card body
        paint.color =
            const Color(0xFFFFFFFF).withValues(alpha: stagger * 0.95);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 4, cy, colW - 12, ch),
            const Radius.circular(8),
          ),
          paint,
        );

        // Top accent bar
        paint.color = color.withValues(alpha: stagger * 0.7);
        canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            cx + 4, cy, cx + colW - 8, cy + 3,
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
          ),
          paint,
        );

        // Title skeleton (2 widths for variety)
        paint.color =
            const Color(0xFF1A1A1A).withValues(alpha: stagger * 0.14);
        final titleW = (j % 2 == 0) ? colW * 0.52 : colW * 0.65;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 12, cy + 12, titleW, 6),
            const Radius.circular(3),
          ),
          paint,
        );

        // Subtitle skeleton
        if (ch > 50) {
          paint.color =
              const Color(0xFF1A1A1A).withValues(alpha: stagger * 0.07);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(cx + 12, cy + 24, colW * 0.38, 5),
              const Radius.circular(3),
            ),
            paint,
          );
        }

        // Progress bar
        if (ch > 60) {
          final barY = cy + ch - 18;
          final barW = colW - 32;
          paint.color =
              const Color(0xFF1A1A1A).withValues(alpha: stagger * 0.06);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(cx + 12, barY, barW, 4),
              const Radius.circular(2),
            ),
            paint,
          );
          paint.color = color.withValues(alpha: stagger * 0.5);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                cx + 12,
                barY,
                barW * progressSets[i][j.clamp(0, 2)],
                4,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
        }

        // Bottom-right avatar dot (assignee indicator)
        if (ch > 55) {
          paint.color = color.withValues(alpha: stagger * 0.25);
          canvas.drawCircle(
            Offset(cx + colW - 22, cy + ch - 14),
            5,
            paint,
          );
        }
      }
    }

    // Flow arrows between columns
    if (alpha > 0.15) {
      final arrowPaint = Paint()
        ..color = const Color(0xFF1A1A1A).withValues(alpha: alpha * 0.08)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 2; i++) {
        final fromX = boardLeft + (i + 1) * (colW + colGap) - colGap / 2;
        final arrowY = boardTop + boardH * 0.35;
        canvas.drawLine(
          Offset(fromX - 4, arrowY),
          Offset(fromX + 4, arrowY),
          arrowPaint,
        );
        // Arrow head
        final headPaint = Paint()
          ..color = const Color(0xFF1A1A1A).withValues(alpha: alpha * 0.08)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(fromX + 1, arrowY - 3),
          Offset(fromX + 4, arrowY),
          headPaint,
        );
        canvas.drawLine(
          Offset(fromX + 1, arrowY + 3),
          Offset(fromX + 4, arrowY),
          headPaint,
        );
      }
    }

    // AI warning badge — floating element near the second column
    if (alpha > 0.3) {
      final badgeX = boardLeft + colW + colGap + colW * 0.15;
      final badgeY = boardTop + boardH - 18;
      final badgeW = colW * 0.7;
      final badgeAlpha = (alpha - 0.3) / 0.7;

      // Badge shadow
      paint.color =
          const Color(0xFFF59E0B).withValues(alpha: badgeAlpha * 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeX - 1, badgeY + 2, badgeW + 2, 20),
          const Radius.circular(6),
        ),
        paint,
      );

      // Badge body
      paint.color =
          const Color(0xFFFFFBEB).withValues(alpha: badgeAlpha * 0.92);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeX, badgeY, badgeW, 18),
          const Radius.circular(5),
        ),
        paint,
      );

      // Warning dot
      paint.color =
          const Color(0xFFF59E0B).withValues(alpha: badgeAlpha * 0.8);
      canvas.drawCircle(Offset(badgeX + 8, badgeY + 9), 3, paint);

      // Warning text skeleton
      paint.color =
          const Color(0xFFF59E0B).withValues(alpha: badgeAlpha * 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeX + 16, badgeY + 6, badgeW * 0.5, 5),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ContinuousMorphPainter old) =>
      old.pageOffset != pageOffset;
}

class _Node {
  final List<double> kx; // x keyframes [page0, page1, page2]
  final List<double> ky;
  final List<double> kr; // radius keyframes
  final Color color;

  const _Node({
    required this.kx,
    required this.ky,
    required this.kr,
    required this.color,
  });

  double _lerp3(List<double> vals, double t0, double t1) {
    if (t0 < 1.0) return vals[0] + (vals[1] - vals[0]) * t0;
    return vals[1] + (vals[2] - vals[1]) * t1;
  }

  double nx(double t0, double t1) => _lerp3(kx, t0, t1);
  double ny(double t0, double t1) => _lerp3(ky, t0, t1);
  double nr(double t0, double t1) => _lerp3(kr, t0, t1);
}
