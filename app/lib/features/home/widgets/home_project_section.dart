import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_card.dart';
import 'home_section_header.dart';

class HomeProjectSection extends StatelessWidget {
  final List<ProjectModel> projects;

  const HomeProjectSection({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final visibleProjects = projects.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '我的项目',
          subtitle: '项目状态、预算与关键节点都在这里。',
          actionLabel: '查看全部',
          onAction: () => context.go(RoutePaths.projectList),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: visibleProjects.isEmpty
              ? const _EmptyProjectCard()
              : SizedBox(
                  height: 248,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: visibleProjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 276,
                        child: _ProjectCard(project: visibleProjects[index]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final routeId = project.uuid.isNotEmpty ? project.uuid : project.id;

    return VccCard(
      onTap: routeId.isEmpty ? null : () => context.push('/projects/$routeId'),
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      boxShadow: AppShadows.shadow1,
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
                    fontSize: 17,
                    height: 1.28,
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
          Text(
            _statusSummary(project),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ProjectMetaChip(
                icon: Icons.payments_outlined,
                label: project.budgetDisplay,
              ),
              _ProjectMetaChip(
                icon: Icons.event_outlined,
                label: _deadlineLabel(project),
              ),
            ],
          ),
          const Spacer(),
          if (project.hasMatchedProvider)
            _MatchedProviderRow(project: project)
          else
            const _PendingProviderRow(),
        ],
      ),
    );
  }
}

class _MatchedProviderRow extends StatelessWidget {
  final ProjectModel project;

  const _MatchedProviderRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final providerName = project.providerName ?? '已匹配造物者';

    return Row(
      children: [
        VccAvatar(
          imageUrl: project.providerAvatarUrl,
          size: VccAvatarSize.small,
          fallbackText: providerName,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '造物者',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                providerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_outward_rounded,
          size: 18,
          color: AppColors.gray500,
        ),
      ],
    );
  }
}

class _PendingProviderRow extends StatelessWidget {
  const _PendingProviderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 16,
            color: AppColors.gray500,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '正在匹配合适的造物者',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectStatusTag extends StatelessWidget {
  final ProjectModel project;

  const _ProjectStatusTag({required this.project});

  @override
  Widget build(BuildContext context) {
    final textColor = _statusColor(project);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        project.homeStatusName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ProjectMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProjectMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gray500),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProjectCard extends StatelessWidget {
  const _EmptyProjectCard();

  @override
  Widget build(BuildContext context) {
    return VccCard(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      boxShadow: AppShadows.shadow1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 24,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '还没有任何项目',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '把你的想法告诉 AI，让我们帮你变成现实。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 20),
          VccButton(
            text: '发布第一个需求',
            isFullWidth: false,
            width: 180,
            onPressed: () => context.push(RoutePaths.publishProject),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ProjectModel project) {
  switch (project.homeStatusName) {
    case '招募中':
      return const Color(0xFF3B82F6);
    case '进行中':
      return const Color(0xFF22C55E);
    case '待验收':
      return const Color(0xFFF59E0B);
    case '已完成':
      return const Color(0xFF6B7280);
    default:
      return AppColors.gray500;
  }
}

String _statusSummary(ProjectModel project) {
  switch (project.homeStatusName) {
    case '招募中':
      return '需求已发布，正在等待合适的造物者响应。';
    case '进行中':
      return '项目已经启动，当前交付正在稳步推进。';
    case '待验收':
      return '核心交付已完成，等待你确认验收结果。';
    case '已完成':
      return '项目已经完成交付，可以回看结果与沉淀。';
    default:
      return project.description;
  }
}

String _deadlineLabel(ProjectModel project) {
  final deadline = project.deadlineAt;
  if (deadline == null) return '截止待定';
  return DateFormat('M月d日').format(deadline.toLocal());
}
