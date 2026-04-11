import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/project_models.dart';

/// 需求 → EARS 任务父子级联展示
class RequirementTaskList extends StatelessWidget {
  final List<KanbanTask> tasks;
  final List<Map<String, dynamic>> prdItems;

  const RequirementTaskList({
    super.key,
    required this.tasks,
    required this.prdItems,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined,
                size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text('暂无任务',
                style: AppTextStyles.body2.copyWith(color: AppColors.gray500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      itemCount: groups.length,
      itemBuilder: (context, index) => _RequirementGroup(group: groups[index]),
    );
  }

  List<_TaskGroup> _buildGroups() {
    // 按 featureItemId 分组
    final grouped = <String, List<KanbanTask>>{};
    final ungrouped = <KanbanTask>[];

    for (final task in tasks) {
      final fid = task.featureItemId;
      if (fid != null && fid.isNotEmpty) {
        grouped.putIfAbsent(fid, () => []).add(task);
      } else {
        ungrouped.add(task);
      }
    }

    // 构建 prdItem 查找表
    final prdMap = <String, Map<String, dynamic>>{};
    for (final item in prdItems) {
      final itemId = item['item_id']?.toString() ?? '';
      if (itemId.isNotEmpty) prdMap[itemId] = item;
    }

    final groups = <_TaskGroup>[];

    // 按 feature_item_id 排序
    final sortedKeys = grouped.keys.toList()..sort();
    for (final fid in sortedKeys) {
      final prd = prdMap[fid];
      groups.add(_TaskGroup(
        featureItemId: fid,
        requirementTitle: prd?['title']?.toString() ?? '',
        moduleName: prd?['module_name']?.toString() ?? '',
        priority: prd?['priority']?.toString() ?? '',
        tasks: grouped[fid]!,
      ));
    }

    // 未关联的任务
    if (ungrouped.isNotEmpty) {
      groups.add(_TaskGroup(
        featureItemId: '',
        requirementTitle: '未关联需求',
        moduleName: '',
        priority: '',
        tasks: ungrouped,
      ));
    }

    return groups;
  }
}

class _TaskGroup {
  final String featureItemId;
  final String requirementTitle;
  final String moduleName;
  final String priority;
  final List<KanbanTask> tasks;

  const _TaskGroup({
    required this.featureItemId,
    required this.requirementTitle,
    required this.moduleName,
    required this.priority,
    required this.tasks,
  });
}

class _RequirementGroup extends StatefulWidget {
  final _TaskGroup group;

  const _RequirementGroup({required this.group});

  @override
  State<_RequirementGroup> createState() => _RequirementGroupState();
}

class _RequirementGroupState extends State<_RequirementGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 需求父级
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      size: 18, color: AppColors.gray400),
                ),
                const SizedBox(width: 6),
                if (g.featureItemId.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      g.featureItemId,
                      style: AppTextStyles.overline.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    g.requirementTitle.isNotEmpty
                        ? g.requirementTitle
                        : g.featureItemId,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                if (g.priority.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _priorityColor(g.priority).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      g.priority,
                      style: AppTextStyles.overline.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _priorityColor(g.priority),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${g.tasks.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // EARS 子任务列表
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: g.tasks
                  .map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EarsTaskCard(task: task),
                      ))
                  .toList(),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'P0':
        return AppColors.error;
      case 'P1':
        return AppColors.warning;
      default:
        return AppColors.gray400;
    }
  }
}

class _EarsTaskCard extends StatelessWidget {
  final KanbanTask task;

  const _EarsTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：编号 + 类型 + 工时
          Row(
            children: [
              if (task.taskCode != null) ...[
                Text(
                  task.taskCode!,
                  style: AppTextStyles.overline.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray400,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (task.earsType != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _earsTypeLabel(task.earsType!),
                    style: AppTextStyles.overline.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              const Spacer(),
              if (task.effortHours > 0)
                Text(
                  '${task.effortHours}h',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.gray400),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // EARS 描述
          Text(
            task.title,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _earsTypeLabel(String type) {
    switch (type) {
      case 'ubiquitous':
        return '普适性';
      case 'event':
        return '事件驱动';
      case 'state':
        return '状态驱动';
      case 'optional':
        return '可选功能';
      case 'unwanted':
        return '异常处理';
      default:
        return type;
    }
  }
}
