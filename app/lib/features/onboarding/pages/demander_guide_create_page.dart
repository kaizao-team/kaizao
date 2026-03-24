import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../providers/onboarding_provider.dart';

/// ONBOARD-002: 引导需求方点击"+"创建需求
class DemanderGuideCreatePage extends ConsumerWidget {
  const DemanderGuideCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: VccStepIndicator(
                totalSteps: 4,
                currentStep: 1,
                labels: const ['资料', '创建需求', '填写信息', '完成'],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.add_circle_outline, size: 48, color: AppColors.black),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '发布你的第一个需求',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '描述你想要实现的功能，AI 会帮你生成\n专业的项目需求文档',
                      style: TextStyle(fontSize: 15, color: AppColors.gray500, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: VccButton(
                text: '创建需求',
                icon: Icons.add,
                onPressed: () async {
                  await ref.read(onboardingProvider.notifier).nextStep();
                  if (context.mounted) {
                    context.go(RoutePaths.demanderOnboarding3);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: VccButton(
                text: '先逛逛',
                type: VccButtonType.ghost,
                onPressed: () async {
                  await ref.read(onboardingProvider.notifier).complete();
                  if (context.mounted) context.go(RoutePaths.home);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
