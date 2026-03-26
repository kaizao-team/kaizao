import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../providers/onboarding_provider.dart';

/// ONBOARD-004: 引导需求方 — 完成页
class DemanderCompletePage extends ConsumerWidget {
  const DemanderCompletePage({super.key});

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
                currentStep: 3,
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
                        color: const Color.fromRGBO(16, 185, 129, 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      '需求已发布!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '坐等专家来报价，或主动找专家聊聊',
                      style: TextStyle(fontSize: 15, color: AppColors.gray500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: VccButton(
                text: '进入需求详情',
                onPressed: () async {
                  await ref.read(onboardingProvider.notifier).complete();
                  if (context.mounted) context.go(RoutePaths.home);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: VccButton(
                text: '去首页',
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
