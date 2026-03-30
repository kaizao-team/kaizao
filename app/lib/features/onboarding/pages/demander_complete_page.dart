import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/project_category.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

/// ONBOARD-004: 引导项目方 — 完成页
class DemanderCompletePage extends ConsumerWidget {
  const DemanderCompletePage({super.key});

  String _displayCategoryLabel(String? value) {
    switch (value?.trim() ?? '') {
      case 'APP开发':
      case '网站开发':
      case '小程序':
      case 'dev':
      case 'app':
      case 'web':
      case 'backend':
        return '研发';
      case 'UI设计':
      case '品牌设计':
      case 'visual':
      case 'design':
        return '视觉设计';
      case '数据分析':
      case 'data':
      case 'ai':
        return '数据';
      case '技术指导':
      case '解决方案':
      case 'solution':
      case 'consult':
      case 'other':
        return '解决方案';
      default:
        return projectCategoryLabel(value, fallback: '研发');
    }
  }

  String _formatBudget(num? value) {
    if (value == null) return '--';
    final amount = value.toInt().toString();
    final chars = amount.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  String _buildProjectCode(String seed) {
    final normalized = seed.trim().isEmpty ? 'KAIZO' : seed.trim();
    final hash = normalized.hashCode.abs().toString();
    final suffix = hash.padLeft(4, '0').substring(0, 4);
    return 'KZ-$suffix';
  }

  String _estimateCycle(num? min, num? max) {
    final minValue = min?.toDouble() ?? 1000;
    final maxValue = max?.toDouble() ?? 5000;
    final midpoint = (minValue + maxValue) / 2;
    if (midpoint < 5000) return '7 天上线首版';
    if (midpoint < 15000) return '14 天推进主版本';
    if (midpoint < 30000) return '21 天完成核心功能';
    return '28 天进入交付节奏';
  }

  Future<void> _goToProjectDetail(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(onboardingProvider).draft;
    final projectId = draft['project_uuid'] as String?;
    await ref.read(onboardingProvider.notifier).complete();
    if (context.mounted) {
      if (projectId != null && projectId.isNotEmpty) {
        context.go(
          RoutePaths.projectDetail.replaceFirst(':projectId', projectId),
        );
        return;
      }
      context.go(RoutePaths.home);
    }
  }

  Future<void> _goHome(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).complete();
    if (context.mounted) {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final draft = state.draft;

    final title = (draft['project_title'] as String?)?.trim().isNotEmpty == true
        ? draft['project_title'] as String
        : '需求已准备好，等待你推进下一步';
    final category = _displayCategoryLabel(
      draft['category_label'] as String? ?? draft['category'] as String?,
    );
    final budgetMin = draft['budget_min'] as num?;
    final budgetMax = draft['budget_max'] as num?;
    final projectId = draft['project_uuid'] as String?;
    final budgetText =
        '¥${_formatBudget(budgetMin)} - ¥${_formatBudget(budgetMax)} / 项目';

    return OnboardingScaffold(
      currentStep: 3,
      onBack: () async {
        await ref.read(onboardingProvider.notifier).goToStep(2);
        if (context.mounted) {
          context.go(RoutePaths.demanderOnboarding3);
        }
      },
      primaryActionText: '进入项目详情',
      onPrimaryAction: () => _goToProjectDetail(context, ref),
      secondaryActionText: '去首页',
      onSecondaryAction: () => _goHome(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 26),
          const Text('项目已发布', style: AppTextStyles.onboardingTitle),
          const SizedBox(height: 10),
          const Text(
            '你的项目已进入 Kaizo 团队网络，我们正在为你匹配合适的协作团队。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 22),
          _RequirementSummaryCard(
            projectCode: _buildProjectCode(projectId ?? title),
            title: title,
            category: category,
            budgetText: budgetText,
            cycleText: _estimateCycle(budgetMin, budgetMax),
          ),
          const SizedBox(height: 18),
          const OnboardingInfoBlock(
            icon: Icons.forum_outlined,
            title: '即时沟通',
            description: '匹配成功后，你可以直接在对话里沟通目标、节奏与交付方式。',
          ),
          const SizedBox(height: 12),
          const OnboardingInfoBlock(
            icon: Icons.verified_user_outlined,
            title: '平台担保',
            description: '所有合作都以 Kaizo 协作标准为基础，确保交付过程清晰可信。',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RequirementSummaryCard extends StatelessWidget {
  final String projectCode;
  final String title;
  final String category;
  final String budgetText;
  final String cycleText;

  const _RequirementSummaryCard({
    required this.projectCode,
    required this.title,
    required this.category,
    required this.budgetText,
    required this.cycleText,
  });

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
                'REQUIREMENT ID · $projectCode',
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.onboardingPrimary,
                ),
              ),
              const Spacer(),
              const OnboardingStatusBadge(text: '团队匹配中', animate: true),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.h2.copyWith(fontSize: 23)),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaLine(icon: Icons.sell_outlined, text: category),
              const SizedBox(width: 16),
              Expanded(
                child: _MetaLine(
                  icon: Icons.payments_outlined,
                  text: budgetText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetaLine(icon: Icons.schedule_outlined, text: cycleText),
          const SizedBox(height: 18),
          OnboardingSectionHeader(
            title: '团队候选队列 (2)',
            accessory: Text(
              '实时更新中',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onboardingMutedText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _QueuePlaceholder(),
          const SizedBox(height: 10),
          const _QueuePlaceholder(),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _QueuePlaceholder extends StatelessWidget {
  const _QueuePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.onboardingSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingSkeletonBlock(
                  width: 120,
                  height: 8,
                  color: AppColors.gray200,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    OnboardingSkeletonBlock(
                      width: 72,
                      height: 8,
                      color: AppColors.gray100,
                    ),
                    SizedBox(width: 10),
                    OnboardingSkeletonBlock(
                      width: 42,
                      height: 8,
                      color: AppColors.onboardingSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
