import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Editorial Compact collapsing header for tab pages.
///
/// The title physically shrinks and moves up as the user scrolls,
/// matching the iOS large-title behavior. Subtitle and trailing
/// widgets fade out during the collapse.
class VccEditorialAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double expandedHeight;
  final Color? backgroundColor;

  const VccEditorialAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.expandedHeight = 80,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _EditorialHeaderDelegate(
        topPadding: topPadding,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        expandedHeight: expandedHeight,
        backgroundColor: backgroundColor ?? AppColors.surface,
      ),
    );
  }
}

class _EditorialHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _toolbarHeight = 48;
  static const double _expandedTitleSize = 30;
  static const double _collapsedTitleSize = 18;

  final double topPadding;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double expandedHeight;
  final Color backgroundColor;

  const _EditorialHeaderDelegate({
    required this.topPadding,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.expandedHeight,
    required this.backgroundColor,
  });

  @override
  double get minExtent => topPadding + _toolbarHeight;

  @override
  double get maxExtent => topPadding + expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final progress = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    // Title smoothly shrinks and moves up
    final titleTop = lerpDouble(topPadding + 12, topPadding + 14, progress)!;
    final titleSize = lerpDouble(_expandedTitleSize, _collapsedTitleSize, progress)!;
    final titleWeight =
        FontWeight.lerp(FontWeight.w700, FontWeight.w600, progress) ??
            FontWeight.w600;

    // Subtitle fades out in first 65% of scroll
    final subtitleOpacity =
        1 - Curves.easeOut.transform((progress / 0.65).clamp(0.0, 1.0));
    final subtitleTop = lerpDouble(topPadding + 48, topPadding + 42, progress)!;

    // Trailing fades out in first 50-65% of scroll
    final trailingOpacity =
        1 - Curves.easeOut.transform(((progress - 0.15) / 0.5).clamp(0.0, 1.0));

    // Divider appears at full collapse
    final dividerOpacity =
        Curves.easeOut.transform(((progress - 0.82) / 0.18).clamp(0.0, 1.0));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: dividerOpacity > 0
            ? Border(
                bottom: BorderSide(
                  color: AppColors.gray200.withValues(alpha: dividerOpacity),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Trailing widgets (top-right, fades out)
          if (trailing != null)
            Positioned(
              top: topPadding + 10,
              right: 20,
              child: IgnorePointer(
                ignoring: trailingOpacity < 0.1,
                child: Opacity(
                  opacity: trailingOpacity,
                  child: trailing!,
                ),
              ),
            ),

          // Title — physically moves and shrinks
          Positioned(
            top: titleTop,
            left: 20,
            right: trailing != null ? 132 : 20,
            child: IgnorePointer(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: titleWeight,
                  height: 1,
                  letterSpacing: -0.8,
                  color: AppColors.black,
                ),
              ),
            ),
          ),

          // Subtitle — fades out
          if (subtitle != null)
            Positioned(
              top: subtitleTop,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: subtitleOpacity,
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _EditorialHeaderDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding ||
        title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        trailing != oldDelegate.trailing ||
        expandedHeight != oldDelegate.expandedHeight ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
