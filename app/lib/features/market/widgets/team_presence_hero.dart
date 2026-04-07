import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/market_expert.dart';

/// Zone 1: Overlapping avatars with tap-to-reveal status line.
class TeamPresenceHero extends StatefulWidget {
  final List<MarketExpertItem> experts;
  final ValueChanged<MarketExpertItem>? onTapExpert;

  const TeamPresenceHero({
    super.key,
    required this.experts,
    this.onTapExpert,
  });

  @override
  State<TeamPresenceHero> createState() => _TeamPresenceHeroState();
}

class _TeamPresenceHeroState extends State<TeamPresenceHero> {
  int? _selectedIndex;

  static const double _heroSize = 52.0;
  static const double _avatarSize = 42.0;
  static const double _overlap = 10.0;

  void _onTap(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final experts = widget.experts;
    final skillCount = experts.expand((e) => e.skills).toSet().length;
    final selected =
        _selectedIndex != null ? experts[_selectedIndex!] : null;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  '今天在场',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.gray400,
                  ),
                ),
                const Spacer(),
                Text(
                  '${experts.length} 支团队 · $skillCount 种技能',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Avatar strip — extra vertical padding for scale overflow
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              height: _heroSize,
              child: _buildAvatarStrip(experts),
            ),
          ),
          // Status line — animated reveal
          _StatusLine(expert: selected),
        ],
      ),
    );
  }

  Widget _buildAvatarStrip(List<MarketExpertItem> experts) {
    if (experts.isEmpty) return const SizedBox.shrink();

    final step = _avatarSize - _overlap;
    final totalWidth = _heroSize + (experts.length - 1) * step + 20;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: SizedBox(
        width: totalWidth,
        height: _heroSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < experts.length; i++)
              _buildPositionedAvatar(i, experts[i], step),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedAvatar(
    int index,
    MarketExpertItem expert,
    double step,
  ) {
    final isFirst = index == 0;
    final isSelected = _selectedIndex == index;
    final hasSelection = _selectedIndex != null;
    final size = isFirst ? _heroSize : _avatarSize;
    final left =
        isFirst ? 0.0 : _heroSize + (index - 1) * step - _overlap;
    final top = isFirst ? 0.0 : (_heroSize - _avatarSize) / 2;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _onTap(index),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: hasSelection && !isSelected ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.white,
                  width: isFirst ? 3 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.18)
                        : const Color(0x0C000000),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: VccAvatar(
                  imageUrl: expert.avatarUrl,
                  size: size > 50
                      ? VccAvatarSize.large
                      : VccAvatarSize.medium,
                  fallbackText: expert.displayName,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated status line that slides up when an expert is selected.
class _StatusLine extends StatelessWidget {
  final MarketExpertItem? expert;

  const _StatusLine({this.expert});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: expert == null
          ? const SizedBox(key: ValueKey('empty'), height: 8)
          : Padding(
              key: ValueKey(expert!.id),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  // Team name
                  Text(
                    expert!.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                  // Separator
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '·',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray300,
                      ),
                    ),
                  ),
                  // Skills
                  Expanded(
                    child: Text(
                      expert!.skills.map((s) => '#$s').join('  '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Member count
                  Text(
                    '${expert!.memberCount < 1 ? 1 : expert!.memberCount}人',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
