import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_card.dart';

class PostPrdLoading extends StatelessWidget {
  final int progress;

  const PostPrdLoading({
    super.key,
    required this.progress,
  });

  static const _steps = [
    _LoadingStep(
      label: '分析需求语境',
      description: '识别目标、用户、关键约束与项目边界。',
      icon: Icons.search_rounded,
    ),
    _LoadingStep(
      label: '整理模块结构',
      description: '把零散描述归并成可以推进的模块骨架。',
      icon: Icons.account_tree_outlined,
    ),
    _LoadingStep(
      label: '生成需求卡片',
      description: '为每个模块拆出可执行的功能卡片。',
      icon: Icons.layers_outlined,
    ),
    _LoadingStep(
      label: '完成项目定义',
      description: '补足预算提示和后续发布所需的结构信息。',
      icon: Icons.description_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0, 100);
    final activeStep = normalizedProgress >= 100
        ? _steps.length - 1
        : (normalizedProgress / 25).floor().clamp(0, _steps.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VccCard(
          padding: const EdgeInsets.all(24),
          backgroundColor: AppColors.onboardingSurface,
          border: Border.all(color: AppColors.gray200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRD 生成中',
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.gray500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$normalizedProgress%',
                style: AppTextStyles.num1.copyWith(
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'AI 正在把对话里的目标、范围和限制整理成可继续推进的项目定义。',
                style: AppTextStyles.body1.copyWith(
                  height: 1.6,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: normalizedProgress / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.gray200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted =
              normalizedProgress >= 100 ? true : index < activeStep;
          final isActive = normalizedProgress < 100 && index == activeStep;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _steps.length - 1 ? 0 : 12,
            ),
            child: VccCard(
              padding: const EdgeInsets.all(18),
              backgroundColor:
                  isActive ? AppColors.gray100 : AppColors.onboardingSurface,
              border: Border.all(
                color: isActive ? AppColors.black : AppColors.gray200,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? AppColors.black
                          : AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : step.icon,
                      size: 18,
                      color: isCompleted || isActive
                          ? AppColors.white
                          : AppColors.gray500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: AppTextStyles.body2.copyWith(
                            height: 1.55,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCompleted
                        ? '完成'
                        : isActive
                            ? '处理中'
                            : '等待',
                    style: AppTextStyles.caption.copyWith(
                      color: isCompleted || isActive
                          ? AppColors.black
                          : AppColors.gray400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LoadingStep {
  final String label;
  final String description;
  final IconData icon;

  const _LoadingStep({
    required this.label,
    required this.description,
    required this.icon,
  });
}
