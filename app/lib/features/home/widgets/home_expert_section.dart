import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../models/home_models.dart';
import 'home_section_header.dart';

class HomeExpertSection extends StatelessWidget {
  final List<RecommendedExpert> experts;
  final VoidCallback onViewMore;

  const HomeExpertSection({
    super.key,
    required this.experts,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    if (experts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '推荐团队',
          subtitle: '先看擅长方向与时薪，合适就继续沟通。',
          actionLabel: '查看更多',
          onAction: onViewMore,
        ),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: experts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _ExpertCard(expert: experts[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _ExpertCard extends StatelessWidget {
  final RecommendedExpert expert;

  const _ExpertCard({required this.expert});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 216,
      child: VccCard(
        onTap: expert.id.isEmpty ? null : () => context.push('/team/${expert.id}/profile'),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
        borderRadius: AppRadius.lg,
        backgroundColor: AppColors.surfaceRaised,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VccAvatar(
                  imageUrl: expert.avatarUrl,
                  size: VccAvatarSize.large,
                  fallbackText: expert.displayName,
                ),
                const Spacer(),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              expert.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _SkillTag(label: _primarySkill(expert)),
            const Spacer(),
            Row(
              children: [
                if (expert.vibeLevel != null &&
                    expert.vibeLevel!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onSurface,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      expert.vibeLevel!,
                      style: AppTextStyles.overline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expert.rating > 0 ? expert.rating.toStringAsFixed(1) : '-',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _experienceText(expert),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _rateText(expert),
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;

  const _SkillTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.gray700,
        ),
      ),
    );
  }
}

String _primarySkill(RecommendedExpert expert) {
  final value = expert.skill.trim();
  if (value.isNotEmpty) return value;
  return '综合交付';
}

String _rateText(RecommendedExpert expert) {
  if (expert.hourlyRate > 0) return '¥${expert.hourlyRate}/h';
  return '时薪面议';
}

String _experienceText(RecommendedExpert expert) {
  final parts = <String>[];
  if (expert.completedOrders > 0) parts.add('${expert.completedOrders} 个项目');
  if (expert.memberCount > 1) parts.add('${expert.memberCount}人团队');
  if (parts.isEmpty) return '可先沟通';
  return parts.join(' · ');
}
