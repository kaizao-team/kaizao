import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_filter_chip_bar.dart';
import '../models/market_filter.dart';

class MarketFilterBar extends StatelessWidget {
  final String selectedCategory;
  final String sortBy;
  final bool hasActiveFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onFilterTap;
  final int userRole;

  const MarketFilterBar({
    super.key,
    required this.selectedCategory,
    required this.sortBy,
    required this.hasActiveFilter,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onFilterTap,
    this.userRole = 1,
  });

  @override
  Widget build(BuildContext context) {
    final categoryOptions = MarketCategory.all
        .map(
          (cat) => VccFilterChipOption<String>(
            value: cat.key,
            label: cat.name,
          ),
        )
        .toList(growable: false);

    return Column(
      children: [
        VccFilterChipBar<String>(
          options: categoryOptions,
          selectedValue: selectedCategory,
          onSelected: onCategoryChanged,
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
    final sortOptions = MarketSortOption.forRole(userRole);
    final currentSort = sortOptions.firstWhere(
      (s) => s.key == sortBy,
      orElse: () => sortOptions.first,
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
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.gray600,
            ),
          ],
        ),
      ),
      itemBuilder: (_) => sortOptions
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
