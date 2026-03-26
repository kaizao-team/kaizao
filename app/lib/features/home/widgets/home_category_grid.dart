import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/home_models.dart';

class HomeCategoryGrid extends StatelessWidget {
  final List<CategoryItem> categories;
  final void Function(String categoryKey) onCategoryTap;

  const HomeCategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  static const _iconMap = <String, IconData>{
    'phone_android': Icons.phone_android,
    'language': Icons.language,
    'widgets': Icons.widgets_outlined,
    'palette': Icons.palette_outlined,
    'analytics': Icons.analytics_outlined,
    'school': Icons.school_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '热门分类',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 109 / 72,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () => onCategoryTap(cat.key),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray200, width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconMap[cat.icon] ?? Icons.category_outlined,
                        size: 24,
                        color: AppColors.black,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
