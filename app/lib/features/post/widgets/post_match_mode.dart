import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/post_models.dart';

class PostMatchMode extends StatelessWidget {
  final MatchMode? selected;
  final ValueChanged<MatchMode> onSelect;

  const PostMatchMode({
    super.key,
    this.selected,
    required this.onSelect,
  });

  static const _modeIcons = {
    MatchMode.ai: Icons.auto_awesome,
    MatchMode.manual: Icons.search,
    MatchMode.invite: Icons.person_add_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '撮合模式',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black),
          ),
          const SizedBox(height: 8),
          const Text(
            '选择你希望的匹配方式',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 20),
          ...MatchMode.values.map((mode) {
            final isSelected = selected == mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.black : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.black : AppColors.gray200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color.fromRGBO(255, 255, 255, 0.15)
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _modeIcons[mode],
                          size: 20,
                          color: isSelected ? AppColors.white : AppColors.gray600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.white : AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mode.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? const Color.fromRGBO(255, 255, 255, 0.7)
                                    : AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, size: 22, color: AppColors.accent),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
