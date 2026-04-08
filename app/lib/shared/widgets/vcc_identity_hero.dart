import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'vcc_card.dart';

class VccIdentityHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String headline;
  final String? summary;
  final Widget avatar;
  final List<Widget> badges;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onActionTap;
  final List<Widget> layers;
  final EdgeInsetsGeometry contentPadding;
  final double bottomSpacing;

  const VccIdentityHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.avatar,
    required this.badges,
    required this.actionLabel,
    required this.actionIcon,
    required this.onActionTap,
    this.summary,
    this.layers = const <Widget>[],
    this.contentPadding = const EdgeInsets.fromLTRB(20, 12, 20, 18),
    this.bottomSpacing = 32,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.tonalHeroEnd],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ...layers,
          Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      eyebrow,
                      style: AppTextStyles.overline.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    VccHeroActionButton(
                      label: actionLabel,
                      icon: actionIcon,
                      onTap: onActionTap,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 25,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.08,
                            ),
                          ),
                          if (badges.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: badges,
                            ),
                          ],
                          if (summary != null &&
                              summary!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              summary!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body2.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: bottomSpacing),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VccHeroActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const VccHeroActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VccHeroBadge extends StatelessWidget {
  final String label;

  const VccHeroBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.86),
        ),
      ),
    );
  }
}

class VccMetricSpec {
  final String value;
  final String label;
  final IconData icon;

  const VccMetricSpec({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class VccMetricsPanel extends StatelessWidget {
  final List<VccMetricSpec> items;

  const VccMetricsPanel({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return VccCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Expanded(
            child: Row(
              children: [
                if (index != 0)
                  Container(
                    width: 1,
                    height: 34,
                    color: AppColors.outlineVariant,
                  ),
                if (index != 0) const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        style: AppTextStyles.num2.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 13,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gray400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
