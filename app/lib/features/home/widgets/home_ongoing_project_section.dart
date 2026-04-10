import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/project_model.dart';
import '../../project/widgets/progress_ring.dart';
import 'home_section_header.dart';

class HomeOngoingProjectSection extends StatelessWidget {
  final List<ProjectModel> projects;

  const HomeOngoingProjectSection({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final visibleProjects = projects.take(3).toList();
    final previewProjects = visibleProjects.isEmpty && kDebugMode
        ? [_debugPreviewProject]
        : visibleProjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '在途项目',
          subtitle: '已对接，正在推进。',
          actionLabel: '全部项目',
          onAction: () => context.go(RoutePaths.projectList),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: previewProjects.isEmpty
              ? const _EmptyOngoingProjectCard()
              : Column(
                  children: [
                    _FeaturedOngoingProjectCard(project: previewProjects.first),
                    if (previewProjects.length > 1) const SizedBox(height: 12),
                    for (var index = 1;
                        index < previewProjects.length;
                        index++) ...[
                      _CompactOngoingProjectRow(
                        project: previewProjects[index],
                      ),
                      if (index != previewProjects.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _EmptyOngoingProjectCard extends StatelessWidget {
  const _EmptyOngoingProjectCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: () => context.push(RoutePaths.publishProject),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StageBadge(label: '协作阶段'),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '已对接的项目会出现在这里',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '当项目进入已匹配、进行中或验收中，这里会显示当前进度。',
                      style: AppTextStyles.body2.copyWith(
                        height: 1.45,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.north_east_rounded,
                  size: 18,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedOngoingProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _FeaturedOngoingProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final route = _projectRoute(project);

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        onTap: route == null ? null : () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StageBadge(label: _stageLabel(project)),
                        _MetaChip(label: project.categoryName),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ProgressRing(
                    progress: project.progress,
                    size: 64,
                    strokeWidth: 5,
                    trackColor: AppColors.gray100,
                    progressColor: AppColors.black,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 20,
                  height: 1.18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _stageDescription(project),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetaLine(
                      icon: Icons.payments_outlined,
                      label: _priceLabel(project),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetaLine(
                      icon: Icons.handshake_outlined,
                      label: _matchLabel(project),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: project.progress / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.gray100,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOngoingProjectRow extends StatelessWidget {
  final ProjectModel project;

  const _CompactOngoingProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final route = _projectRoute(project);

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: route == null ? null : () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              ProgressRing(
                progress: project.progress,
                size: 46,
                strokeWidth: 4,
                trackColor: AppColors.gray100,
                progressColor: AppColors.black,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_stageLabel(project)} · ${project.categoryName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _priceLabel(project),
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;

  const _StageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

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
          color: AppColors.gray700,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaLine({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.gray500),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
      ],
    );
  }
}

String? _projectRoute(ProjectModel project) {
  final routeId = project.uuid.isNotEmpty ? project.uuid : project.id;
  if (routeId.isEmpty) return null;
  if (project.status == 5 && project.id.isNotEmpty) {
    return '/projects/${project.id}/manage';
  }
  return '/projects/$routeId';
}

String _stageLabel(ProjectModel project) {
  switch (project.status) {
    case 4:
      return '已对接';
    case 5:
      return '进行中';
    case 6:
      return '验收中';
    default:
      return project.statusName;
  }
}

String _stageDescription(ProjectModel project) {
  switch (project.status) {
    case 4:
      return '已确认团队，准备进入交付';
    case 5:
      return '项目已进入制作阶段';
    case 6:
      return '交付完成，等待你确认验收';
    default:
      return '项目正在推进中';
  }
}

String _matchLabel(ProjectModel project) {
  if (project.status == 6) return '等待你验收';
  if (project.status == 4) return '团队已进场';
  return '协作推进中';
}

String _priceLabel(ProjectModel project) {
  if (project.agreedPrice != null) {
    return '成交 ${project.budgetDisplay}';
  }
  return project.budgetDisplay;
}

final _debugPreviewProject = ProjectModel(
  id: '',
  uuid: '',
  ownerId: 'preview_owner',
  providerId: 'preview_provider',
  teamId: null,
  title: 'AI 招聘助手小程序',
  description: '已完成项目对接，当前进入核心流程开发。',
  category: 'dev',
  budgetMin: 5000,
  budgetMax: 8000,
  agreedPrice: 6800,
  complexity: 'medium',
  progress: 63,
  status: 5,
  matchMode: 1,
  viewCount: 0,
  bidCount: 0,
  techRequirements: const ['小程序', 'AI 工作流'],
  publishedAt: DateTime(2026, 3, 24),
  createdAt: DateTime(2026, 3, 21),
);
