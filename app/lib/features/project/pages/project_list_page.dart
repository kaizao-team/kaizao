import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/widgets/vcc_editorial_app_bar.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../../shared/widgets/vcc_filter_chip_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/project_list_provider.dart';

enum _ProjectDeskFilter { all, recruiting, active, review, atRisk, done }

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});

  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage> {
  _ProjectDeskFilter _selectedFilter = _ProjectDeskFilter.all;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final listState = ref.watch(projectListProvider);
    final isDemander = authState.userRole != 2;
    final projects = listState.projects;
    final filterOptions = _buildFilterOptions(projects, isDemander);
    final effectiveFilter = filterOptions.any(
      (option) => option.filter == _selectedFilter,
    )
        ? _selectedFilter
        : _ProjectDeskFilter.all;
    final visibleProjects = _applyFilter(projects, effectiveFilter);
    final focusProject =
        visibleProjects.isEmpty ? null : _pickFocusProject(visibleProjects);
    final groupedProjects = _buildSections(
      visibleProjects
          .where((project) => project.routingId != focusProject?.routingId)
          .toList(),
      effectiveFilter,
    );

    final headerTrailing = projects.isNotEmpty || isDemander
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (projects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${projects.length} 个项目',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              if (isDemander) ...[
                if (projects.isNotEmpty) const SizedBox(width: 8),
                _ProjectHeaderAction(
                  onPressed: () => context.push(RoutePaths.publishProject),
                ),
              ],
            ],
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: () => ref.read(projectListProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            VccEditorialAppBar(
              title: '我的项目',
              subtitle: isDemander
                  ? '按状态管理招募、推进、验收与争议处理'
                  : '按阶段查看交付、验收、争议与结项',
              trailing: headerTrailing,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProjectFilterHeaderDelegate(
                filterOptions: filterOptions,
                selected: effectiveFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            ),
            if (listState.isLoading && projects.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.black),
                    ),
                  ),
                ),
              )
            else if (listState.errorMessage != null && projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: VccEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: '加载失败',
                  subtitle: listState.errorMessage,
                  buttonText: '重试',
                  onButtonPressed: () =>
                      ref.read(projectListProvider.notifier).refresh(),
                ),
              )
            else if (projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: VccEmptyState(
                  icon: isDemander
                      ? Icons.description_outlined
                      : Icons.explore_outlined,
                  title: '还没有项目',
                  subtitle: isDemander ? '创建你的第一个项目' : '去广场看看可接项目',
                  buttonText: isDemander ? '创建项目' : '去广场',
                  onButtonPressed: () => isDemander
                      ? context.push(RoutePaths.publishProject)
                      : context.go(RoutePaths.square),
                ),
              )
            else ...[
              if (focusProject != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                    child: _SectionIntro(
                      title: '优先处理',
                      count: 1,
                      note: isDemander ? '当前最值得先看的一单' : '当前最该先推进的项目',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _FocusProjectCard(
                      project: focusProject,
                      isDemander: isDemander,
                      onTap: () => _openProject(context, focusProject),
                    ),
                  ),
                ),
              ],
              if (visibleProjects.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: VccEmptyState(
                    icon: Icons.tune_outlined,
                    title: '当前筛选下没有项目',
                    subtitle: '换一个状态看看。',
                  ),
                )
              else
                ...groupedProjects.map(
                  (section) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: _ProjectSection(
                        title: section.title,
                        subtitle: section.subtitle,
                        projects: section.projects,
                        isDemander: isDemander,
                        onTapProject: (project) =>
                            _openProject(context, project),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ],
        ),
      ),
    );
  }

  void _openProject(BuildContext context, ProjectModel project) {
    if (project.status == 5) {
      context.push('/projects/${project.routingId}/manage');
      return;
    }
    context.push('/projects/${project.routingId}');
  }
}

