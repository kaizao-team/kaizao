import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../models/project_models.dart';

class MilestoneTimeline extends StatelessWidget {
  final List<Milestone> milestones;
  final bool isTeamMember;
  final void Function(
    String milestoneId,
    String action, {
    String? note,
    String? previewUrl,
    String? reason,
  })? onMilestoneAction;
  final void Function(Milestone milestone)? onTap;

  const MilestoneTimeline({
    super.key,
    required this.milestones,
    this.isTeamMember = false,
    this.onMilestoneAction,
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
          isTeamMember: isTeamMember,
          onMilestoneAction: onMilestoneAction,
          onTap: onTap != null ? () => onTap!(ms) : null,
        );
      },
    );
  }
}

Color milestoneStatusColor(String status) {
  switch (status) {
    case 'completed':
      return AppColors.success;
    case 'delivered':
      return AppColors.info;
    case 'in_progress':
      return AppColors.accent;
    case 'revision_requested':
      return AppColors.warning;
    default:
      return AppColors.gray300; // pending
  }
}

class _MilestoneItem extends StatelessWidget {
  final Milestone milestone;
  final bool isLast;
  final bool isTeamMember;
  final void Function(
    String milestoneId,
    String action, {
    String? note,
    String? previewUrl,
    String? reason,
  })? onMilestoneAction;
  final VoidCallback? onTap;

  const _MilestoneItem({
    required this.milestone,
    required this.isLast,
    required this.isTeamMember,
    this.onMilestoneAction,
    this.onTap,
  });

  Color get _nodeColor => milestoneStatusColor(milestone.status);

  Color get _lineColor =>
      milestone.isCompleted ? AppColors.success : AppColors.gray200;

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
                    isActive: milestone.isInProgress || milestone.isDelivered,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: _lineColor),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.gray200, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            milestone.title,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: milestone.isPending
                                  ? AppColors.gray400
                                  : AppColors.onSurface,
                              decoration: milestone.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        // Status badge
                        _StatusBadge(status: milestone.status),
                      ],
                    ),

                    // Description
                    if (milestone.description != null &&
                        milestone.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        milestone.description!,
                        style: AppTextStyles.caption
                            .copyWith(height: 1.5, color: AppColors.gray500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Phase tags
                    if (milestone.phases.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: milestone.phases.map((phase) {
                          final name = phase['name']?.toString() ?? '';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              name,
                              style: AppTextStyles.overline.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Meta row
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (milestone.dueDate.isNotEmpty) ...[
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.gray400),
                          const SizedBox(width: 4),
                          Text(
                            milestone.dueDate,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.gray500),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (milestone.estimatedDays != null) ...[
                          const Icon(Icons.schedule_outlined,
                              size: 12, color: AppColors.gray400),
                          const SizedBox(width: 4),
                          Text(
                            '${milestone.estimatedDays!.toStringAsFixed(milestone.estimatedDays == milestone.estimatedDays!.roundToDouble() ? 0 : 1)} 天',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.gray500),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (milestone.amount > 0)
                          Text(
                            '¥${milestone.amount.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600,
                            ),
                          ),
                      ],
                    ),

                    // Action area
                    if (onMilestoneAction != null)
                      _ActionArea(
                        milestone: milestone,
                        isTeamMember: isTeamMember,
                        onAction: onMilestoneAction!,
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

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  String get _label {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'delivered':
        return '待验收';
      case 'in_progress':
        return '进行中';
      case 'revision_requested':
        return '待修改';
      default:
        return '待开始';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = milestoneStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        _label,
        style: AppTextStyles.overline
            .copyWith(color: color, fontWeight: FontWeight.w600, letterSpacing: 0),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Area (role + status dependent)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionArea extends StatelessWidget {
  final Milestone milestone;
  final bool isTeamMember;
  final void Function(
    String milestoneId,
    String action, {
    String? note,
    String? previewUrl,
    String? reason,
  }) onAction;

  const _ActionArea({
    required this.milestone,
    required this.isTeamMember,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Team member actions
    if (isTeamMember) {
      if (milestone.isInProgress) {
        return _actionRow(
          context,
          child: VccButton(
            text: '提交交付',
            onPressed: () => _showDeliverSheet(context),
          ),
        );
      }
      if (milestone.isRevisionRequested) {
        return _actionRow(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '项目方要求修改',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.warning),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              VccButton(
                text: '重新提交',
                onPressed: () => _showDeliverSheet(context),
              ),
            ],
          ),
        );
      }
      if (milestone.isDelivered) {
        return _actionRow(
          context,
          child: Text(
            '已提交，等待验收',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.info),
          ),
        );
      }
    }

    // Project owner actions
    if (!isTeamMember) {
      if (milestone.isDelivered) {
        return _actionRow(
          context,
          child: Row(
            children: [
              Expanded(
                child: VccButton(
                  text: '验收通过',
                  onPressed: () => _showAcceptDialog(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: VccButton(
                  text: '要求修改',
                  type: VccButtonType.secondary,
                  onPressed: () => _showRevisionSheet(context),
                ),
              ),
            ],
          ),
        );
      }
      if (milestone.isRevisionRequested) {
        return _actionRow(
          context,
          child: Text(
            '等待团队方修改',
            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _actionRow(BuildContext context, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.base),
        Container(
          height: 0.5,
          color: AppColors.gray200,
        ),
        const SizedBox(height: AppSpacing.base),
        child,
      ],
    );
  }

  void _showDeliverSheet(BuildContext context) {
    final noteController = TextEditingController();
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('提交交付', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.xl),
            Text('交付说明（可选）', style: AppTextStyles.inputLabel),
            const SizedBox(height: AppSpacing.sm),
            VccInput(
              controller: noteController,
              hint: '简要描述本次交付的内容',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('预览链接（可选）', style: AppTextStyles.inputLabel),
            const SizedBox(height: AppSpacing.sm),
            VccInput(
              controller: urlController,
              hint: 'https://',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.xl),
            VccButton(
              text: '确认提交',
              onPressed: () {
                Navigator.of(ctx).pop();
                onAction(
                  milestone.id,
                  'deliver',
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                  previewUrl: urlController.text.trim().isEmpty
                      ? null
                      : urlController.text.trim(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        title: Text('确认验收', style: AppTextStyles.h3),
        content: Text(
          '确认验收「${milestone.title}」？\n验收后将释放该阶段款项。',
          style: AppTextStyles.body2.copyWith(color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('取消',
                style: AppTextStyles.body2.copyWith(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onAction(milestone.id, 'accept');
            },
            child: Text('验收通过',
                style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showRevisionSheet(BuildContext context) {
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('要求修改', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.xl),
            Text('修改原因', style: AppTextStyles.inputLabel),
            const SizedBox(height: AppSpacing.sm),
            VccInput(
              controller: reasonController,
              hint: '请说明需要修改的内容',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            VccButton(
              text: '确认提交',
              onPressed: () {
                Navigator.of(ctx).pop();
                onAction(
                  milestone.id,
                  'revision',
                  reason: reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Node Widget
// ─────────────────────────────────────────────────────────────────────────────

class _NodeWidget extends StatefulWidget {
  final Color color;
  final bool isCompleted;
  final bool isActive; // in_progress or delivered

  const _NodeWidget({
    required this.color,
    required this.isCompleted,
    required this.isActive,
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
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
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
          if (widget.isActive)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Container(
                width: 28 * _pulseAnimation.value,
                height: 28 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.15),
                ),
              ),
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
                : widget.isActive
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
