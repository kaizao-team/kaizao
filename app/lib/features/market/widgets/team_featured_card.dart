import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/market_expert.dart';

/// Compact card for the Zone 2 horizontal scroll in team plaza.
/// Shows avatar + name + meta + tagline + skills. No redundant info.
class TeamFeaturedCard extends StatefulWidget {
  final MarketExpertItem expert;
  final VoidCallback? onTap;
  final bool highlight;

  const TeamFeaturedCard({
    super.key,
    required this.expert,
    this.onTap,
    this.highlight = false,
  });

  @override
  State<TeamFeaturedCard> createState() => _TeamFeaturedCardState();
}

class _TeamFeaturedCardState extends State<TeamFeaturedCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final e = widget.expert;
    final isHi = widget.highlight;
    final memberCount = e.memberCount < 1 ? 1 : e.memberCount;
    final skills = e.skills.take(3).toList();

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHi ? AppColors.accentLight : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isHi ? AppColors.accentMuted : AppColors.gray200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: avatar + name + meta
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipOval(
                      child: VccAvatar(
                        imageUrl: e.avatarUrl,
                        size: VccAvatarSize.medium,
                        fallbackText: e.displayName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.displayName,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$memberCount 人 · ${_domain(e)}',
                          style: AppTextStyles.overline.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isHi ? AppColors.accent : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Tagline
              Text(
                _tagline(e),
                style: AppTextStyles.caption.copyWith(
                  height: 1.5,
                  color: AppColors.gray600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Skills
              if (skills.isNotEmpty) ...[
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: skills.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isHi
                            ? AppColors.white
                            : AppColors.gray100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#$s',
                        style: AppTextStyles.overline.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isHi ? AppColors.accent : AppColors.gray600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              // Bottom
              Row(
                children: [
                  Text(
                    '$memberCount 人协作',
                    style: AppTextStyles.overline.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _vibeLabel(e),
                    style: AppTextStyles.overline.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isHi ? AppColors.accent : AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _domain(MarketExpertItem e) {
    if (e.skills.isNotEmpty) return e.skills.first;
    return '团队';
  }

  static String _tagline(MarketExpertItem e) {
    final tl = e.tagline.trim();
    if (tl.isNotEmpty) return tl;
    if (e.skills.length > 1) {
      return e.skills.take(3).map((s) => '#$s').join('  ');
    }
    return '团队介绍待补充';
  }

  static String _vibeLabel(MarketExpertItem e) {
    final vibe = e.vibeLevel?.trim() ?? '';
    if (vibe.isNotEmpty) return '⚡ $vibe';
    if (e.rating > 0) return '⭐ ${e.rating.toStringAsFixed(1)}';
    return '';
  }
}
