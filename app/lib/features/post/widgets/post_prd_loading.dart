import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class PostPrdLoading extends StatelessWidget {
  final int progress;

  const PostPrdLoading({super.key, required this.progress});

  static const _steps = [
    {'label': '分析需求', 'icon': Icons.search},
    {'label': '构建模块', 'icon': Icons.account_tree_outlined},
    {'label': '生成卡片', 'icon': Icons.style_outlined},
    {'label': '完善文档', 'icon': Icons.description_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final activeStep = (progress / 25).floor().clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 3,
                    backgroundColor: AppColors.gray200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                Text(
                  '$progress%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '正在生成 PRD...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI 正在分析你的需求并生成项目文档',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 40),
          ..._steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isActive = i == activeStep;
            final isCompleted = i < activeStep;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accentLight
                      : isCompleted
                          ? AppColors.gray50
                          : AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppColors.accent
                        : isCompleted
                            ? AppColors.gray200
                            : AppColors.gray200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : (step['icon'] as IconData),
                      size: 20,
                      color: isCompleted
                          ? AppColors.success
                          : isActive
                              ? AppColors.accent
                              : AppColors.gray400,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive || isCompleted ? AppColors.black : AppColors.gray400,
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
