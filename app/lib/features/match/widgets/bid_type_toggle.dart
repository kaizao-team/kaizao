import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/match_models.dart';

class BidTypeToggle extends StatelessWidget {
  final BidFormType selected;
  final ValueChanged<BidFormType> onChanged;

  const BidTypeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: BidFormType.values.map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? AppShadows.shadow1 : null,
                ),
                child: Center(
                  child: Text(
                    type == BidFormType.personal ? '个人投标' : '团队投标',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.black : AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
