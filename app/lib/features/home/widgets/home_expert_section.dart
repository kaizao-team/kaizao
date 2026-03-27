import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/home_models.dart';
import 'home_section_header.dart';

class HomeExpertSection extends StatelessWidget {
  final List<RecommendedExpert> experts;
  final VoidCallback onRefresh;

  const HomeExpertSection({
    super.key,
    required this.experts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final visibleExperts = experts.take(3).toList();
    if (visibleExperts.isEmpty) return const SizedBox.shrink();

    final featuredExpert = visibleExperts.first;
    final supportingExperts = visibleExperts.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '高分团队',
          subtitle: '可直接继续沟通。',
          trailing: _RefreshButton(onTap: onRefresh),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _FeaturedExpertCard(expert: featuredExpert),
              if (supportingExperts.isNotEmpty) const SizedBox(height: 14),
              for (var index = 0;
                  index < supportingExperts.length;
                  index++) ...[
                _SupportingExpertRow(expert: supportingExperts[index]),
                if (index != supportingExperts.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedExpertCard extends StatelessWidget {
  final RecommendedExpert expert;

  const _FeaturedExpertCard({required this.expert});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      shadowColor: AppColors.black.withValues(alpha: 0.04),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: expert.id.isEmpty
            ? null
            : () => context.push('/profile/${expert.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _ExpertAvatar(
                    expert: expert,
                    size: 58,
                    avatarSize: VccAvatarSize.large,
                    showNewBadge: _isNewExpert(expert),
                  ),
                  const SizedBox(height: 8),
                  if (!_isNewExpert(expert)) _FeaturedTrustChip(expert: expert),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            expert.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _PriceLabel(rateText: _rateText(expert)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _headlineSkill(expert),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (expert.rating > 0) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.accentGold,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                expert.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        Text(
                          _experienceText(expert),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportingExpertRow extends StatelessWidget {
  final RecommendedExpert expert;

  const _SupportingExpertRow({required this.expert});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: expert.id.isEmpty
            ? null
            : () => context.push('/profile/${expert.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExpertAvatar(
                expert: expert,
                size: 44,
                avatarSize: VccAvatarSize.medium,
                showNewBadge: _isNewExpert(expert),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expert.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _headlineSkill(expert),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PriceLabel(
                    rateText: _rateText(expert),
                    compact: true,
                  ),
                  if (_supportingTrustText(expert).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _supportingTrustText(expert),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '刷新高分团队',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppColors.gray700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  final String rateText;
  final bool compact;

  const _PriceLabel({
    required this.rateText,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasHourly = rateText.endsWith('/h');
    final amount = hasHourly ? rateText.replaceAll('/h', '') : rateText;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: amount,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          if (hasHourly)
            TextSpan(
              text: '/h',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray500,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedTrustChip extends StatelessWidget {
  final RecommendedExpert expert;

  const _FeaturedTrustChip({required this.expert});

  @override
  Widget build(BuildContext context) {
    final label = expert.rating >= 4.8
        ? '优先沟通'
        : expert.completedOrders > 0
            ? '有经验'
            : '新加入';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.gray700,
        ),
      ),
    );
  }
}

class _ExpertAvatar extends StatelessWidget {
  final RecommendedExpert expert;
  final double size;
  final VccAvatarSize avatarSize;
  final bool showNewBadge;

  const _ExpertAvatar({
    required this.expert,
    required this.size,
    required this.avatarSize,
    required this.showNewBadge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gray100,
            ),
            alignment: Alignment.center,
            child: expert.avatarUrl != null && expert.avatarUrl!.isNotEmpty
                ? VccAvatar(
                    imageUrl: expert.avatarUrl,
                    size: avatarSize,
                    fallbackText: expert.nickname,
                  )
                : _MockPortrait(
                    size: size,
                    seed: expert.nickname,
                  ),
          ),
          if (showNewBadge)
            Positioned(
              top: size * 0.02,
              right: -2,
              child: Transform.rotate(
                angle: -6 * math.pi / 180,
                child: Container(
                  width: size >= 52 ? 22 : 20,
                  height: size >= 52 ? 18 : 16,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AppColors.black.withValues(alpha: 0.14),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(17, 17, 17, 0.06),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '新',
                    style: TextStyle(
                      fontSize: size >= 52 ? 9 : 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MockPortrait extends StatelessWidget {
  final double size;
  final String seed;

  const _MockPortrait({
    required this.size,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    const skin = Color(0xFFF1D3BC);
    const palettes = <({Color background, Color shirt, Color hair})>[
      (
        background: Color(0xFFE7ECE9),
        shirt: Color(0xFF6E8B7D),
        hair: Color(0xFF3A4A45),
      ),
      (
        background: Color(0xFFF0E9E2),
        shirt: Color(0xFF8A7064),
        hair: Color(0xFF4B3D35),
      ),
      (
        background: Color(0xFFE7EBF1),
        shirt: Color(0xFF6D7C96),
        hair: Color(0xFF32445C),
      ),
    ];
    final palette = palettes[seed.hashCode.abs() % palettes.length];

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          children: [
            Container(color: palette.background),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: size * 0.78,
                height: size * 0.38,
                decoration: BoxDecoration(
                  color: palette.shirt,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(size * 0.26),
                  ),
                ),
              ),
            ),
            Positioned(
              left: size * 0.28,
              top: size * 0.22,
              child: Container(
                width: size * 0.44,
                height: size * 0.44,
                decoration: const BoxDecoration(
                  color: skin,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: size * 0.24,
              top: size * 0.16,
              child: Container(
                width: size * 0.52,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: palette.hair,
                  borderRadius: BorderRadius.circular(size * 0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _headlineSkill(RecommendedExpert expert) {
  final value = expert.skill.trim();
  if (value.isNotEmpty) return value;
  const fallbackSkills = [
    '产品原型与项目梳理',
    '小程序与落地页交付',
    'AI 工作流与自动化搭建',
    '增长投放与内容包装',
  ];
  return fallbackSkills[expert.nickname.hashCode.abs() % fallbackSkills.length];
}

String _rateText(RecommendedExpert expert) {
  if (expert.hourlyRate > 0) return '¥${expert.hourlyRate}/h';
  return '面议';
}

String _experienceText(RecommendedExpert expert) {
  if (expert.completedOrders > 0) return '${expert.completedOrders}+ 项目经验';
  return '可先沟通';
}

String _supportingTrustText(RecommendedExpert expert) {
  if (expert.rating >= 4.8) return '优先沟通';
  if (expert.rating > 0) return '${expert.rating.toStringAsFixed(1)} 分';
  return '';
}

bool _isNewExpert(RecommendedExpert expert) {
  return expert.rating <= 0 && expert.completedOrders <= 0;
}
