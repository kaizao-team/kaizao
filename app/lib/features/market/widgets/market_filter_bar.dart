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
    const categories = MarketCategory.all;

    return SizedBox(
      key: const ValueKey('market-project-filter-bar'),
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(categories.length, (index) {
                  final category = categories[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == categories.length - 1 ? 0 : 6,
                    ),
                    child: _MarketCategoryTab(
                      label: category.name,
                      selected: category.key == selectedCategory,
                      onTap: () => onCategoryChanged(category.key),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildSortDropdown(context),
          const SizedBox(width: 8),
          _FilterButton(
            active: hasActiveFilter,
            onTap: onFilterTap,
          ),
        ],
      ),
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
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: AppColors.gray500,
            ),
            const SizedBox(width: 4),
            Text(
              currentSort.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.gray500,
            ),
          ],
        ),
      ),
      itemBuilder: (_) => sortOptions
          .map(
            (option) => PopupMenuItem<String>(
              value: option.key,
              child: Row(
                children: [
                  if (option.key == sortBy)
                    const Icon(Icons.check, size: 16, color: AppColors.accent)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(option.name),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MarketCategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MarketCategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.gray100 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.gray200 : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.black : AppColors.gray500,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.accentLight : AppColors.gray100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.accentMuted : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: active ? AppColors.accent : AppColors.gray600,
            ),
            const SizedBox(width: 4),
            Text(
              '筛选',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.accent : AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
