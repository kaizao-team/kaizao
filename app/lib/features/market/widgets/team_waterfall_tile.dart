import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/market_expert.dart';

class TeamWaterfallTile extends StatefulWidget {
  final MarketExpertItem expert;
  final VoidCallback? onTap;
  final bool tinted;

  const TeamWaterfallTile({
    super.key,
    required this.expert,
    this.onTap,
    this.tinted = false,
  });

  @override
  State<TeamWaterfallTile> createState() => _TeamWaterfallTileState();
}

class _TeamWaterfallTileState extends State<TeamWaterfallTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final expert = widget.expert;
    final skills = expert.skills.take(2).toList();
    final memberCount = expert.memberCount < 1 ? 1 : expert.memberCount;
    final isOnline = expert.vibePower > 500;

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.tinted ? const Color(0xFFF7F8FA) : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.tinted
                  ? AppColors.gray200
                  : const Color(0xFFECECEC),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              SizedBox(
                width: 36,
                height: 36,
                child: ClipOval(
                  child: VccAvatar(
                    imageUrl: expert.avatarUrl,
                    size: VccAvatarSize.medium,
                    fallbackText: expert.displayName,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Name
              Text(
                expert.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Tagline
              Text(
                _tagline(expert),
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.gray500,
                ),
                maxLines: _maxLines(expert),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Tags
              if (skills.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: skills
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '#$s',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 10),
              // Bottom row
              Row(
                children: [
                  Text(
                    '$memberCount人',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray400,
                    ),
                  ),
                  const Spacer(),
                  if (isOnline)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
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

  static String _tagline(MarketExpertItem expert) {
    final tl = expert.tagline.trim();
    if (tl.isNotEmpty) return tl;
    if (expert.skills.isNotEmpty) {
      return expert.skills.take(3).map((s) => '#$s').join('  ');
    }
    return '团队介绍待补充';
  }

  /// Vary max lines to create natural height differences in the waterfall.
  static int _maxLines(MarketExpertItem expert) {
    final taglineLen = expert.tagline.trim().length;
    if (taglineLen > 30) return 4;
    if (taglineLen > 15) return 3;
    return 2;
  }
}
