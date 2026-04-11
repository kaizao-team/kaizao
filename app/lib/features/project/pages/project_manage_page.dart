import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/project_models.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_manage_provider.dart';
import '../widgets/progress_ring.dart';
import '../widgets/kanban_board.dart';
import '../widgets/milestone_timeline.dart';
import '../widgets/project_tab_bar.dart';

class ProjectManagePage extends ConsumerWidget {
  final String projectId;
  final String? projectTitle;

  const ProjectManagePage({
    super.key,
    required this.projectId,
    this.projectTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectManageProvider(projectId));
    final detailState = ref.watch(projectDetailProvider(projectId));
    final displayTitle = detailState.title.isNotEmpty
        ? detailState.title
        : (projectTitle ?? '项目管理');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        title: Text(
          displayTitle,
          style: AppTextStyles.h3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            onPressed: () => context.push('/projects/$projectId/prd'),
            tooltip: '需求文档',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              ),
            )
          : state.errorMessage != null
              ? _buildError(context, ref, state.errorMessage!)
              : Column(
                  children: [
                    _OverviewBar(
                      progress: state.totalProgress,
                      completedCount: state.completedTasks.length,
                      totalCount: state.tasks.length,
                      milestoneTotal: state.milestones.length,
                      milestoneCompleted: state.milestones
                          .where((m) => m.isCompleted)
                          .length,
                    ),
                    ProjectTabBar(
                      selected: state.currentTab,
                      onChanged: (tab) => ref
                          .read(projectManageProvider(projectId).notifier)
                          .switchTab(tab),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildTabContent(context, ref, state),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabContent(
      BuildContext context, WidgetRef ref, ProjectManageState state) {
    final authState = ref.watch(authStateProvider);
    final isTeamMember = authState.userRole == 2;

    switch (state.currentTab) {
      case ProjectTab.tasks:
        return KanbanBoard(
          key: const ValueKey('tasks'),
          todoTasks: state.todoTasks,
          inProgressTasks: state.inProgressTasks,
          completedTasks: state.completedTasks,
          readOnly: !isTeamMember,
          onMoveTask: (taskId, newStatus) {
            ref
                .read(projectManageProvider(projectId).notifier)
                .moveTask(taskId, newStatus);
            if (newStatus == 'completed') {
              VccToast.show(context,
                  message: '任务已完成', type: VccToastType.success);
            }
          },
        );
      case ProjectTab.milestones:
        return MilestoneTimeline(
          key: const ValueKey('milestones'),
          milestones: state.milestones,
          isTeamMember: isTeamMember,
          onMilestoneAction: (milestoneId, action,
              {String? note, String? previewUrl, String? reason}) {
            final notifier =
                ref.read(projectManageProvider(projectId).notifier);
            switch (action) {
              case 'deliver':
                notifier.deliverMilestone(milestoneId,
                    note: note, previewUrl: previewUrl);
              case 'accept':
                notifier.acceptMilestone(milestoneId);
              case 'revision':
                notifier.requestRevision(milestoneId, reason: reason);
            }
          },
        );
      case ProjectTab.files:
        return _FilesTab(
          key: const ValueKey('files'),
          projectId: projectId,
          state: state,
          ref: ref,
        );
    }
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.gray400),
          const SizedBox(height: 16),
          Text('加载失败',
              style: AppTextStyles.body1
                  .copyWith(fontWeight: FontWeight.w500, color: AppColors.gray600)),
          const SizedBox(height: 8),
          Text(message,
              style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () =>
                ref.read(projectManageProvider(projectId).notifier).loadAll(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('重试',
                  style: AppTextStyles.body2.copyWith(color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Bar
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewBar extends StatelessWidget {
  final int progress;
  final int completedCount;
  final int totalCount;
  final int milestoneTotal;
  final int milestoneCompleted;

  const _OverviewBar({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.milestoneTotal,
    required this.milestoneCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.base),
      color: AppColors.surfaceRaised,
      child: Row(
        children: [
          ProgressRing(progress: progress, size: 56, strokeWidth: 5),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    value: '$progress%',
                    label: '整体进度',
                  ),
                ),
                Container(width: 0.5, height: 32, color: AppColors.gray200),
                Expanded(
                  child: _StatColumn(
                    value: totalCount > 0 ? '$completedCount/$totalCount' : '—',
                    label: '任务完成',
                  ),
                ),
                Container(width: 0.5, height: 32, color: AppColors.gray200),
                Expanded(
                  child: _StatColumn(
                    value: milestoneTotal > 0
                        ? '$milestoneCompleted/$milestoneTotal'
                        : '—',
                    label: '里程碑',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.overline.copyWith(color: AppColors.gray400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Files Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FilesTab extends StatelessWidget {
  final String projectId;
  final ProjectManageState state;
  final WidgetRef ref;

  const _FilesTab({
    super.key,
    required this.projectId,
    required this.state,
    required this.ref,
  });

  static const _kinds = [
    ('reference', '参考文件'),
    ('process', '过程文件'),
    ('deliverable', '交付文件'),
  ];

  IconData _fileIcon(String contentType) {
    if (contentType.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (contentType.contains('image')) return Icons.image_outlined;
    if (contentType.contains('word') || contentType.contains('document')) {
      return Icons.article_outlined;
    }
    if (contentType.contains('spreadsheet') || contentType.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    if (contentType.contains('zip') || contentType.contains('compressed')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(projectManageProvider(projectId).notifier);
    final filteredFiles = state.filteredFiles;

    return Column(
      children: [
        // Kind filter chips
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.gray200, width: 0.5)),
          ),
          child: Row(
            children: _kinds.map((kind) {
              final isSelected = state.selectedFileKind == kind.$1;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => notifier.setFileKind(kind.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.black
                            : AppColors.gray300,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      kind.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? AppColors.white : AppColors.gray600,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // File list
        Expanded(
          child: filteredFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_outlined,
                          size: 48, color: AppColors.gray300),
                      const SizedBox(height: 12),
                      Text(
                        '暂无文件',
                        style: AppTextStyles.body2
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filteredFiles.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    return GestureDetector(
                      onTap: () async {
                        try {
                          final url = await ref
                              .read(
                                  projectManageProvider(projectId).notifier)
                              .fetchDownloadUrl(file.uuid);
                          if (context.mounted) {
                            VccToast.show(context,
                                message: '下载链接：$url',
                                type: VccToastType.info);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            VccToast.show(context,
                                message: '获取下载链接失败',
                                type: VccToastType.error);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.gray200, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(_fileIcon(file.contentType),
                                size: 28, color: AppColors.gray400),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.originalName,
                                    style: AppTextStyles.body2.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${file.displaySize}  ·  ${file.uploadedByNickname ?? '未知'}  ·  ${file.createdAt.toString().substring(0, 10)}',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.gray400),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.download_outlined,
                                size: 18, color: AppColors.gray400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
