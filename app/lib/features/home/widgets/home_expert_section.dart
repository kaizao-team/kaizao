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
                  fallbackText: expert.displayName,
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
              expert.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            if (expert.skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: expert.skills
                    .take(2)
                    .map((label) => _SkillTag(label: label))
                    .toList(),
              ),
            ],
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
                      color: const Color(0xFF1A1C1C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      expert.vibeLevel!,
                      style: const TextStyle(
                        fontSize: 10,
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
                    style: const TextStyle(
                      fontSize: 13,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
            if (_rateText(expert) != null) ...[
              const SizedBox(height: 8),
              Text(
                _rateText(expert)!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
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

String? _rateText(RecommendedExpert expert) {
  if (expert.budgetMin > 0 && expert.budgetMax > 0) {
    return '¥${_formatWholeAmount(expert.budgetMin)}-${_formatWholeAmount(expert.budgetMax)}';
  }
  if (expert.budgetMin > 0) {
    return '¥${_formatWholeAmount(expert.budgetMin)}起';
  }
  if (expert.hourlyRate > 0) return '¥${expert.hourlyRate}/h';
  return null;
}

String _formatWholeAmount(double amount) {
  if (amount >= 10000) {
    final wan = amount / 10000;
    return wan == wan.truncateToDouble()
        ? '${wan.toInt()}w'
        : '${wan.toStringAsFixed(1)}w';
  }
  return amount.toStringAsFixed(0);
}

String _experienceText(RecommendedExpert expert) {
  final parts = <String>[];
  if (expert.completedOrders > 0) parts.add('${expert.completedOrders} 个项目');
  if (expert.memberCount > 1) parts.add('${expert.memberCount}人团队');
  if (parts.isEmpty) return '可先沟通';
  return parts.join(' · ');
}
