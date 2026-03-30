import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/models/project_category.dart';

class PostCategoryStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const PostCategoryStep({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '你想做什么？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '选择一个分类，AI 将帮你梳理需求',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: projectCategorySpecs.map((cat) {
              final key = cat.key;
              final isSelected = selected == key;
              return GestureDetector(
                onTap: () => onSelect(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.black : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.black : AppColors.gray200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _categoryIcon(key),
                        size: 20,
                        color: isSelected ? AppColors.white : AppColors.gray600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String key) {
  switch (key) {
    case 'dev':
      return Icons.code_rounded;
    case 'visual':
      return Icons.palette_outlined;
    case 'data':
      return Icons.bar_chart_rounded;
    case 'solution':
      return Icons.lightbulb_outline_rounded;
    default:
      return Icons.more_horiz;
  }
}
