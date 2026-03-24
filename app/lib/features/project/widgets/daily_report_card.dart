import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/project_models.dart';

class DailyReportCard extends StatelessWidget {
  final DailyReport report;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const DailyReportCard({
    super.key,
    required this.report,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 16, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI 日报',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black)),
                        Text(report.date,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.gray200),
                  const SizedBox(height: 12),
                  Text(
                    report.summary,
                    style: const TextStyle(
                        fontSize: 14, height: 1.6, color: AppColors.gray700),
                  ),
                  if (report.completedTasks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Section(
                      icon: Icons.check_circle_outline,
                      iconColor: AppColors.success,
                      title: '今日完成',
                      items: report.completedTasks,
                    ),
                  ],
                  if (report.inProgressTasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _Section(
                      icon: Icons.play_circle_outline,
                      iconColor: AppColors.accent,
                      title: '进行中',
                      items: report.inProgressTasks,
                    ),
                  ],
                  if (report.riskItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _Section(
                      icon: Icons.warning_amber_outlined,
                      iconColor: AppColors.error,
                      title: '风险项',
                      items: report.riskItems,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_forward_outlined,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '明日计划：${report.tomorrowPlan}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.gray600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700)),
          ],
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text('· $item',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray500)),
            )),
      ],
    );
  }
}
