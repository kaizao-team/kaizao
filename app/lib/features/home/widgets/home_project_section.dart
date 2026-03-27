import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/models/project_model.dart';
import 'home_section_header.dart';

class HomeProjectSection extends StatelessWidget {
  final List<ProjectModel> projects;

  const HomeProjectSection({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final visibleProjects = projects.take(3).toList();
    if (visibleProjects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '更多项目',
          subtitle: '其他项目与草稿。',
          actionLabel: '查看全部',
          onAction: () => context.go(RoutePaths.projectList),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                for (var index = 0;
                    index < visibleProjects.length;
                    index++) ...[
                  _ProjectRow(project: visibleProjects[index]),
                  if (index != visibleProjects.length - 1)
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

class _ProjectRow extends StatelessWidget {
  final ProjectModel project;

  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final routeId = project.uuid.isNotEmpty ? project.uuid : project.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
            routeId.isEmpty ? null : () => context.push('/projects/$routeId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            project.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ProjectStatusTag(project: project),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _ProjectMeta(
                          icon: Icons.payments_outlined,
                          label: project.budgetDisplay,
                        ),
                        _ProjectMeta(
                          icon: Icons.folder_open_outlined,
                          label: project.categoryName,
                        ),
                        _ProjectMeta(
                          icon: Icons.auto_graph_outlined,
                          label: '进度 ${project.progress}%',
                        ),
                      ],
                    ),
                    if (project.progress > 0) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: project.progress / 100,
                          backgroundColor: AppColors.gray200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _statusColor(project.status),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 2:
      case 3:
        return AppColors.info;
      case 5:
        return AppColors.success;
      case 6:
        return AppColors.warning;
      case 7:
        return AppColors.gray500;
      default:
        return AppColors.gray400;
    }
  }
}

class _ProjectStatusTag extends StatelessWidget {
  final ProjectModel project;

  const _ProjectStatusTag({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(project.status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        project.statusName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _textColor(project.status),
        ),
      ),
    );
  }

  Color _backgroundColor(int status) {
    switch (status) {
      case 2:
      case 3:
        return AppColors.infoBg;
      case 5:
        return AppColors.successBg;
      case 6:
        return AppColors.warningBg;
      case 7:
        return AppColors.gray200;
      default:
        return AppColors.gray100;
    }
  }

  Color _textColor(int status) {
    switch (status) {
      case 2:
      case 3:
        return AppColors.info;
      case 5:
        return AppColors.success;
      case 6:
        return AppColors.warning;
      case 7:
        return AppColors.gray700;
      default:
        return AppColors.gray600;
    }
  }
}

class _ProjectMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProjectMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.gray500),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray600),
        ),
      ],
    );
  }
}
