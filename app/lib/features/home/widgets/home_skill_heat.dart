import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/home_models.dart';

class HomeSkillHeat extends StatelessWidget {
  final List<SkillHeatItem> skills;

  const HomeSkillHeat({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();

    final maxHeat = skills.fold<int>(1, (m, s) => s.heat > m ? s.heat : m);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '技能热度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...skills.map((skill) => _SkillHeatRow(
                skill: skill,
                maxHeat: maxHeat,
              )),
        ],
      ),
    );
  }
}

class _SkillHeatRow extends StatelessWidget {
  final SkillHeatItem skill;
  final int maxHeat;

  const _SkillHeatRow({required this.skill, required this.maxHeat});

  @override
  Widget build(BuildContext context) {
    final fraction = skill.heat / maxHeat;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              skill.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.gray100,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.black),
                  minHeight: 6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '${skill.heat}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
