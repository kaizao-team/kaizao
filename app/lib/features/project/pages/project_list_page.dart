import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_card.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  static const _projects = [
    {
      'id': '1',
      'title': '智能客服系统',
      'status': 5,
      'statusName': '进行中',
      'progress': 68,
      'budget': '¥3,000-8,000',
      'hasRisk': true,
    },
    {
      'id': '2',
      'title': '企业官网改版',
      'status': 5,
      'statusName': '进行中',
      'progress': 30,
      'budget': '¥2,000-5,000',
      'hasRisk': false,
    },
    {
      'id': '3',
      'title': 'AI写作助手',
      'status': 2,
      'statusName': '已发布',
      'progress': 0,
      'budget': '¥5,000-10,000',
      'hasRisk': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('我的项目',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => context.push('/publish'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final proj = _projects[index];
          final hasRisk = proj['hasRisk'] as bool;
          final progress = proj['progress'] as int;
          final status = proj['status'] as int;

          return VccCard(
            onTap: () {
              if (status == 5) {
                context.push('/projects/${proj['id']}/manage');
              } else {
                context.push('/projects/${proj['id']}');
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        proj['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusBgColor(status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        proj['statusName'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(proj['budget'] as String,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.gray600)),
                    const Spacer(),
                    if (hasRisk)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 12, color: AppColors.error),
                            SizedBox(width: 2),
                            Text('有风险',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: AppColors.gray200,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    AppColors.accent),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$progress%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600)),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 2:
        return AppColors.accent;
      case 5:
        return AppColors.success;
      case 7:
        return AppColors.gray500;
      default:
        return AppColors.gray500;
    }
  }

  Color _statusBgColor(int status) {
    switch (status) {
      case 2:
        return AppColors.accentLight;
      case 5:
        return AppColors.successBg;
      case 7:
        return AppColors.gray100;
      default:
        return AppColors.gray100;
    }
  }
}
