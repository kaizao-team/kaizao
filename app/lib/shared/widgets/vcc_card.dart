import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'vcc_tag.dart';

/// 开造 VCC 通用卡片组件
class VccCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final Gradient? gradient;

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
              ? (isDark ? AppColors.darkCard : Colors.white)
              : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          border: border ??
              Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
          boxShadow: boxShadow ?? AppShadows.shadow2,
        ),
        child: child,
      ),
    );
  }
}

/// 项目卡片
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
          // 顶部行：匹配度标签 + 金额
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (matchScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryButton,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '匹配 $matchScore%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (amount != null)
                Text(
                  amount!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 描述
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
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                aiTip!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.info,
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
