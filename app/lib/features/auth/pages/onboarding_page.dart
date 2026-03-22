import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/widgets/vcc_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.psychology,
      title: 'AI帮你理清需求',
      description: '只需描述你的想法，AI会通过对话帮你梳理需求，自动生成专业的项目需求文档',
      bgColor: const Color(0xFFF8F7FF),
    ),
    _OnboardingData(
      icon: Icons.groups,
      title: '智能匹配造物者',
      description: '基于技能、评价、作品多维度分析，为你精准推荐最合适的开发者或团队',
      bgColor: const Color(0xFFEFF6FF),
    ),
    _OnboardingData(
      icon: Icons.dashboard_customize,
      title: '透明管理全流程',
      description: '可视化看板追踪每个任务进度，AI智能预警风险，担保交易安心付款',
      bgColor: AppColors.gray50,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await StorageService().setFirstLaunchDone();
    if (mounted) context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Container(
                  color: page.bgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.shadow2,
                        ),
                        child: Icon(
                          page.icon,
                          size: 80,
                          color: AppColors.brandPurple,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        page.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.gray500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                );
              },
            ),
            // 跳过按钮
            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  '跳过',
                  style: TextStyle(fontSize: 14, color: AppColors.gray400),
                ),
              ),
            ),
            // 底部指示器 + 按钮
            Positioned(
              bottom: 48,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: isActive ? AppGradients.primaryButton : null,
                          color: isActive ? null : AppColors.gray300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  if (_currentPage == _pages.length - 1)
                    VccButton(text: '开始使用', onPressed: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color bgColor;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.bgColor,
  });
}
