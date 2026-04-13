import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../profile/providers/profile_provider.dart';
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
      primaryActionText: '开始创建',
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
        ref.invalidate(profileProvider('me'));
        if (context.mounted) context.go(RoutePaths.home);
      },
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 36),
          Text('把第一个需求发出来', style: AppTextStyles.onboardingTitle),
          SizedBox(height: 12),
          Text(
            '先把要做的事讲清一点，这页就会先把骨架搭出来。',
            style: AppTextStyles.onboardingBody,
          ),
          SizedBox(height: 28),
          _RequirementDraftPreview(),
          SizedBox(height: 18),
          OnboardingSectionHeader(
            title: '先把骨架搭起来',
            description: '你不用一上来就写完整文档，先把方向说清，结构会慢慢长出来。',
            accessory: OnboardingHelperTag(text: '先搭骨架，再慢慢补细节'),
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
            '需求草稿',
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
            '等你补充项目关键信息',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '已按项目摘要结构预排版',
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
