import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../providers/onboarding_provider.dart';

/// ONBOARD-007: 专家定级展示
class ExpertLevelPage extends ConsumerStatefulWidget {
  const ExpertLevelPage({super.key});

  @override
  ConsumerState<ExpertLevelPage> createState() => _ExpertLevelPageState();
}

class _ExpertLevelPageState extends ConsumerState<ExpertLevelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _showResult = true);
        _controller.forward();
      }
    });
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: VccStepIndicator(
                totalSteps: 3,
                currentStep: 2,
                labels: const ['专家资料', '补充信息', '等级评定'],
              ),
            ),
            Expanded(
              child: Center(
                child: _showResult ? _buildResult() : _buildLoading(),
              ),
            ),
            if (_showResult)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: VccButton(
                  text: '开始接单',
                  onPressed: () async {
                    await ref.read(onboardingProvider.notifier).complete();
                    if (mounted) context.go(RoutePaths.home);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AI 正在评估你的能力...',
          style: TextStyle(fontSize: 16, color: AppColors.gray500),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final draft = ref.read(onboardingProvider).draft;
    final skills = (draft['skills'] as List?)?.cast<String>() ?? [];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.black, width: 3),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lv.1', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.black)),
                  Text('新星', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray600)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '恭喜，你已通过能力评估!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.black),
            ),
            const SizedBox(height: 12),
            if (skills.isNotEmpty)
              Text(
                '擅长领域：${skills.join("、")}',
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            const Text(
              '完成项目可提升等级，获得更多曝光',
              style: TextStyle(fontSize: 14, color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
