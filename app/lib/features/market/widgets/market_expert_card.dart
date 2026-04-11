import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/market_expert.dart';

enum MarketExpertCardVariant {
  feature,
  shelf,
  editorial,
}

class MarketExpertCard extends StatefulWidget {
  final MarketExpertItem expert;
  final VoidCallback? onTap;
  final MarketExpertCardVariant variant;
  final bool metaLeading;

  const MarketExpertCard({
    super.key,
    required this.expert,
    this.onTap,
    this.variant = MarketExpertCardVariant.editorial,
    this.metaLeading = true,
  });

  @override
  State<MarketExpertCard> createState() => _MarketExpertCardState();
}

class _MarketExpertCardState extends State<MarketExpertCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.985),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _tone.background,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _tone.border),
          ),
          child: Padding(
            padding: _padding,
            child: switch (widget.variant) {
              MarketExpertCardVariant.feature => _FeatureLayout(
                  expert: widget.expert,
                  tone: _tone,
                ),
              MarketExpertCardVariant.shelf => _ShelfLayout(
                  expert: widget.expert,
                  tone: _tone,
                ),
              MarketExpertCardVariant.editorial => _EditorialLayout(
                  expert: widget.expert,
                  tone: _tone,
                  metaLeading: widget.metaLeading,
                ),
            },
          ),
        ),
      ),
    );
  }

  _TeamCardTone get _tone => _toneForExpert(widget.expert);

  EdgeInsets get _padding {
    switch (widget.variant) {
      case MarketExpertCardVariant.feature:
        return const EdgeInsets.fromLTRB(22, 22, 22, 20);
      case MarketExpertCardVariant.shelf:
        return const EdgeInsets.fromLTRB(18, 18, 18, 18);
      case MarketExpertCardVariant.editorial:
        return const EdgeInsets.fromLTRB(18, 18, 18, 18);
    }
  }

  double get _radius {
    switch (widget.variant) {
      case MarketExpertCardVariant.feature:
        return AppRadius.xxxl;
      case MarketExpertCardVariant.shelf:
        return AppRadius.xxl;
      case MarketExpertCardVariant.editorial:
        return AppRadius.xxl;
    }
  }
}

class _FeatureLayout extends StatelessWidget {
  final MarketExpertItem expert;
  final _TeamCardTone tone;

