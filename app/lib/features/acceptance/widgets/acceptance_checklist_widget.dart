import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/acceptance_models.dart';

class AcceptanceChecklistWidget extends StatelessWidget {
  final List<AcceptanceItem> items;
  final double progress;
  final ValueChanged<String> onToggle;

  const AcceptanceChecklistWidget({
    super.key,
    required this.items,
    required this.progress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final checkedCount = items.where((i) => i.isChecked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.gray200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? AppColors.success : AppColors.accent,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$checkedCount / ${items.length}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _buildItem(item)),
      ],
    );
  }

  Widget _buildItem(AcceptanceItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onToggle(item.id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: item.isChecked
                ? AppColors.successBg
                : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.isChecked ? AppColors.success : AppColors.gray200,
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: item.isChecked ? AppColors.success : AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.isChecked
                        ? AppColors.success
                        : AppColors.gray300,
                    width: 1.5,
                  ),
                ),
                child: item.isChecked
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.isChecked
                            ? AppColors.gray500
                            : AppColors.gray800,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (item.sourceCard != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '来源: ${item.sourceCard}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.gray400),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
