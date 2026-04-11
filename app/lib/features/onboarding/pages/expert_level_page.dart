import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/skills/app_skill_icon.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

const _expertLevelStepLabels = ['资料', '补充', '等级'];

/// ONBOARD-007: 团队定级展示
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
    ref.invalidate(profileProvider('me'));
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
    if (rating >= 5) return '资深';
    if (rating == 4) return '出众';
    if (rating == 3) return '熟练';
    return '初启';
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
      primaryActionText: _showResult ? '开始接单' : '正在生成团队等级',
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
                rating: rating,
                availability: availability,
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
        const Text('正在生成你的团队等级', style: AppTextStyles.onboardingTitle),
        const SizedBox(height: 12),
        const Text(
          'AI 正在把你的能力、排期与协作方式压成一张初始团队画像。',
          style: AppTextStyles.onboardingBody,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'AI ASSESSMENT',
              style: AppTextStyles.onboardingMeta.copyWith(
                color: AppColors.onboardingPrimary,
              ),
            ),
            const Spacer(),
            const OnboardingStatusBadge(text: '评估中', animate: true),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIGNAL BUILDING',
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.white.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '你的起始档案正在成形',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.white,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '通常只需 2-3 秒，系统会先给你一个能进入市场的起始位。',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _AssessmentRow(
          title: '技能栈解析中',
          description: '整理你的核心能力与交付方向',
        ),
        const SizedBox(height: 10),
        const _AssessmentRow(
          title: '协作方式生成中',
          description: '推导适合你的接单节奏与沟通模式',
        ),
        const SizedBox(height: 10),
        const _AssessmentRow(
          title: '接单建议生成中',
          description: '准备一版可直接进入市场的初始档案',
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
  final int rating;
  final String availability;
  final String hint;

  const _AssessmentResultView({
    super.key,
    required this.levelCode,
    required this.levelTitle,
    required this.skills,
    required this.rating,
    required this.availability,
    required this.hint,
  });

  double _availabilityScore() {
    switch (availability) {
      case '随时':
        return 1;
      case '1周内':
        return 0.82;
      case '1-2周':
        return 0.68;
      case '1个月内':
        return 0.52;
      default:
        return 0.36;
    }
  }

  String _availabilityLabel() {
    return availability.isEmpty ? '排期待补充' : availability;
  }

  String _ratingHint() {
    switch (rating) {
      case 5:
        return '你已经具备主导关键路径的信号，适合接高判断密度的项目。';
      case 4:
        return '复杂协作和稳定交付是你的起点，可以直接接中高复杂度项目。';
      case 3:
        return '独立推进能力已经成形，先用真实案例把信任继续往上拉。';
      default:
        return '先用清晰案例和高响应速度，把第一批信号建立起来。';
    }
  }

  double _marketScore() {
    final skillScore = (skills.take(4).length / 4).clamp(0.25, 1.0);
    return ((rating / 5) * 0.58 + skillScore * 0.42).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final highlightedSkillCount = skills.take(4).length;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text('你的团队等级已生成', style: AppTextStyles.onboardingTitle),
        const SizedBox(height: 12),
        const Text(
          '这不是终局评级，而是你进入 KAIZO 团队网络的起始位。后面的真实合作会继续抬高它。',
          style: AppTextStyles.onboardingBody,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'TEAM SIGNAL READY',
              style: AppTextStyles.onboardingMeta.copyWith(
                color: AppColors.onboardingPrimary,
              ),
            ),
            const Spacer(),
            const OnboardingStatusBadge(text: '档案已激活', animate: true),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                levelCode,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 40,
                  color: AppColors.white,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                levelTitle,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 24,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '你的技能结构和协作状态已经足够形成第一版市场画像。先进入网络，再用真实交付继续抬升。',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .take(4)
                      .map(
                        (skill) => OnboardingIconTag(
                          label: skill,
                          icon: Icons.bolt_rounded,
                          iconWidget: AppSkillIcon(skill: skill, size: 15),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AssessmentSignalRail(
          label: '能力密度',
          value: '$rating / 5',
          hint: _ratingHint(),
          progress: rating / 5,
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 10),
        _AssessmentSignalRail(
          label: '协作准备',
          value: _availabilityLabel(),
          hint: hint,
          progress: _availabilityScore(),
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: 10),
        _AssessmentSignalRail(
          label: '市场起步',
          value: '$highlightedSkillCount 项主力方向',
          hint: '把前几个案例和响应速度做好，平台会更愿意把高意向项目推给你。',
          progress: _marketScore(),
          icon: Icons.rocket_launch_outlined,
        ),
        const SizedBox(height: 16),
        const OnboardingInfoBlock(
          icon: Icons.trending_up_rounded,
          title: '等级先给入口，案例再拉成交',
          description: '真正决定你能不能持续接到好项目的，还是案例质量、响应速度和交付记录。',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AssessmentSignalRail extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final double progress;
  final IconData icon;

  const _AssessmentSignalRail({
    required this.label,
    required this.value,
    required this.hint,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.onboardingSurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  color: AppColors.onboardingHairline,
                ),
                FractionallySizedBox(
                  widthFactor: clamped,
                  child: OnboardingSheen(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    duration: const Duration(milliseconds: 2200),
                    sheenWidthFactor: 0.38,
                    child: Container(
                      height: 4,
                      color: AppColors.onboardingPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            hint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onboardingMutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
