import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/home_models.dart';
import 'home_section_header.dart';

class ExpertHomeDemands extends StatelessWidget {
  final List<RecommendedDemand> demands;

  const ExpertHomeDemands({super.key, required this.demands});

  @override
  Widget build(BuildContext context) {
    final visibleDemands = demands.take(3).toList();
    if (visibleDemands.isEmpty) return const SizedBox.shrink();

    final featuredDemand = visibleDemands.first;
    final supportingDemands = visibleDemands.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '匹配中的项目',
          subtitle: '按你的技能与近期活跃度排序。',
          actionLabel: '需求广场',
          onAction: () => context.go(RoutePaths.square),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _FeaturedDemandCard(demand: featuredDemand),
              if (supportingDemands.isNotEmpty) const SizedBox(height: 12),
              for (var index = 0;
                  index < supportingDemands.length;
                  index++) ...[
                _DemandRow(demand: supportingDemands[index]),
                if (index != supportingDemands.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedDemandCard extends StatelessWidget {
  final RecommendedDemand demand;

  const _FeaturedDemandCard({required this.demand});

  @override
  Widget build(BuildContext context) {
    final projectRoute = _projectRoute(demand);
    final chips = _demandChips(demand);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: projectRoute == null ? null : () => context.push(projectRoute),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DemandBadge(label: '匹配 ${demand.matchScore}%'),
                  const Spacer(),
                  Text(
                    demand.budgetDisplay,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                demand.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h2.copyWith(
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                demand.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(
                  height: 1.5,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chip in chips) _DemandMetaChip(label: chip),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemandRow extends StatelessWidget {
  final RecommendedDemand demand;

  const _DemandRow({required this.demand});

  @override
  Widget build(BuildContext context) {
    final projectRoute = _projectRoute(demand);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: projectRoute == null ? null : () => context.push(projectRoute),
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
                      demand.title,
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
                      _supportingSubtitle(demand),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _DemandBadge(label: '匹配 ${demand.matchScore}%'),
                  const SizedBox(height: 8),
                  Text(
                    demand.budgetDisplay,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemandBadge extends StatelessWidget {
  final String label;

  const _DemandBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _DemandMetaChip extends StatelessWidget {
  final String label;

  const _DemandMetaChip({required this.label});

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

List<String> _demandChips(RecommendedDemand demand) {
  final chips = demand.techRequirements
      .where((item) => item.trim().isNotEmpty)
      .take(3)
      .toList();
  if (chips.isEmpty) {
    chips.add('继续查看详情');
  }
  return chips;
}

String _supportingSubtitle(RecommendedDemand demand) {
  final skills = demand.techRequirements
      .where((item) => item.trim().isNotEmpty)
      .take(2)
      .join(' · ');
  if (skills.isNotEmpty) return skills;
  if (demand.description.trim().isNotEmpty) return demand.description.trim();
  return '进入项目详情继续查看';
}

String? _projectRoute(RecommendedDemand demand) {
  final id = demand.routingId;
  if (id.isEmpty) return null;
  return RoutePaths.projectDetail.replaceFirst(':projectId', id);
}
