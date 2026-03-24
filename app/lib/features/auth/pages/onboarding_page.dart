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
    const _OnboardingData(
      icon: Icons.psychology_outlined,
      title: 'AI 帮你理清需求',
      description: '只需描述你的想法，AI 会通过对话帮你梳理需求，自动生成专业的项目需求文档',
    ),
    const _OnboardingData(
      icon: Icons.groups_outlined,
      title: '智能匹配造物者',
      description: '基于技能、评价、作品多维度分析，为你精准推荐最合适的开发者或团队',
    ),
    const _OnboardingData(
      icon: Icons.dashboard_customize_outlined,
      title: '透明管理全流程',
      description: '可视化看板追踪每个任务进度，AI 智能预警风险，担保交易安心付款',
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    '跳过',
                    style: TextStyle(fontSize: 14, color: AppColors.gray400),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(page.icon, size: 56, color: AppColors.black),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.gray500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.black : AppColors.gray300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  if (_currentPage == _pages.length - 1)
                    VccButton(text: '开始使用', onPressed: _finish)
                  else
                    VccButton(
                      text: '继续',
                      type: VccButtonType.secondary,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
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

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
