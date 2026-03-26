import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'vcc_tag.dart';

/// 开造 VCC 通用卡片组件 — 白底 + 细边框，Notion 风格
class VccCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final Gradient? gradient;
  final Color? backgroundColor;

  const VccCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.boxShadow,
    this.border,
    this.gradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient == null
              ? (backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.white))
              : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          border: border ??
              Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.gray200,
                width: 1,
              ),
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}

/// 项目卡片 — 白底细边框风格
class VccProjectCard extends StatelessWidget {
  final String title;
  final String description;
  final String? amount;
  final int? matchScore;
  final List<String> tags;
  final String? aiTip;
  final String? footerInfo;
  final VoidCallback? onTap;

  const VccProjectCard({
    super.key,
    required this.title,
    required this.description,
    this.amount,
    this.matchScore,
    this.tags = const [],
    this.aiTip,
    this.footerInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VccCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (matchScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '匹配 $matchScore%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              if (amount != null)
                Text(
                  amount!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.gray500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) => VccTag(label: tag)).toList(),
            ),
          ],
          if (aiTip != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                aiTip!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
          if (footerInfo != null) ...[
            const SizedBox(height: 12),
            Text(
              footerInfo!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.gray400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
