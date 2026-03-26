import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/prd_models.dart';

class EarsCriteriaList extends StatelessWidget {
  final List<AcceptanceCriteria> criteria;
  final void Function(String criteriaId) onToggle;

  const EarsCriteriaList({
    super.key,
    required this.criteria,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (criteria.isEmpty) return const SizedBox();

    final completed = criteria.where((c) => c.checked).length;
    final total = criteria.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('验收标准', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black)),
            const SizedBox(width: 8),
            Text('$completed/$total', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
            const Spacer(),
            if (completed == total)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('全部通过', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            minHeight: 3,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(
              completed == total ? AppColors.success : AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...criteria.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onToggle(c.id),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: c.checked ? AppColors.black : AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: c.checked ? AppColors.black : AppColors.gray300),
                      ),
                      child: c.checked
                          ? const Icon(Icons.check, size: 14, color: AppColors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: c.checked ? AppColors.gray400 : AppColors.gray700,
                          decoration: c.checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
