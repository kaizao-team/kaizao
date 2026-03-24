import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/match_models.dart';

class AiSuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;

  const AiSuggestionCard({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final isLowMatch = suggestion.skillMatchScore < 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 16, color: AppColors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI 评估建议',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: '建议报价',
            value:
                '¥${suggestion.suggestedPriceMin.toStringAsFixed(0)}-${suggestion.suggestedPriceMax.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: '建议工期',
            value: '${suggestion.suggestedDurationDays}天',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: '技能匹配度',
            value: '${suggestion.skillMatchScore}%',
            valueColor: isLowMatch ? AppColors.warning : AppColors.success,
          ),
          if (isLowMatch) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.warning),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '技能匹配度较低，建议评估后再投标',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            suggestion.reason,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.gray500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.black,
          ),
        ),
      ],
    );
  }
}
