import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../models/project_models.dart';

class KanbanBoard extends StatelessWidget {
  final List<KanbanTask> todoTasks;
  final List<KanbanTask> inProgressTasks;
  final List<KanbanTask> completedTasks;
  final void Function(String taskId, String newStatus) onMoveTask;
  final void Function(KanbanTask task)? onTaskTap;

  const KanbanBoard({
    super.key,
    required this.todoTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.onMoveTask,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(
            title: '待办',
            tasks: todoTasks,
            statusColor: AppColors.gray400,
            acceptStatus: 'todo',
            onMoveTask: onMoveTask,
            onTaskTap: onTaskTap,
          ),
          const SizedBox(width: 12),
          _KanbanColumn(
            title: '进行中',
            tasks: inProgressTasks,
            statusColor: AppColors.accent,
            acceptStatus: 'in_progress',
            onMoveTask: onMoveTask,
            onTaskTap: onTaskTap,
          ),
          const SizedBox(width: 12),
          _KanbanColumn(
            title: '已完成',
            tasks: completedTasks,
            statusColor: AppColors.success,
            acceptStatus: 'completed',
            onMoveTask: onMoveTask,
            onTaskTap: onTaskTap,
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final List<KanbanTask> tasks;
  final Color statusColor;
  final String acceptStatus;
  final void Function(String taskId, String newStatus) onMoveTask;
  final void Function(KanbanTask task)? onTaskTap;

  const _KanbanColumn({
    required this.title,
    required this.tasks,
    required this.statusColor,
    required this.acceptStatus,
    required this.onMoveTask,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<KanbanTask>(
      onWillAcceptWithDetails: (details) => details.data.status != acceptStatus,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        onMoveTask(details.data.id, acceptStatus);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.accentLight
                : AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovering ? AppColors.accent : AppColors.gray200,
              width: isHovering ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$title (${tasks.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.gray200),
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('暂无任务',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.gray400)),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _DraggableTaskCard(
                        task: task,
                        onTap: onTaskTap != null
                            ? () => onTaskTap!(task)
                            : null,
                      );
                    },
                  ),
                ),
              if (isHovering)
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableTaskCard extends StatelessWidget {
  final KanbanTask task;
  final VoidCallback? onTap;

  const _DraggableTaskCard({required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<KanbanTask>(
      data: task,
      delay: const Duration(milliseconds: 300),
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: _TaskCardContent(task: task, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _TaskCardContent(task: task),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: _TaskCardContent(task: task),
      ),
    );
  }
}

class _TaskCardContent extends StatelessWidget {
  final KanbanTask task;
  final bool isDragging;

  const _TaskCardContent({required this.task, this.isDragging = false});

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 264,
      padding: const EdgeInsets.all(12),
      transform: isDragging
          ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: task.isAtRisk ? AppColors.error : AppColors.gray200,
            width: task.isAtRisk ? 3 : 1,
          ),
          top: BorderSide(color: AppColors.gray200, width: 1),
          right: BorderSide(color: AppColors.gray200, width: 1),
          bottom: BorderSide(color: AppColors.gray200, width: 1),
        ),
        boxShadow: isDragging ? AppShadows.shadow3 : AppShadows.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _priorityColor,
                  ),
                ),
              ),
              if (task.isAtRisk) ...[
                const SizedBox(width: 6),
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
                          size: 10, color: AppColors.error),
                      SizedBox(width: 2),
                      Text('有风险',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${task.effortHours}h',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.gray400),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            task.description,
            style:
                const TextStyle(fontSize: 12, color: AppColors.gray500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.assignee != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 12, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(task.assignee!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.gray500)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