class _ProjectHeaderAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _ProjectHeaderAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: AppColors.gray50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: const BorderSide(color: AppColors.gray200),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 16),
          SizedBox(width: 4),
          Text(
            '新建',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<_FilterOption> filterOptions;
  final _ProjectDeskFilter selected;
  final ValueChanged<_ProjectDeskFilter> onFilterChanged;

  const _ProjectFilterHeaderDelegate({
    required this.filterOptions,
    required this.selected,
    required this.onFilterChanged,
  });

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final chipOptions = filterOptions
        .map(
          (option) => VccFilterChipOption<_ProjectDeskFilter>(
            value: option.filter,
            label: option.label,
          ),
        )
        .toList(growable: false);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.gray100, width: 0.5),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: VccFilterChipBar<_ProjectDeskFilter>(
          options: chipOptions,
          selectedValue: selected,
          onSelected: onFilterChanged,
          height: 40,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProjectFilterHeaderDelegate oldDelegate) {
    return filterOptions != oldDelegate.filterOptions ||
        selected != oldDelegate.selected ||
        onFilterChanged != oldDelegate.onFilterChanged;
  }
}

class _FilterOption {
  final _ProjectDeskFilter filter;
  final String label;
  final int count;

  const _FilterOption({
    required this.filter,
    required this.label,
    required this.count,
  });
}

class _SectionIntro extends StatelessWidget {
  final String title;
  final int? count;
  final String? note;

