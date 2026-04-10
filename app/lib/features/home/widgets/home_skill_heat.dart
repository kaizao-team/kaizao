import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/home_models.dart';
import 'home_section_header.dart';

class HomeSkillHeat extends StatelessWidget {
  final List<SkillHeatItem> skills;

  const HomeSkillHeat({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();

    final rankedSkills = skills.toList()
      ..sort((left, right) => right.heat.compareTo(left.heat));
    final visibleSkills = rankedSkills.take(5).toList();
    final headlineSkill = visibleSkills.first;
    final maxHeat =
        visibleSkills.fold<int>(1, (m, s) => s.heat > m ? s.heat : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: '技能热度',
          subtitle: '近期在平台上被频繁点名的方向。',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '当前最高需求',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            headlineSkill.name,
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${headlineSkill.heat} 热度',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (var index = 0; index < visibleSkills.length; index++) ...[
                  _SkillHeatRow(
                    rank: index + 1,
                    skill: visibleSkills[index],
                    maxHeat: maxHeat,
                  ),
                  if (index != visibleSkills.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillHeatRow extends StatelessWidget {
  final int rank;
  final SkillHeatItem skill;
  final int maxHeat;

  const _SkillHeatRow({
    required this.rank,
    required this.skill,
    required this.maxHeat,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = skill.heat / maxHeat;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: rank == 1 ? AppColors.black : AppColors.gray100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: rank == 1 ? AppColors.white : AppColors.gray700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${skill.heat}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.gray100,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.black),
                    minHeight: 7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
