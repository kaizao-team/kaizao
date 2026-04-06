import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class VccFilterChipOption<T> {
  final T value;
  final String label;

  const VccFilterChipOption({
    required this.value,
    required this.label,
  });
}

class VccFilterChipBar<T> extends StatelessWidget {
  final List<VccFilterChipOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  final double height;

  const VccFilterChipBar({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selectedValue;

          return GestureDetector(
            onTap: () => onSelected(option.value),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.gray50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.gray200,
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: AppDurations.normal,
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.white : AppColors.gray600,
                ),
                child: Text(option.label),
              ),
            ),
          );
        },
      ),
    );
  }
}
