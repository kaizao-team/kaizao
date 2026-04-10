import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/project_models.dart';

class MilestoneTimeline extends StatelessWidget {
  final List<Milestone> milestones;
  final void Function(Milestone milestone)? onTap;

  const MilestoneTimeline({
    super.key,
    required this.milestones,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final ms = milestones[index];
        final isLast = index == milestones.length - 1;
        return _MilestoneItem(
          milestone: ms,
          isLast: isLast,
          onTap: onTap != null ? () => onTap!(ms) : null,
        );
      },
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final Milestone milestone;
  final bool isLast;
  final VoidCallback? onTap;

  const _MilestoneItem({
    required this.milestone,
    required this.isLast,
    this.onTap,
  });

  Color get _nodeColor {
    if (milestone.isCompleted) return AppColors.success;
    if (milestone.isInProgress) return AppColors.accent;
    return AppColors.gray300;
  }

  Color get _lineColor {
    if (milestone.isCompleted) return AppColors.success;
    return AppColors.gray200;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  _NodeWidget(
                    color: _nodeColor,
                    isCompleted: milestone.isCompleted,
                    isInProgress: milestone.isInProgress,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: _lineColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: milestone.isInProgress
                      ? AppColors.accentLight
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: milestone.isInProgress
                        ? AppColors.accentMuted
                        : AppColors.gray200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            milestone.title,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: milestone.isInProgress
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: milestone.isPending
                                  ? AppColors.gray400
                                  : AppColors.black,
                              decoration: milestone.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (milestone.isInProgress)
                          Text(
                            '${milestone.progress}%',
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          milestone.dueDate,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray500),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '¥${milestone.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${milestone.completedTaskCount}/${milestone.taskCount} 任务',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeWidget extends StatefulWidget {
  final Color color;
  final bool isCompleted;
  final bool isInProgress;

  const _NodeWidget({
    required this.color,
    required this.isCompleted,
    required this.isInProgress,
  });

  @override
  State<_NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<_NodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isInProgress) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInProgress != oldWidget.isInProgress) {
      if (widget.isInProgress) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isInProgress)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 28 * _pulseAnimation.value,
                  height: 28 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.15),
                  ),
                );
              },
            ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: widget.isCompleted
                ? const Icon(Icons.check, size: 14, color: AppColors.white)
                : widget.isInProgress
                    ? Container(
                        margin: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
          ),
        ],
      ),
    );
  }
}
