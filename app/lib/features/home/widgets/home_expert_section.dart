import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
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
          title: '推荐专家',
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
        onTap: expert.id.isEmpty ? null : () => context.push('/expert/${expert.id}'),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
        borderRadius: 18,
        backgroundColor: AppColors.white,
        border: Border.all(
          color: AppColors.gray200.withValues(alpha: 0.7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 17, 17, 0.05),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VccAvatar(
                  imageUrl: expert.avatarUrl,
                  size: VccAvatarSize.large,
                  fallbackText: expert.nickname,
                ),
                const Spacer(),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
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
              expert.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            _SkillTag(label: _primarySkill(expert)),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: AppColors.accentGold,
                ),
                const SizedBox(width: 4),
                Text(
                  expert.rating > 0 ? expert.rating.toStringAsFixed(1) : '暂无评分',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _experienceText(expert),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _rateText(expert),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
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
  if (expert.completedOrders > 0) return '${expert.completedOrders} 个项目';
  return '可先沟通';
}