  const _SectionIntro({
    required this.title,
    this.count,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final suffix = count != null ? ' · $count' : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$title$suffix',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray400,
            letterSpacing: 1.8,
          ),
        ),
        if (note != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FocusProjectCard extends StatelessWidget {
  final ProjectModel project;
  final bool isDemander;
  final VoidCallback onTap;

  const _FocusProjectCard({
    required this.project,
    required this.isDemander,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ProjectRowCard(
      project: project,
      isDemander: isDemander,
      onTap: onTap,
      highlighted: true,
    );
  }
}

class _ProjectGlyph extends StatelessWidget {
  final ProjectModel project;
  final bool highlighted;

  const _ProjectGlyph({
    required this.project,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(project.status);
    final size = highlighted ? 42.0 : 36.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlighted ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(highlighted ? 14 : 12),
      ),
      child: Icon(
        _iconForProject(project),
        size: highlighted ? 20 : 18,
        color: color,
      ),
    );
  }
}

IconData _iconForProject(ProjectModel project) {
  switch (_filterForProject(project)) {
    case _ProjectDeskFilter.recruiting:
      return Icons.campaign_outlined;
    case _ProjectDeskFilter.active:
      return Icons.play_circle_outline_rounded;
    case _ProjectDeskFilter.review:
      return Icons.task_alt_rounded;
    case _ProjectDeskFilter.atRisk:
      return Icons.warning_amber_rounded;
    case _ProjectDeskFilter.done:
      return Icons.check_circle_outline_rounded;
    case _ProjectDeskFilter.all:
      return Icons.folder_open_rounded;
  }
}

class _ProjectSectionData {
  final String title;
  final String subtitle;
  final List<ProjectModel> projects;

  const _ProjectSectionData({
    required this.title,
    required this.subtitle,
    required this.projects,
  });
}

class _ProjectSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ProjectModel> projects;
  final bool isDemander;
  final ValueChanged<ProjectModel> onTapProject;

  const _ProjectSection({
    required this.title,
    required this.subtitle,
    required this.projects,
    required this.isDemander,
    required this.onTapProject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionIntro(
          title: title,
          count: projects.length,
          note: subtitle,
        ),
        const SizedBox(height: 12),
        Column(
          children: projects
              .map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProjectRowCard(
                    project: project,
                    isDemander: isDemander,
                    onTap: () => onTapProject(project),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ProjectRowCard extends StatelessWidget {
  final ProjectModel project;
  final bool isDemander;
  final VoidCallback onTap;
  final bool highlighted;

  const _ProjectRowCard({
    required this.project,
    required this.isDemander,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final metaText = _rowMetaText(project, isDemander);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(highlighted ? 24 : 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(highlighted ? 24 : 22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.surfaceRaised : AppColors.gray50,
            borderRadius: BorderRadius.circular(highlighted ? 24 : 22),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: highlighted ? AppShadows.shadow1 : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProjectGlyph(project: project, highlighted: highlighted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlighted) ...[
                      const Text(
                        '优先处理',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      project.title,
                      maxLines: highlighted ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: highlighted ? 16 : 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      metaText,
                      maxLines: highlighted ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: highlighted ? 96 : 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusBadge(project: project, compact: true),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        project.budgetDisplay,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: highlighted ? 17 : 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    if (highlighted) ...[
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        size: 14,
                        color: AppColors.gray500,
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
}

class _StatusBadge extends StatelessWidget {
  final ProjectModel project;
  final bool compact;

  const _StatusBadge({required this.project, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(project.status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        project.homeStatusName,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

List<_FilterOption> _buildFilterOptions(
  List<ProjectModel> projects,
  bool isDemander,
) {
  final baseOrder = isDemander
      ? const [
          _ProjectDeskFilter.all,
          _ProjectDeskFilter.recruiting,
          _ProjectDeskFilter.active,
          _ProjectDeskFilter.review,
          _ProjectDeskFilter.atRisk,
          _ProjectDeskFilter.done,
        ]
      : const [
          _ProjectDeskFilter.all,
          _ProjectDeskFilter.active,
          _ProjectDeskFilter.review,
          _ProjectDeskFilter.atRisk,
          _ProjectDeskFilter.done,
        ];

  return baseOrder
      .map(
        (filter) => _FilterOption(
          filter: filter,
          label: _filterLabel(filter),
          count: filter == _ProjectDeskFilter.all
              ? projects.length
              : _countForFilter(projects, filter),
        ),
      )
      .toList();
}

List<ProjectModel> _applyFilter(
  List<ProjectModel> projects,
  _ProjectDeskFilter filter,
) {
  if (filter == _ProjectDeskFilter.all) return projects;
  return projects
      .where((project) => _filterForProject(project) == filter)
      .toList();
}

ProjectModel _pickFocusProject(List<ProjectModel> projects) {
  final sorted = List<ProjectModel>.from(projects)
    ..sort((a, b) {
      final aScore = _focusPriority(a);
      final bScore = _focusPriority(b);
      if (aScore != bScore) return aScore.compareTo(bScore);
      return b.createdAt.compareTo(a.createdAt);
    });
  return sorted.first;
}

int _focusPriority(ProjectModel project) {
  switch (project.status) {
    case 6:
      return 0;
    case 5:
      return 1;
    case 4:
      return 2;
    case 2:
    case 3:
      return 3;
    case 7:
      return 4;
    default:
      return 5;
  }
}

List<_ProjectSectionData> _buildSections(
  List<ProjectModel> projects,
  _ProjectDeskFilter filter,
) {
  if (projects.isEmpty) return const [];

  if (filter != _ProjectDeskFilter.all) {
    return [
      _ProjectSectionData(
        title: _filterLabel(filter),
        subtitle: _filterSubtitle(filter, projects.length),
        projects: projects,
      ),
    ];
  }

  final sections = <_ProjectSectionData>[];
  const order = [
    _ProjectDeskFilter.active,
    _ProjectDeskFilter.review,
    _ProjectDeskFilter.atRisk,
    _ProjectDeskFilter.recruiting,
    _ProjectDeskFilter.done,
  ];

  for (final current in order) {
    final filtered = projects
        .where((project) => _filterForProject(project) == current)
        .toList();
    if (filtered.isEmpty) continue;

    sections.add(
      _ProjectSectionData(
        title: _filterLabel(current),
        subtitle: _filterSubtitle(current, filtered.length),
        projects: filtered,
      ),
    );
  }

  return sections;
}

int _countForFilter(List<ProjectModel> projects, _ProjectDeskFilter filter) {
  return projects
      .where((project) => _filterForProject(project) == filter)
      .length;
}

_ProjectDeskFilter _filterForProject(ProjectModel project) {
  switch (project.status) {
    case 1:
    case 2:
    case 3:
      return _ProjectDeskFilter.recruiting;
    case 4:
    case 5:
      return _ProjectDeskFilter.active;
    case 6:
      return _ProjectDeskFilter.review;
    case 9:
      return _ProjectDeskFilter.atRisk;
    case 7:
    case 8:
      return _ProjectDeskFilter.done;
    default:
      return _ProjectDeskFilter.active;
  }
}

String _filterLabel(_ProjectDeskFilter filter) {
  switch (filter) {
    case _ProjectDeskFilter.all:
      return '全部';
    case _ProjectDeskFilter.recruiting:
      return '招募中';
    case _ProjectDeskFilter.active:
      return '进行中';
    case _ProjectDeskFilter.review:
      return '待验收';
    case _ProjectDeskFilter.atRisk:
      return '争议中';
    case _ProjectDeskFilter.done:
      return '已完成';
  }
}

String _filterSubtitle(_ProjectDeskFilter filter, int count) {
  switch (filter) {
    case _ProjectDeskFilter.all:
      return '$count 个项目';
    case _ProjectDeskFilter.recruiting:
      return '还有 $count 个项目在等待合适匹配。';
    case _ProjectDeskFilter.active:
      return '当前正在推进的项目共有 $count 个。';
    case _ProjectDeskFilter.review:
      return '$count 个项目已经来到交付收口阶段。';
    case _ProjectDeskFilter.atRisk:
      return '$count 个项目存在争议或阻塞，建议优先跟进。';
    case _ProjectDeskFilter.done:
      return '$count 个项目已经完成，可以随时回看。';
  }
}

String _providerName(ProjectModel project) {
  if (project.providerName?.isNotEmpty ?? false) return project.providerName!;
  if (project.hasMatchedProvider) return '已匹配团队方';
  return '等待匹配';
}

String _rowMetaText(ProjectModel project, bool isDemander) {
  final parts = <String>[];

  if (isDemander) {
    if (_filterForProject(project) == _ProjectDeskFilter.recruiting) {
      parts.add('${project.bidCount} 投标');
      if (project.viewCount > 0) {
        parts.add('${project.viewCount} 浏览');
      }
    } else {
      parts.add(_providerName(project));
      if (project.progress > 0) {
        parts.add('${project.progress}% 进度');
      }
    }
  } else {
    parts.add(
      (project.ownerName?.isNotEmpty ?? false) ? project.ownerName! : '需求方',
    );
    if (project.progress > 0) {
      parts.add('${project.progress}% 进度');
    }
  }

  if (project.deadlineAt != null) {
    parts.add(_deadlineLabel(project));
  } else if (project.categoryName.isNotEmpty) {
    parts.add(project.categoryName);
  }

  return parts.join(' · ');
}

String _deadlineLabel(ProjectModel project) {
  final deadline = project.deadlineAt;
  if (deadline == null) return '未设置截止';

  final local = deadline.toLocal();
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfDeadline = DateTime(local.year, local.month, local.day);
  final days = startOfDeadline.difference(startOfToday).inDays;

  if (days == 0) return '今天截止';
  if (days == 1) return '明天截止';
  if (days > 1 && days <= 7) return '$days 天后截止';
  if (days < 0) return '已逾期 ${days.abs()} 天';
  return DateFormat('M月d日').format(local);
}

Color _statusColor(int status) {
  switch (status) {
    case 2:
    case 3:
      return AppColors.accent;
    case 4:
    case 5:
      return AppColors.info;
    case 6:
      return AppColors.warning;
    case 7:
      return AppColors.success;
    case 9:
      return AppColors.error;
    default:
      return AppColors.gray500;
  }
}
