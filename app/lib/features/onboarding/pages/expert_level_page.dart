import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

const _expertLevelStepLabels = ['资料', '补充', '等级'];

/// ONBOARD-007: 专家定级展示
class ExpertLevelPage extends ConsumerStatefulWidget {
  const ExpertLevelPage({super.key});

  @override
  ConsumerState<ExpertLevelPage> createState() => _ExpertLevelPageState();
}

class _ExpertLevelPageState extends ConsumerState<ExpertLevelPage> {
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _showResult = true);
      }
    });
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).complete();
    if (context.mounted) {
      context.go(RoutePaths.home);
    }
  }

  String _levelCode(int rating) {
    if (rating >= 5) return 'Lv.4';
    if (rating == 4) return 'Lv.3';
    if (rating == 3) return 'Lv.2';
    return 'Lv.1';
  }

  String _levelTitle(int rating) {
    if (rating >= 5) return '领航';
    if (rating == 4) return '资深';
    if (rating == 3) return '进阶';
    return '新星';
  }

  String _collaborationHint(String availability) {
    if (availability.isEmpty) return '建议先保持高响应速度，尽快完成首个合作。';
    if (availability == '随时') return '当前可快速进入项目，是接高意向需求的最佳状态。';
    return '排期已明确，平台会优先匹配节奏合适的需求。';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider).draft;
    final skills = (draft['skills'] as List?)?.cast<String>() ?? [];
    final rating = (draft['self_rating'] as int?) ?? 3;
    final availability = draft['availability'] as String? ?? '';

    return OnboardingScaffold(
      currentStep: 2,
      stepLabels: _expertLevelStepLabels,
      onBack: () async {
        await ref.read(onboardingProvider.notifier).goToStep(1);
        if (context.mounted) {
          context.go(RoutePaths.expertOnboarding2);
        }
      },
      primaryActionText: _showResult ? '开始接单' : '正在生成专家等级',
      onPrimaryAction: _showResult ? () => _finish(context, ref) : null,
      secondaryActionText: _showResult ? '去首页' : null,
      onSecondaryAction: _showResult ? () => _finish(context, ref) : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: AppCurves.standard,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _showResult
            ? _AssessmentResultView(
                key: const ValueKey('result'),
                levelCode: _levelCode(rating),
                levelTitle: _levelTitle(rating),
                skills: skills,
                hint: _collaborationHint(availability),
              )
            : const _AssessmentLoadingView(key: ValueKey('loading')),
      ),
    );
  }
}

class _AssessmentLoadingView extends StatelessWidget {
  const _AssessmentLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 34),
        const Text('正在生成你的专家等级', style: AppTextStyles.onboardingTitle),
        const SizedBox(height: 12),
        const Text(
          'AI 正在整理你的技能、协作方式与接单节奏，生成一版初始专家档案。',
          style: AppTextStyles.onboardingBody,
        ),
        const SizedBox(height: 28),
        Container(
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
                    'AI ASSESSMENT',
                    style: AppTextStyles.onboardingMeta.copyWith(
                      color: AppColors.onboardingPrimary,
                    ),
                  ),
                  const Spacer(),
                  const OnboardingStatusBadge(text: '评估中'),
                ],
              ),
              const SizedBox(height: 20),
              const _AssessmentRow(
                title: '技能栈解析中',
                description: '整理你的核心能力与交付方向',
              ),
              const SizedBox(height: 12),
              const _AssessmentRow(
                title: '协作方式生成中',
                description: '推导适合你的接单节奏与沟通模式',
              ),
              const SizedBox(height: 12),
              const _AssessmentRow(
                title: '接单建议生成中',
                description: '准备一版可直接进入市场的初始档案',
              ),
              const SizedBox(height: 18),
              Text(
                '通常只需 2-3 秒',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const OnboardingInfoBlock(
          icon: Icons.auto_awesome_outlined,
          title: '先建立可信度，再建立成交',
          description: '等级只是起点。真正提升曝光和转化的，是你后续的案例质量、响应速度与交付记录。',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  final String title;
  final String description;

  const _AssessmentRow({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.onboardingSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.checklist_rtl_rounded,
              color: AppColors.gray400,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                const OnboardingSkeletonBlock(
                  width: 118,
                  height: 8,
                  color: AppColors.gray200,
                ),
                const SizedBox(height: 6),
                OnboardingSkeletonBlock(
                  width: description.length > 16 ? 148 : 112,
                  height: 8,
                  color: AppColors.gray100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentResultView extends StatelessWidget {
  final String levelCode;
  final String levelTitle;
  final List<String> skills;
  final String hint;

  const _AssessmentResultView({
    super.key,
    required this.levelCode,
    required this.levelTitle,
    required this.skills,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text('你的专家等级已生成', style: AppTextStyles.onboardingTitle),
        const SizedBox(height: 12),
        const Text(
          '这会作为你进入 Kaizao 专家网络的初始档案。完成真实合作后，平台会继续修正它。',
          style: AppTextStyles.onboardingBody,
        ),
        const SizedBox(height: 24),
        Container(
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
                    'EXPERT LEVEL GENERATED',
                    style: AppTextStyles.onboardingMeta.copyWith(
                      color: AppColors.onboardingPrimary,
                    ),
                  ),
                  const Spacer(),
                  const OnboardingStatusBadge(text: '档案已激活'),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    color: AppColors.onboardingSurfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.onboardingPrimary,
                      width: 2.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        levelCode,
                        style: AppTextStyles.h1.copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        levelTitle,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (skills.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .take(4)
                      .map(
                        (skill) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onboardingSurfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            skill,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
              ],
              const Row(
                children: [
                  Expanded(
                    child: _LevelMetric(
                      label: '档案状态',
                      value: '已进入专家网络',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _LevelMetric(
                      label: '下一步',
                      value: '完善案例并开始接单',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _LevelMetric(
                label: '平台建议',
                value: hint,
                fullWidth: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const OnboardingInfoBlock(
          icon: Icons.trending_up_rounded,
          title: '完成首单后，曝光会更快提升',
          description: '真实合作记录、响应速度和交付质量，会直接影响你在需求方侧的可信度与排序。',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LevelMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool fullWidth;

  const _LevelMetric({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.onboardingMeta.copyWith(
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
