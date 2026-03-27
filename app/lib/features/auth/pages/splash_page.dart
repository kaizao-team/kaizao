import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _sloganController;
  late AnimationController _buttonController;
  late Animation<double> _scaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _sloganOpacityAnim;
  late Animation<double> _buttonOpacityAnim;
  late Animation<Offset> _buttonSlideAnim;

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
    await ref.read(authStateProvider.notifier).resetForFreshStart();
    await ref.read(onboardingProvider.notifier).reset();
    if (!mounted) return;
    context.go(RoutePaths.onboarding);
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
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: _logoOpacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: SizedBox(
                          width: 212,
                          height: 212,
                          child: Image.asset(
                            'assets/branding/app_launch_motion_flat.webp',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.low,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Opacity(
                      opacity: _logoOpacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: const Column(
                          children: [
                            Text(
                              'KAIZAO',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 6,
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
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: padding.bottom + 34,
                child: FadeTransition(
                  opacity: _buttonOpacityAnim,
                  child: SlideTransition(
                    position: _buttonSlideAnim,
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '开始',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
