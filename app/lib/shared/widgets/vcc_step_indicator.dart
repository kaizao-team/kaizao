import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// 开造 VCC 步骤指示器 — 线性进度条风格
class VccStepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String>? labels;

  const VccStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              final lineIndex = index ~/ 2;
              final isCompleted = lineIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isCompleted ? AppColors.black : AppColors.gray200,
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isActive = stepIndex == currentStep;

            return Container(
              width: isActive ? 28 : 20,
              height: isActive ? 28 : 20,
              decoration: BoxDecoration(
                color: isCompleted || isActive ? AppColors.black : AppColors.white,
                shape: BoxShape.circle,
                border: !(isCompleted || isActive)
                    ? Border.all(color: AppColors.gray300, width: 1.5)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: isActive ? 13 : 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.white : AppColors.gray400,
                        ),
                      ),
              ),
            );
          }),
        ),
        if (labels != null && labels!.length == totalSteps) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels!.asMap().entries.map((entry) {
              final isActive = entry.key == currentStep;
              final isCompleted = entry.key < currentStep;
              return Expanded(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive || isCompleted ? AppColors.black : AppColors.gray400,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
