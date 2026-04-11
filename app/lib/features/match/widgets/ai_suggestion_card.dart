import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/match_models.dart';

class AiSuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;

  const AiSuggestionCard({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final isLowMatch = suggestion.skillMatchScore < 60;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 0.5),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 2.5, color: AppColors.accent),
              Expanded(
                child: Container(
                  color: AppColors.surfaceRaised,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'AI 评估',
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: '建议报价',
                  value:
                      '¥${suggestion.suggestedPriceMin.toStringAsFixed(0)}-${suggestion.suggestedPriceMax.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: '建议工期',
                  value: '${suggestion.suggestedDurationDays}天',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: '技能匹配',
                  value: '${suggestion.skillMatchScore}%',
                  valueColor:
                      isLowMatch ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            suggestion.reason,
            style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (isLowMatch) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '技能匹配度较低，建议补充相关经验说明',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.gray400,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Shown when AI suggestion is unavailable (null state after load)
class AiSuggestionUnavailable extends StatelessWidget {
  const AiSuggestionUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.gray400),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'AI 评估暂时不可用',
            style: AppTextStyles.body2.copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}
