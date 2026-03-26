import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class PrdRoleFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const PrdRoleFilter({
    super.key,
    this.selected,
    required this.onChanged,
  });

  static const _roles = [
    {'key': 'frontend', 'label': '前端'},
    {'key': 'backend', 'label': '后端'},
    {'key': 'algorithm', 'label': '算法'},
    {'key': 'design', 'label': '设计'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: '全部',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          ..._roles.map((role) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(
                  label: role['label']!,
                  isSelected: selected == role['key'],
                  onTap: () => onChanged(role['key']),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: isSelected ? AppColors.black : AppColors.gray300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.white : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}
