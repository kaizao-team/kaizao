import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/chat_models.dart';

class TaskCardMessage extends StatelessWidget {
  final TaskCardExtra task;
  final VoidCallback? onTap;

  const TaskCardMessage({super.key, required this.task, this.onTap});

  Color get _typeColor {
    switch (task.taskType) {
      case 'event': return AppColors.info;
      case 'state': return AppColors.warning;
      case 'unwanted': return AppColors.error;
      default: return AppColors.accent;
    }
  }

  String get _typeLabel {
    switch (task.taskType) {
      case 'event': return '事件';
      case 'state': return '状态';
      case 'unwanted': return '异常';
      default: return '始终';
    }
  }

  String get _statusLabel {
    switch (task.taskStatus) {
      case 'completed': return '已完成';
      case 'in_progress': return '进行中';
      default: return '待办';
    }
  }

  Color get _statusColor {
    switch (task.taskStatus) {
      case 'completed': return AppColors.success;
      case 'in_progress': return AppColors.accent;
      default: return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
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
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.taskId,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              task.taskTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              task.taskSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
