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
            '先摆出你最能打的一组作品，再补一句像你本人会说的话。需求方先感受到你，再决定要不要聊。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 28),
          const _PortfolioDraftWall(),
          const SizedBox(height: 18),
          const OnboardingSectionHeader(
            title: '案例不是装饰，是信任入口',
            description: '先上传最能代表你风格和判断力的内容，草图、过程图和交付截图都可以。',
            accessory: OnboardingHelperTag(
              text: '最多 5 个案例',
              icon: Icons.grid_view_rounded,
            ),
          ),
          const SizedBox(height: 32),
          const OnboardingSectionHeader(
            title: '写一段像你本人会说的话',
            description: '别写成标准简历。像第一次开口介绍自己，让对方知道你擅长什么、怎么合作。',
            accessory: OnboardingHelperTag(text: '建议 80-160 字'),
          ),
          const SizedBox(height: 10),
          OnboardingDeckCard(
            child: TextField(
              controller: _bioController,
              maxLines: 6,
              maxLength: 200,
              style: AppTextStyles.input.copyWith(fontSize: 15),
              decoration: _bioDecoration(),
            ),
          ),
          const SizedBox(height: 18),
          const OnboardingInfoBlock(
            icon: Icons.visibility_outlined,
            title: '先被看懂，才会被联系',
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
    return OnboardingDeckCard(
      elevated: true,
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
              const OnboardingStatusBadge(text: '案例整理中', animate: true),
            ],
          ),
          const SizedBox(height: 18),
          const _PortfolioHeroTile(),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _PortfolioMiniTile(
                  indexLabel: 'CASE 02',
                  descriptor: '过程拆解',
                  icon: Icons.layers_outlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _PortfolioMiniTile(
                  indexLabel: 'CASE 03',
                  descriptor: '交付结果',
                  icon: Icons.open_in_new_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '先用一个主案例把能力立住，再补过程图和结果页，信任会快很多。',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioHeroTile extends StatelessWidget {
  const _PortfolioHeroTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CASE 01',
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.gray400,
                ),
              ),
              const Spacer(),
              const OnboardingHelperTag(
                text: '主案例',
                icon: Icons.image_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.onboardingSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.onboardingHairline.withValues(alpha: 0.42),
              ),
            ),
            child: const Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OnboardingSkeletonBlock(
                          width: double.infinity,
                          height: 56,
                          radius: 14,
                          color: AppColors.gray100,
                        ),
                        SizedBox(height: 10),
                        OnboardingSkeletonBlock(
                          width: 118,
                          height: 8,
                          color: AppColors.gray200,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: _PortfolioAddButton(size: 38),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '第一张先放最能代表你判断力和完成度的作品。',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioMiniTile extends StatelessWidget {
  final String indexLabel;
  final String descriptor;
  final IconData icon;

  const _PortfolioMiniTile({
    required this.indexLabel,
    required this.descriptor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
          Row(
            children: [
              Text(
                indexLabel,
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.gray400,
                ),
              ),
              const Spacer(),
              Icon(
                icon,
                size: 15,
                color: AppColors.gray400,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const _PortfolioAddButton(size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descriptor,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onboardingMutedText,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const OnboardingSkeletonBlock(
                      width: 42,
                      height: 7,
                      color: AppColors.gray200,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioAddButton extends StatelessWidget {
  final double size;

  const _PortfolioAddButton({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.onboardingPrimary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add_rounded,
        color: AppColors.white,
        size: size * 0.48,
      ),
    );
  }
}
