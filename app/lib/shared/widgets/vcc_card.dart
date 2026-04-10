import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
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
              ? (backgroundColor ??
                  (isDark ? AppColors.darkCard : AppColors.surfaceRaised))
              : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.md),
          border: border ??
              Border.all(
                color:
                    isDark ? AppColors.darkDivider : AppColors.outlineVariant,
                width: 0.8,
              ),
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}

class VccSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;

  const VccSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return VccCard(
      margin: margin,
      padding: padding ?? const EdgeInsets.fromLTRB(18, 18, 18, 16),
      borderRadius: AppRadius.xxl,
      onTap: onTap,
      border: border,
      boxShadow: boxShadow,
      backgroundColor: backgroundColor ?? AppColors.surfaceRaised,
      child: child,
    );
  }
}

/// 项目卡片 — 白底 + 微妙阴影，Notion 风格
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
      backgroundColor: AppColors.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (matchScore != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '匹配 $matchScore%',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.gray500,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) => VccTag(label: tag)).toList(),
            ),
          ],
          if (aiTip != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                aiTip!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (amount != null)
                Text(
                  amount!,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
              const Spacer(),
              if (footerInfo != null)
                Text(
                  footerInfo!,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.gray400),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
