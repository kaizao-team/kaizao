import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/market_filter.dart';

enum MarketProjectCardVariant {
  feature,
  shelf,
  editorial,
}

class MarketProjectCard extends StatefulWidget {
  final MarketProjectItem project;
  final VoidCallback? onTap;
  final bool isExpert;
  final String? aiTip;
  final MarketProjectCardVariant variant;
  final bool metaLeading;

  const MarketProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.isExpert = false,
    this.aiTip,
    this.variant = MarketProjectCardVariant.editorial,
    this.metaLeading = true,
  });

  @override
  State<MarketProjectCard> createState() => _MarketProjectCardState();
}

class _MarketProjectCardState extends State<MarketProjectCard> {
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
              MarketProjectCardVariant.feature => _FeatureLayout(
                  project: widget.project,
                  tone: _tone,
                  isExpert: widget.isExpert,
                  aiTip: widget.aiTip,
                ),
              MarketProjectCardVariant.shelf => _ShelfLayout(
                  project: widget.project,
                  tone: _tone,
                  isExpert: widget.isExpert,
                  aiTip: widget.aiTip,
                ),
              MarketProjectCardVariant.editorial => _EditorialLayout(
                  project: widget.project,
                  tone: _tone,
                  isExpert: widget.isExpert,
                  aiTip: widget.aiTip,
                  metaLeading: widget.metaLeading,
                ),
            },
          ),
        ),
      ),
    );
  }

  _MarketCardTone get _tone => _toneForCategory(widget.project.category);

  EdgeInsets get _padding {
    switch (widget.variant) {
      case MarketProjectCardVariant.feature:
        return const EdgeInsets.fromLTRB(22, 22, 22, 20);
      case MarketProjectCardVariant.shelf:
        return const EdgeInsets.fromLTRB(18, 18, 18, 18);
      case MarketProjectCardVariant.editorial:
        return const EdgeInsets.fromLTRB(18, 18, 18, 18);
    }
  }

  double get _radius {
    switch (widget.variant) {
      case MarketProjectCardVariant.feature:
        return 30;
      case MarketProjectCardVariant.shelf:
        return 26;
      case MarketProjectCardVariant.editorial:
        return 24;
    }
  }
}

class _FeatureLayout extends StatelessWidget {
  final MarketProjectItem project;
  final _MarketCardTone tone;
  final bool isExpert;
  final String? aiTip;

  const _FeatureLayout({
    required this.project,
    required this.tone,
    required this.isExpert,
    required this.aiTip,
  });