  const _FeatureLayout({
    required this.expert,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final overlayText = _overlayLabel(expert);

    return Stack(
      children: [
        Positioned(
          right: 0,
          top: 8,
          child: IgnorePointer(
            child: Text(
              overlayText,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: tone.overlay,
                height: 1,
                letterSpacing: -2,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TeamOverline(
              expert: expert,
              tone: tone,
              emphasisLabel: '社区精选',
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Text(
                          expert.displayName,
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 30,
                            height: 1.08,
                            letterSpacing: -1.1,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 286),
                        child: Text(
                          _communityDescription(expert),
                          style: AppTextStyles.body1.copyWith(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.gray600,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _AvatarStack(
                  expert: expert,
                  tone: tone,
                  size: 76,
                  emphasizeCount: true,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _TeamTagRow(
              expert: expert,
              tone: tone,
              maxCount: 3,
            ),
            const SizedBox(height: 26),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _PrimaryMetric(
                    label: '成员',
                    value: '${_memberCount(expert)} 人',
                  ),
                ),
                const SizedBox(width: 18),
                if (expert.completedProjects > 0) ...[
                  _InlineMetric(
                    icon: Icons.work_outline_rounded,
                    label: '${expert.completedProjects}',
                  ),
                  const SizedBox(width: 12),
                ],
                if (expert.rating > 0) ...[
                  _InlineMetric(
                    icon: Icons.star_rounded,
                    label: expert.rating.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 12),
                ],
                _InlineMetric(
                  icon: Icons.bolt_rounded,
                  label: _badgeLabel(expert),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ShelfLayout extends StatelessWidget {
  final MarketExpertItem expert;
  final _TeamCardTone tone;

  const _ShelfLayout({
    required this.expert,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TeamOverline(
          expert: expert,
          tone: tone,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarStack(
              expert: expert,
              tone: tone,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                expert.displayName,
                style: AppTextStyles.h2.copyWith(
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Text(
            _communityDescription(expert),
            style: AppTextStyles.body2.copyWith(
              height: 1.55,
              color: AppColors.gray600,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 14),
        _TeamTagRow(
          expert: expert,
          tone: tone,
          maxCount: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_memberCount(expert)} 人协作',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _badgeLabel(expert),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: tone.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditorialLayout extends StatelessWidget {
  final MarketExpertItem expert;
  final _TeamCardTone tone;
  final bool metaLeading;

  const _EditorialLayout({
    required this.expert,
    required this.tone,
    required this.metaLeading,
  });

  @override
  Widget build(BuildContext context) {
    final metaRail = _TeamMetaRail(
      expert: expert,
      tone: tone,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (metaLeading) ...[
          metaRail,
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TeamOverline(
                expert: expert,
                tone: tone,
              ),
              const SizedBox(height: 14),
              Text(
                expert.displayName,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 23,
                  height: 1.16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                _communityDescription(expert),
                style: AppTextStyles.body2.copyWith(
                  height: 1.6,
                  color: AppColors.gray600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              _TeamTagRow(
                expert: expert,
                tone: tone,
                maxCount: 3,
              ),
            ],
          ),
        ),
        if (!metaLeading) ...[
          const SizedBox(width: 16),
          metaRail,
        ],
      ],
    );
  }
}

class _TeamOverline extends StatelessWidget {
  final MarketExpertItem expert;
  final _TeamCardTone tone;
  final String? emphasisLabel;

  const _TeamOverline({
    required this.expert,
    required this.tone,
    this.emphasisLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tone.pillBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_rounded,
                size: 13,
                color: tone.accent,
              ),
              const SizedBox(width: 6),
              Text(
                emphasisLabel ?? _badgeLabel(expert),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tone.accent,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${_memberCount(expert)} 人协作',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TeamTagRow extends StatelessWidget {
  final MarketExpertItem expert;
  final _TeamCardTone tone;
  final int maxCount;

  const _TeamTagRow({
    required this.expert,
    required this.tone,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final tags = _tagLabels(expert, maxCount: maxCount);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tone.border),
              ),
              child: Text(
                tag,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TeamMetaRail extends StatelessWidget {
  final MarketExpertItem expert;
  final _TeamCardTone tone;

  const _TeamMetaRail({
    required this.expert,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarStack(
            expert: expert,
            tone: tone,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            '${_memberCount(expert)} 人协作',
            style: AppTextStyles.overline.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _metaCaption(expert),
            style: AppTextStyles.caption.copyWith(
              height: 1.35,
              color: AppColors.gray500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final MarketExpertItem expert;
  final _TeamCardTone tone;
  final double size;
  final bool emphasizeCount;

  const _AvatarStack({
    required this.expert,
    required this.tone,
    required this.size,
    this.emphasizeCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = emphasizeCount ? '${_memberCount(expert)} 人' : _badgeLabel(expert);

    return SizedBox(
      width: size + 14,
      height: size + 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.86),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: VccAvatar(
                imageUrl: expert.avatarUrl,
                size: size >= 60 ? VccAvatarSize.large : VccAvatarSize.medium,
                fallbackText: expert.displayName,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tone.border),
              ),
              child: Text(
                badge,
                style: AppTextStyles.overline.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tone.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PrimaryMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineMetric({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.gray400,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _TeamCardTone {
  final Color background;
  final Color border;
  final Color pillBackground;
  final Color accent;
  final Color overlay;

  const _TeamCardTone({
    required this.background,
    required this.border,
    required this.pillBackground,
    required this.accent,
    required this.overlay,
  });
}

_TeamCardTone _toneForExpert(MarketExpertItem expert) {
  if (expert.vibePower >= 900) {
    return const _TeamCardTone(
      background: AppColors.accentLight,
      border: AppColors.accentMuted,
      pillBackground: AppColors.white,
      accent: AppColors.accentDark,
      overlay: AppColors.accentMuted,
    );
  }

  if (expert.skills.length >= 3) {
    return const _TeamCardTone(
      background: AppColors.surfaceAlt,
      border: AppColors.gray200,
      pillBackground: AppColors.white,
      accent: AppColors.black,
      overlay: Color(0xFFE8EBEF),
    );
  }

  return const _TeamCardTone(
    background: AppColors.gray50,
    border: AppColors.gray200,
    pillBackground: AppColors.white,
    accent: AppColors.black,
    overlay: AppColors.surfaceStrong,
  );
}

String _badgeLabel(MarketExpertItem expert) {
  final vibe = expert.vibeLevel?.trim() ?? '';
  if (vibe.isNotEmpty) {
    return vibe;
  }
  if (expert.rating > 0) {
    return '评分 ${expert.rating.toStringAsFixed(1)}';
  }
  return '公开团队';
}

String _overlayLabel(MarketExpertItem expert) {
  final vibe = expert.vibeLevel?.trim();
  if (vibe != null && vibe.isNotEmpty) {
    return vibe.toUpperCase();
  }
  if (expert.skills.isNotEmpty) {
    return expert.skills.first.toUpperCase();
  }
  return 'TEAM';
}

String _communityDescription(MarketExpertItem expert) {
  final tagline = expert.tagline.trim();
  if (tagline.isNotEmpty) {
    return tagline;
  }
  if (expert.skills.isNotEmpty) {
    return _skillHashtags(expert, maxCount: 3);
  }
  return '团队介绍待补充';
}

String _metaCaption(MarketExpertItem expert) {
  if (expert.hourlyRate > 0) {
    return _rateLabel(expert);
  }
  if (expert.completedProjects > 0) {
    return '${expert.completedProjects} 项目';
  }
  return _badgeLabel(expert);
}

List<String> _tagLabels(MarketExpertItem expert, {required int maxCount}) {
  if (expert.skills.isNotEmpty) {
    return expert.skills.take(maxCount).map((skill) => '#$skill').toList();
  }

  final tags = <String>[
    '${_memberCount(expert)} 人协作',
    _badgeLabel(expert),
    if (expert.completedProjects > 0) '${expert.completedProjects} 项目',
  ];
  return tags.take(maxCount).toList(growable: false);
}

String _skillHashtags(MarketExpertItem expert, {required int maxCount}) {
  if (expert.skills.isEmpty) {
    return '';
  }
  return expert.skills.take(maxCount).map((skill) => '#$skill').join('  ');
}

String _rateLabel(MarketExpertItem expert) {
  if (expert.hourlyRate <= 0) {
    return '面议';
  }
  return '¥${expert.hourlyRate}/h';
}

int _memberCount(MarketExpertItem expert) {
  return expert.memberCount < 1 ? 1 : expert.memberCount;
}
