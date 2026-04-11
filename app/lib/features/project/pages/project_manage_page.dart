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
          onTap: (_) {},
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

  const _OverviewBar({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.base),
      color: AppColors.surfaceRaised,
      child: Row(
        children: [
          ProgressRing(progress: progress, size: 52, strokeWidth: 5),
          const SizedBox(width: AppSpacing.base),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$progress%',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                totalCount > 0
                    ? '$completedCount/$totalCount 任务完成'
                    : '暂无任务',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Files Tab (placeholder — implemented in Step 5)
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_outlined, size: 48, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text('文件管理即将上线',
              style: AppTextStyles.body2.copyWith(color: AppColors.gray500)),
        ],
      ),
    );
  }
}
