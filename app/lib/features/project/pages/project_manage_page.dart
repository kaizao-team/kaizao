import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/project_models.dart';
import '../providers/project_manage_provider.dart';
import '../widgets/progress_ring.dart';
import '../widgets/kanban_board.dart';
import '../widgets/milestone_timeline.dart';
import '../widgets/daily_report_card.dart';
import '../widgets/risk_badge.dart';
import '../widgets/project_tab_bar.dart';

class ProjectManagePage extends ConsumerStatefulWidget {
  final String projectId;
  final String? projectTitle;

  const ProjectManagePage({
    super.key,
    required this.projectId,
    this.projectTitle,
  });

  @override
  ConsumerState<ProjectManagePage> createState() => _ProjectManagePageState();
}

class _ProjectManagePageState extends ConsumerState<ProjectManagePage> {
  final Set<String> _expandedReports = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectManageProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(
          widget.projectTitle ?? '项目管理',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (state.hasRisks)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: RiskBadge(riskCount: state.riskCount),
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
              ? _buildError(state.errorMessage!)
              : Column(
                  children: [
                    _OverviewBar(progress: state.totalProgress),
                    ProjectTabBar(
                      selected: state.currentTab,
                      onChanged: (tab) => ref
                          .read(
                              projectManageProvider(widget.projectId).notifier)
                          .switchTab(tab),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildTabContent(state),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabContent(ProjectManageState state) {
    final authState = ref.watch(authStateProvider);
    final isDemander = authState.userRole != 2;

    switch (state.currentTab) {
      case ProjectTab.kanban:
        return KanbanBoard(
          key: const ValueKey('kanban'),
          todoTasks: state.todoTasks,
          inProgressTasks: state.inProgressTasks,
          completedTasks: state.completedTasks,
          readOnly: isDemander,
          onMoveTask: (taskId, newStatus) {
            ref
                .read(projectManageProvider(widget.projectId).notifier)
                .moveTask(taskId, newStatus);
            if (newStatus == 'completed') {
              VccToast.show(context,
                  message: '任务已完成', type: VccToastType.success);
            }
          },
        );
      case ProjectTab.milestone:
        return MilestoneTimeline(
          key: const ValueKey('milestone'),
          milestones: state.milestones,
          onTap: (_) {},
        );
      case ProjectTab.prd:
        return _PrdTab(
          key: const ValueKey('prd'),
          projectId: widget.projectId,
        );
      case ProjectTab.files:
        return const _FilesTab(key: ValueKey('files'));
      case ProjectTab.report:
        return _ReportTab(
          key: const ValueKey('report'),
          reports: state.reports,
          expandedReports: _expandedReports,
          onToggle: (id) {
            setState(() {
              if (_expandedReports.contains(id)) {
                _expandedReports.remove(id);
              } else {
                _expandedReports.add(id);
              }
            });
          },
        );
    }
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: AppColors.gray400),
          const SizedBox(height: 16),
          const Text('加载失败',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray600)),
          const SizedBox(height: 8),
          Text(message,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.gray400)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ref
                .read(projectManageProvider(widget.projectId).notifier)
                .loadAll(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('重试',
                  style: TextStyle(fontSize: 14, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewBar extends StatelessWidget {
  final int progress;
  const _OverviewBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.white,
      child: Row(
        children: [
          ProgressRing(progress: progress, size: 52, strokeWidth: 5),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('项目进度',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.gray500)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: AppColors.gray200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent),
                    minHeight: 6,
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

class _PrdTab extends StatelessWidget {
  final String projectId;
  const _PrdTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined,
              size: 48, color: AppColors.gray300),
          const SizedBox(height: 12),
          const Text('查看项目需求文档',
              style: TextStyle(fontSize: 15, color: AppColors.gray500)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push('/projects/$projectId/prd'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('查看 PRD',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilesTab extends StatelessWidget {
  const _FilesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 48, color: AppColors.gray300),
          SizedBox(height: 12),
          Text('文件管理（Phase 5）',
              style: TextStyle(fontSize: 15, color: AppColors.gray500)),
        ],
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  final List<DailyReport> reports;
  final Set<String> expandedReports;
  final ValueChanged<String> onToggle;

  const _ReportTab({
    super.key,
    required this.reports,
    required this.expandedReports,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 48, color: AppColors.gray300),
            SizedBox(height: 12),
            Text('暂无 AI 简报',
                style: TextStyle(fontSize: 15, color: AppColors.gray500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = reports[index];
        return DailyReportCard(
          report: report,
          isExpanded: expandedReports.contains(report.id),
          onToggle: () => onToggle(report.id),
        );
      },
    );
  }
}
