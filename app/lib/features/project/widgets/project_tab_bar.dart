import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/project_models.dart';

class ProjectTabBar extends StatelessWidget {
  final ProjectTab selected;
  final ValueChanged<ProjectTab> onChanged;

  const ProjectTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _tabs = [
    (ProjectTab.tasks, '任务', Icons.check_circle_outline),
    (ProjectTab.milestones, '里程碑', Icons.flag_outlined),
    (ProjectTab.files, '文件', Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = tab.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Center(
                    child: Text(
                      tab.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.black
                            : AppColors.gray500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 32,
                      decoration: BoxDecoration(
                        gradient: AppGradients.accent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
