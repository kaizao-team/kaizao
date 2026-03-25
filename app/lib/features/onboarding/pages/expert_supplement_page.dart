import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

const _expertSupplementStepLabels = ['资料', '补充', '等级'];

/// ONBOARD-006: 引导专家补充评估信息
class ExpertSupplementPage extends ConsumerStatefulWidget {
  const ExpertSupplementPage({super.key});

  @override
  ConsumerState<ExpertSupplementPage> createState() =>
      _ExpertSupplementPageState();
}

class _ExpertSupplementPageState extends ConsumerState<ExpertSupplementPage> {
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _bioController.text = draft['bio'] as String? ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  InputDecoration _bioDecoration() {
    return InputDecoration(
      hintText: '介绍你的经验、擅长领域和代表项目，也可以说明你偏好的合作方式。',
      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.gray400),
      contentPadding: const EdgeInsets.all(14),
      filled: true,
      fillColor: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.65),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.onboardingHairline.withValues(alpha: 0.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.onboardingPrimary,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.onboardingHairline.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final notifier = ref.read(onboardingProvider.notifier);
    await notifier.submitData({
      'bio': _bioController.text.trim(),
    });
    if (!mounted) return;

    await notifier.nextStep();
    if (mounted) context.go(RoutePaths.expertOnboarding3);
  }

  Future<void> _skip() async {
    await ref.read(onboardingProvider.notifier).nextStep();
    if (!mounted) return;
    context.go(RoutePaths.expertOnboarding3);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return OnboardingScaffold(
      currentStep: 1,
      stepLabels: _expertSupplementStepLabels,
      onBack: () async {
        await ref.read(onboardingProvider.notifier).goToStep(0);
        if (context.mounted) {
          context.go(RoutePaths.expertOnboarding1);
        }
      },
      primaryActionText: '生成专家等级',
      onPrimaryAction: _submit,
      isPrimaryLoading: state.isLoading,
      secondaryActionText: '暂时跳过',
      onSecondaryAction: _skip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('补充案例与定位', style: AppTextStyles.onboardingTitle),
          const SizedBox(height: 12),
          const Text(
            '上传几张代表性案例，写一段足够真实的自我介绍。需求方会先看到这些信息。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 28),
          const _PortfolioDraftWall(),
          const SizedBox(height: 18),
          Row(
            children: [
              const OnboardingHelperTag(
                text: '先放草图、截图或上线页面都可以',
                icon: Icons.grid_view_rounded,
              ),
              const Spacer(),
              Text(
                '最多 5 个案例',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              Text(
                '个人简介',
                style: AppTextStyles.onboardingSectionLabel,
              ),
              Spacer(),
              OnboardingHelperTag(text: '建议 80-160 字'),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            maxLines: 6,
            maxLength: 200,
            style: AppTextStyles.input.copyWith(fontSize: 15),
            decoration: _bioDecoration(),
          ),
          const SizedBox(height: 18),
          const OnboardingInfoBlock(
            icon: Icons.visibility_outlined,
            title: '先看案例，再决定是否联系',
            description: '需求方通常会先看你的案例风格、简介和协作方式，再决定是否进入沟通。',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PortfolioDraftWall extends StatelessWidget {
  const _PortfolioDraftWall();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.62),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PORTFOLIO DRAFT',
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.onboardingPrimary,
                ),
              ),
              const Spacer(),
              const OnboardingStatusBadge(text: '案例整理中'),
            ],
          ),
          const SizedBox(height: 18),
          const SizedBox(
            height: 208,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _PortfolioPlaceholderTile(
                    indexLabel: 'CASE 01',
                    large: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: _PortfolioPlaceholderTile(indexLabel: 'CASE 02'),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: _PortfolioPlaceholderTile(indexLabel: 'CASE 03'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '案例越具体，越容易建立信任。即使还没有正式作品，也可以先放概念稿或过程截图。',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioPlaceholderTile extends StatelessWidget {
  final String indexLabel;
  final bool large;

  const _PortfolioPlaceholderTile({
    required this.indexLabel,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 16 : 14),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indexLabel,
            style: AppTextStyles.onboardingMeta.copyWith(
              color: AppColors.gray400,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.onboardingPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
          SizedBox(height: large ? 18 : 12),
          OnboardingSkeletonBlock(
            width: large ? 128 : 88,
            height: 8,
            color: AppColors.gray200,
          ),
          const SizedBox(height: 8),
          OnboardingSkeletonBlock(
            width: large ? 96 : 64,
            height: 8,
            color: AppColors.gray100,
          ),
        ],
      ),
    );
  }
}