  @override
  Widget build(BuildContext context) {
    final overlayText = project.categoryName;

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
            _ProjectOverline(
              project: project,
              tone: tone,
              emphasisLabel: '广场精选',
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                project.title,
                style: const TextStyle(
                  fontSize: 31,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  color: AppColors.black,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                project.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.gray600,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 18),
            _ProjectTagRow(
              project: project,
              tone: tone,
              maxCount: 3,
            ),
            if (isExpert && aiTip != null) ...[
              const SizedBox(height: 14),
              Text(
                aiTip!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: tone.accent,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 26),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _PrimaryMetric(
                    label: '预算',
                    value: project.budgetDisplay,
                  ),
                ),
                const SizedBox(width: 18),
                _InlineMetric(
                  icon: Icons.visibility_outlined,
                  label: '${project.viewCount}',
                ),
                const SizedBox(width: 12),
                _InlineMetric(
                  icon: Icons.gavel_outlined,
                  label: '${project.bidCount}',
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
  final MarketProjectItem project;
  final _MarketCardTone tone;
  final bool isExpert;
  final String? aiTip;

  const _ShelfLayout({
    required this.project,
    required this.tone,
    required this.isExpert,
    required this.aiTip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProjectOverline(
          project: project,
          tone: tone,
        ),
        const SizedBox(height: 18),
        Text(
          project.title,
          style: const TextStyle(
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: AppColors.black,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Text(
            project.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.gray600,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 14),
        _ProjectTagRow(
          project: project,
          tone: tone,
          maxCount: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                project.budgetDisplay,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
            if (isExpert && project.matchScore != null)
              Text(
                '匹配 ${project.matchScore}%',
                style: TextStyle(
                  fontSize: 12,
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
  final MarketProjectItem project;
  final _MarketCardTone tone;
  final bool isExpert;
  final String? aiTip;
  final bool metaLeading;

  const _EditorialLayout({
    required this.project,
    required this.tone,
    required this.isExpert,
    required this.aiTip,
    required this.metaLeading,
  });

  @override
  Widget build(BuildContext context) {
    final metaRail = _MetaRail(
      project: project,
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
              _ProjectOverline(
                project: project,
                tone: tone,
              ),
              const SizedBox(height: 14),
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 23,
                  height: 1.16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: AppColors.black,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                project.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.gray600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              _ProjectTagRow(
                project: project,
                tone: tone,
                maxCount: 3,
              ),
              if (isExpert && aiTip != null) ...[
                const SizedBox(height: 12),
                Text(
                  aiTip!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: tone.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

class _ProjectOverline extends StatelessWidget {
  final MarketProjectItem project;
  final _MarketCardTone tone;
  final String? emphasisLabel;

  const _ProjectOverline({
    required this.project,
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
                _iconForCategory(project.category),
                size: 13,
                color: tone.accent,
              ),
              const SizedBox(width: 6),
              Text(
                emphasisLabel ?? project.categoryName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tone.accent,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          _formatTimeAgo(project.createdAt),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }
}

class _ProjectTagRow extends StatelessWidget {
  final MarketProjectItem project;
  final _MarketCardTone tone;
  final int maxCount;

  const _ProjectTagRow({
    required this.project,
    required this.tone,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final items =
        project.techRequirements.take(maxCount).toList(growable: false);
    if (items.isEmpty) {
      return Text(
        project.ownerName?.isNotEmpty == true ? project.ownerName! : '等待更多项目细节',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.gray500,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
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
                style: const TextStyle(
                  fontSize: 12,
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

class _MetaRail extends StatelessWidget {
  final MarketProjectItem project;
  final _MarketCardTone tone;

  const _MetaRail({
    required this.project,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '预算',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.budgetDisplay,
            style: const TextStyle(
              fontSize: 17,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 18),
          _InlineMetric(
            icon: Icons.visibility_outlined,
            label: '${project.viewCount}',
          ),
          const SizedBox(height: 8),
          _InlineMetric(
            icon: Icons.gavel_outlined,
            label: '${project.bidCount}',
          ),
          if (project.ownerName?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _InlineMetric(
              icon: Icons.person_outline,
              label: project.ownerName!,
            ),
          ],
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: AppColors.black,
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
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MarketCardTone {
  final Color background;
  final Color border;
  final Color accent;
  final Color pillBackground;
  final Color overlay;

  const _MarketCardTone({
    required this.background,
    required this.border,
    required this.accent,
    required this.pillBackground,
    required this.overlay,
  });
}

_MarketCardTone _toneForCategory(String category) {
  switch (category) {
    case 'visual':
      return const _MarketCardTone(
        background: Color(0xFFF8F3FF),
        border: Color(0xFFE9DDFB),
        accent: AppColors.accentDark,
        pillBackground: Color(0xFFF1E6FF),
        overlay: Color(0x80E7D9FF),
      );
    case 'data':
      return const _MarketCardTone(
        background: Color(0xFFF3F8FF),
        border: Color(0xFFD9E8FF),
        accent: Color(0xFF2458A6),
        pillBackground: Color(0xFFE7F0FF),
        overlay: Color(0x807AC0FF),
      );
    case 'solution':
      return const _MarketCardTone(
        background: Color(0xFFFFF8EF),
        border: Color(0xFFF4E1C9),
        accent: Color(0xFFB86A16),
        pillBackground: Color(0xFFFFEFD7),
        overlay: Color(0x80FFD59B),
      );
    case 'dev':
    default:
      return const _MarketCardTone(
        background: Color(0xFFF7F7F7),
        border: Color(0xFFE6E6E6),
        accent: AppColors.black,
        pillBackground: Color(0xFFFFFFFF),
        overlay: Color(0x13000000),
      );
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'visual':
      return Icons.palette_outlined;
    case 'data':
      return Icons.auto_graph_outlined;
    case 'solution':
      return Icons.route_outlined;
    case 'dev':
    default:
      return Icons.code_rounded;
  }
}

String _formatTimeAgo(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${time.month}月${time.day}日';
}
