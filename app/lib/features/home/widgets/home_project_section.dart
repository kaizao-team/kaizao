import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/widgets/vcc_card.dart';

class HomeProjectSection extends StatelessWidget {
  final List<ProjectModel> projects;

  const HomeProjectSection({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '我的项目',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(RoutePaths.projectList),
                child: const Row(
                  children: [
                    Text(
                      '查看全部',
                      style: TextStyle(fontSize: 13, color: AppColors.gray400),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.gray400),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...projects.map(
          (p) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: VccProjectCard(
              title: p.title,
              description: p.description,
              amount: p.budgetDisplay,
              tags: p.techRequirements,
              footerInfo: '进度 ${p.progress}%',
              onTap: () => context.push('/projects/${p.id}'),
            ),
          ),
        ),
      ],
    );
  }
}
