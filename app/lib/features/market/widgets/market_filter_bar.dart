import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/market_filter.dart';

class MarketFilterBar extends StatelessWidget {
  final String selectedCategory;
  final String sortBy;
  final bool hasActiveFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onFilterTap;

  const MarketFilterBar({
    super.key,
    required this.selectedCategory,
    required this.sortBy,
    required this.hasActiveFilter,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: MarketCategory.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = MarketCategory.all[index];
              final isSelected = cat.key == selectedCategory;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.black : AppColors.gray100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? AppColors.white : AppColors.gray600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildSortDropdown(context),
              const Spacer(),
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: hasActiveFilter
                        ? AppColors.accentLight
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16,
                        color: hasActiveFilter
                            ? AppColors.accent
                            : AppColors.gray600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '筛选',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasActiveFilter
                              ? AppColors.accent
                              : AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    final currentSort = MarketSortOption.all.firstWhere(
      (s) => s.key == sortBy,
      orElse: () => MarketSortOption.all.first,
    );

    return PopupMenuButton<String>(
      onSelected: onSortChanged,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentSort.name,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.gray600),
          ],
        ),
      ),
      itemBuilder: (_) => MarketSortOption.all
          .map(
            (s) => PopupMenuItem<String>(
              value: s.key,
              child: Row(
                children: [
                  if (s.key == sortBy)
                    const Icon(Icons.check, size: 16, color: AppColors.accent)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(s.name),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
