import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// Splash 页面 — 纯展示，不做导航决策
/// 导航由 GoRouter redirect 统一处理（当 authState.isInitialized 变为 true 后自动跳转）
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '开造',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '点亮每一个想法',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
