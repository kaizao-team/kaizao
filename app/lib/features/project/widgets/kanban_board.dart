import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/project_models.dart';

class KanbanBoard extends StatefulWidget {
  final List<KanbanTask> todoTasks;
  final List<KanbanTask> inProgressTasks;
  final List<KanbanTask> completedTasks;
  final bool readOnly;
  final void Function(String taskId, String newStatus) onMoveTask;

  const KanbanBoard({
    super.key,
    required this.todoTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.readOnly,
    required this.onMoveTask,
  });

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  // 已完成默认折叠
  final Map<String, bool> _expanded = {
    'todo': true,
    'in_progress': true,
    'completed': false,
  };

  @override
  Widget build(BuildContext context) {
    final sections = [
      (status: 'todo', label: '待办', tasks: widget.todoTasks),
      (status: 'in_progress', label: '进行中', tasks: widget.inProgressTasks),
      (status: 'completed', label: '已完成', tasks: widget.completedTasks),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xxl),
      children: sections.map((section) {
        final isExpanded = _expanded[section.status] ?? true;
        return _TaskSection(
          status: section.status,
          label: section.label,
          tasks: section.tasks,
          isExpanded: isExpanded,
          readOnly: widget.readOnly,
          onToggle: () => setState(() {
            _expanded[section.status] = !isExpanded;
          }),
          onMoveTask: widget.onMoveTask,
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Section (foldable)
// ─────────────────────────────────────────────────────────────────────────────

class _TaskSection extends StatelessWidget {
  final String status;
  final String label;
  final List<KanbanTask> tasks;
  final bool isExpanded;
  final bool readOnly;
  final VoidCallback onToggle;
  final void Function(String taskId, String newStatus) onMoveTask;

  const _TaskSection({
    required this.status,
    required this.label,
    required this.tasks,
    required this.isExpanded,
    required this.readOnly,
    required this.onToggle,
    required this.onMoveTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      size: 18, color: AppColors.gray400),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$label · ${tasks.length}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppSpacing.md, left: AppSpacing.sm),
                  child: Text(
                    '无任务',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.gray400),
                  ),
                )
              : Column(
                  children: tasks
                      .map((task) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _TaskCard(
                              task: task,
                              readOnly: readOnly,
                              currentStatus: status,
                              onMove: onMoveTask,
                            ),
                          ))
                      .toList(),
                ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Card
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final KanbanTask task;
  final bool readOnly;
  final String currentStatus;
  final void Function(String taskId, String newStatus) onMove;

  const _TaskCard({
    required this.task,
    required this.readOnly,
    required this.currentStatus,
    required this.onMove,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case 'P0':
        return AppColors.error;
      case 'P1':
        return AppColors.warning;
      default:
        return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: priority badge + title + effort
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  task.priority,
                  style: AppTextStyles.overline.copyWith(
                    color: _priorityColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  task.title,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task.effortHours > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${task.effortHours}h',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.gray400),
                ),
              ],
            ],
          ),

          // Row 2: description
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              task.description,
              style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Row 3: assignee + move button
          if (task.assignee != null || !readOnly) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (task.assignee != null) ...[
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.gray400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.assignee!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.gray500),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (!readOnly)
                  GestureDetector(
                    onTap: () => _showMoveSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.gray200, width: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '移动',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.expand_more,
                              size: 12, color: AppColors.gray400),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showMoveSheet(BuildContext context) {
    final targets = <(String, String)>[
      ('todo', '待办'),
      ('in_progress', '进行中'),
      ('completed', '已完成'),
    ].where((t) => t.$1 != currentStatus).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                '移动到',
                style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.gray500),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...targets.map((t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.$2, style: AppTextStyles.body1),
                    onTap: () {
                      Navigator.of(context).pop();
                      onMove(task.id, t.$1);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
