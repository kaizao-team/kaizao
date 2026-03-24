import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class RoleFilterChips extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String?> onSelected;

  const RoleFilterChips({
    super.key,
    this.selectedRole,
    required this.onSelected,
  });

  static const _roles = [
    '全部',
    'Flutter开发',
    '前端开发',
    '后端开发',
    '全栈开发',
    'UI设计',
    '产品经理',
    '测试工程师',
    'DevOps',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _roles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final role = _roles[index];
          final isAll = role == '全部';
          final isSelected =
              isAll ? selectedRole == null : selectedRole == role;

          return GestureDetector(
            onTap: () => onSelected(isAll ? null : role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.gray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.white : AppColors.gray600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
