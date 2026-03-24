import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/profile_models.dart';

class ProfileStatsRow extends StatelessWidget {
  final UserStats stats;

  const ProfileStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(value: '${stats.completedProjects}', label: '完成项目'),
        _StatItem(value: '${stats.approvalRate}%', label: '好评率'),
        _StatItem(
          value: '${stats.avgDeliveryDays.toStringAsFixed(1)}天',
          label: '平均交付',
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray400),
        ),
      ],
    );
  }
}
