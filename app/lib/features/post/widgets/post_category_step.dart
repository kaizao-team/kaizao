import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_card.dart';

class PostCategoryStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const PostCategoryStep({
    super.key,
    this.selected,
    required this.onSelect,
  });

  static const _categories = [
    _CategoryOption(
      key: 'data',
      label: '数据',
      description: '适合数据分析、BI 报表、指标体系与业务洞察类项目。',
      deliverable: '常见交付：看板、分析结论、指标方案',
    ),
    _CategoryOption(
      key: 'dev',
      label: '研发',
      description: '适合产品开发、功能交付、系统搭建与技术实现类项目。',
      deliverable: '常见交付：APP、Web、后台、接口服务',
    ),
    _CategoryOption(
      key: 'visual',
      label: '视觉设计',
      description: '适合品牌视觉、界面设计、交互表达与体验优化类项目。',
      deliverable: '常见交付：品牌稿、页面稿、设计规范',
    ),
    _CategoryOption(
      key: 'solution',
      label: '解决方案',
      description: '适合前期梳理、方案拆解、策略咨询与落地路径设计类项目。',
      deliverable: '常见交付：方案文档、实施路径、顾问建议',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = switch (selected) {
      'design' => 'visual',
      _ => selected,
    };

    return Column(
      children: _categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final isSelected = normalizedSelected == category.key;

        return Padding(
          padding: EdgeInsets.only(
            bottom: category == _categories.last ? 0 : 12,
          ),
          child: VccCard(
            onTap: () => onSelect(category.key),
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            backgroundColor:
                isSelected ? AppColors.gray100 : AppColors.onboardingSurface,
            border: Border.all(
              color: isSelected ? AppColors.black : AppColors.gray200,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(17, 17, 17, 0.04),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: AppTextStyles.onboardingMeta.copyWith(
                          color:
                              isSelected ? AppColors.black : AppColors.gray500,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 18,
                        height: 2,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.black : AppColors.gray300,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.label,
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '已选',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2.copyWith(
                          height: 1.55,
                          color: AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.deliverable,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_outward_rounded,
                    size: 18,
                    color: isSelected ? AppColors.black : AppColors.gray300,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryOption {
  final String key;
  final String label;
  final String description;
  final String deliverable;

  const _CategoryOption({
    required this.key,
    required this.label,
    required this.description,
    required this.deliverable,
  });
}
