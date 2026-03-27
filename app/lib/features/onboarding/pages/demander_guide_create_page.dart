import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

/// ONBOARD-002: 引导项目方点击"+"创建项目
class DemanderGuideCreatePage extends ConsumerWidget {
  const DemanderGuideCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingScaffold(
      currentStep: 1,
      onBack: () async {
        await ref.read(onboardingProvider.notifier).goToStep(0);
        if (context.mounted) {
          context.go(RoutePaths.demanderOnboarding1);
        }
      },
      primaryActionText: '创建需求',
      onPrimaryAction: () async {
        final projectId = await ref
            .read(onboardingProvider.notifier)
            .createDemanderProjectDraft();
        if (projectId == null) {
          final message = ref.read(onboardingProvider).errorMessage;
          if (context.mounted && message != null) {
            VccToast.show(
              context,
              message: message,
              type: VccToastType.error,
            );
          }
          return;
        }

        await ref.read(onboardingProvider.notifier).nextStep();
        if (context.mounted) {
          context.go(RoutePaths.demanderOnboarding3);
        }
      },
      isPrimaryLoading: state.isLoading,
      secondaryActionText: '先逛逛',
      onSecondaryAction: () async {
        await ref.read(onboardingProvider.notifier).complete();
        if (context.mounted) context.go(RoutePaths.home);
      },
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 36),
          Text('发布你的第一个需求', style: AppTextStyles.onboardingTitle),
          SizedBox(height: 12),
          Text(
            '描述你想要实现的功能，AI 会帮你整理成更清晰的项目需求文档。',
            style: AppTextStyles.onboardingBody,
          ),
          SizedBox(height: 28),
          _RequirementDraftPreview(),
          SizedBox(height: 18),
          OnboardingSectionHeader(
            title: '先让 AI 起一版草稿',
            description: '你不用从 PRD 开始，只要先把方向说清，结构会慢慢长出来。',
            accessory: OnboardingHelperTag(text: 'AI 会先帮你整理结构'),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RequirementDraftPreview extends StatelessWidget {
  const _RequirementDraftPreview();

  @override
  Widget build(BuildContext context) {
    return OnboardingDeckCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REQUIREMENT DRAFT',
            style: AppTextStyles.onboardingMeta.copyWith(
              color: AppColors.onboardingPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const OnboardingSkeletonBlock(
            width: 156,
            height: 34,
            radius: 10,
            color: AppColors.onboardingSurfaceMuted,
          ),
          const SizedBox(height: 18),
          ...List.generate(3, (index) {
            final widths = [0.82, 0.68, 0.54];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FractionallySizedBox(
                widthFactor: widths[index],
                child: const OnboardingSkeletonBlock(
                  height: 8,
                  color: AppColors.gray100,
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: List.generate(2, (index) {
              return Expanded(
                child: Container(
                  height: 54,
                  margin: EdgeInsets.only(right: index == 0 ? 10 : 0),
                  child: const OnboardingSkeletonBlock(
                    height: 54,
                    radius: 12,
                    color: AppColors.onboardingSurfaceMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          Text(
            'Waiting for your input...',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'PROFESSIONAL STANDARDS APPLIED',
              style: AppTextStyles.onboardingMeta.copyWith(
                color: AppColors.gray400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
