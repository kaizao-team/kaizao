import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/home_models.dart';
import 'home_section_header.dart';

class ExpertHomeTeamOpportunities extends StatelessWidget {
  final List<TeamOpportunity> opportunities;
  final VoidCallback onOpenHall;

  const ExpertHomeTeamOpportunities({
    super.key,
    required this.opportunities,
    required this.onOpenHall,
  });

  @override
  Widget build(BuildContext context) {
    final visibleOpportunities = opportunities.take(3).toList();
    if (visibleOpportunities.isEmpty) return const SizedBox.shrink();

    final featured = visibleOpportunities.first;
    final supporting = visibleOpportunities.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '组队机会',
          subtitle: '适合你补位或联手拿下的项目。',
          actionLabel: '组队大厅',
          onAction: onOpenHall,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Column(
              children: [
                _FeaturedOpportunityCard(
                  opportunity: featured,
                  onTap: onOpenHall,
                ),
                if (supporting.isNotEmpty) const SizedBox(height: 12),
                for (var index = 0; index < supporting.length; index++) ...[
                  _OpportunityRow(
                    opportunity: supporting[index],
                    onTap: onOpenHall,
                  ),
                  if (index != supporting.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedOpportunityCard extends StatelessWidget {
  final TeamOpportunity opportunity;
  final VoidCallback onTap;

  const _FeaturedOpportunityCard({
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 82,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _OpportunityEyebrow(label: '优先', inverted: true),
                      const Spacer(),
                      Text(
                        opportunity.teamSizeDisplay,
                        style: AppTextStyles.overline.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          color: const Color.fromRGBO(255, 255, 255, 0.72),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Icon(
                        Icons.north_east_rounded,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              opportunity.projectTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h2.copyWith(
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _OpportunityMetaChip(
                            label: opportunity.budgetDisplay,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '当前在找 ${opportunity.neededRole}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OpportunityMetaChip(label: opportunity.neededRole),
                          _OpportunityMetaChip(
                            label: opportunity.teamSizeDisplay,
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 14),
                      Text(
                        '进入组队大厅查看完整团队信息',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityRow extends StatelessWidget {
  final TeamOpportunity opportunity;
  final VoidCallback onTap;

  const _OpportunityRow({
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.projectTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '需要 ${opportunity.neededRole}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OpportunityMetaChip(
                          label: opportunity.teamSizeDisplay,
                        ),
                        _OpportunityMetaChip(
                          label: opportunity.budgetDisplay,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunityEyebrow extends StatelessWidget {
  final String label;
  final bool inverted;

  const _OpportunityEyebrow({
    required this.label,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inverted
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          fontSize: 11,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w700,
          color: inverted ? AppColors.white : AppColors.gray700,
        ),
      ),
    );
  }
}

class _OpportunityMetaChip extends StatelessWidget {
  final String label;
  const _OpportunityMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: AppColors.gray700,
        ),
      ),
    );
  }
}
