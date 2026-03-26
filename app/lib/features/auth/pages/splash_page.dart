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

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _sloganController;
  late AnimationController _buttonController;
  late Animation<double> _scaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _sloganOpacityAnim;
  late Animation<double> _buttonOpacityAnim;
  late Animation<Offset> _buttonSlideAnim;

  // DEBUG: 改这里强制跳到指定页面（仅 debug 模式生效）
  static const String? _debugForceRoute = kDebugMode ? RoutePaths.splash : null;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF6F6F6),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),);

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sloganController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _sloganOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sloganController, curve: Curves.easeOut),
    );
    _buttonOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
    _buttonSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _sloganController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _buttonController.forward();
  }

  Future<void> _onStart() async {
    if (kDebugMode && _debugForceRoute == RoutePaths.splash) {
      // Debug: always go to onboarding
      context.go(RoutePaths.onboarding);
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
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _sloganController,
          _buttonController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // Centered logo + text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: _logoOpacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: CustomPaint(painter: _VccLogoPainter()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: _logoOpacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: const Column(
                          children: [
                            Text(
                              'VCC',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 6,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '开造',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Opacity(
                      opacity: _sloganOpacityAnim.value,
                      child: const Text(
                        '点亮每一个想法',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Start button at bottom
              Positioned(
                left: 32,
                right: 32,
                bottom: padding.bottom + 48,
                child: FadeTransition(
                  opacity: _buttonOpacityAnim,
                  child: SlideTransition(
                    position: _buttonSlideAnim,
                    child: GestureDetector(
                      onTap: _onStart,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '开始',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VccLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    // Left triangle — dark
    paint.color = const Color(0xFF1A1A1A);
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w * 0.5, 0)
        ..lineTo(w * 0.36, h)
        ..close(),
      paint,
    );

    // Center triangle — mid gray
    paint.color = const Color(0xFF6B7280);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.33, h)
        ..lineTo(w * 0.67, h)
        ..lineTo(w * 0.5, h * 0.32)
        ..close(),
      paint,
    );

    // Right triangle — light gray
    paint.color = const Color(0xFFD4D4D4);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.64, h)
        ..lineTo(w, h)
        ..lineTo(w * 0.5, 0)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
