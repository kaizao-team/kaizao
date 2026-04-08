import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'vcc_avatar.dart';
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
  final Gradient? backgroundGradient;

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
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        gradient: backgroundGradient ??
            const LinearGradient(
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

class VccHeroAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;

  const VccHeroAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: VccAvatar(
          imageUrl: imageUrl?.trim(),
          size: VccAvatarSize.xlarge,
          fallbackText: fallbackText,
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
    return VccSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      child: IntrinsicHeight(
        child: Row(
          children: items.asMap().entries.expand((entry) {
            final index = entry.key;
            final item = entry.value;
            final children = <Widget>[
              Expanded(
                child: _MetricColumn(
                  item: item,
                  index: index,
                ),
              ),
            ];

            if (index != items.length - 1) {
              children.add(
                Center(
                  child: Container(
                    width: 1,
                    height: 36,
                    color: AppColors.outlineVariant,
                  ),
                ),
              );
            }

            return children;
          }).toList(),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final VccMetricSpec item;
  final int index;

  const _MetricColumn({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AnimatedMetricValue(
            value: item.value,
            staggerIndex: index,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 14,
                color: AppColors.gray400,
              ),
              const SizedBox(width: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedMetricValue extends StatefulWidget {
  final String value;
  final int staggerIndex;

  const _AnimatedMetricValue({
    required this.value,
    required this.staggerIndex,
  });

  @override
  State<_AnimatedMetricValue> createState() => _AnimatedMetricValueState();
}

class _AnimatedMetricValueState extends State<_AnimatedMetricValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  bool get _canAnimate => RegExp(r'\d').hasMatch(widget.value);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 960),
    );
    _restartAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedMetricValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.staggerIndex != widget.staggerIndex) {
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAnimation() {
    _delayTimer?.cancel();
    if (!_canAnimate) {
      _controller.value = 1;
      return;
    }

    _controller.reset();
    _delayTimer = Timer(
      Duration(milliseconds: widget.staggerIndex * 80),
      () {
        if (!mounted) return;
        _controller.forward();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.num2.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (!_canAnimate) {
      return Text(
        widget.value,
        textAlign: TextAlign.center,
        style: style,
      );
    }

    final chars = widget.value.split('');
    final digitIndexes = <int>[];
    for (var i = 0; i < chars.length; i++) {
      if (_isDigit(chars[i])) digitIndexes.add(i);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(chars.length, (charIndex) {
            final char = chars[charIndex];
            if (!_isDigit(char)) {
              return Text(char, style: style);
            }

            final digitOrder = digitIndexes.indexOf(charIndex);
            final start = digitOrder * 0.08;
            final interval = Interval(
              start.clamp(0.0, 0.72),
              1.0,
              curve: Curves.easeOutCubic,
            );

            return _RollingDigit(
              digit: int.parse(char),
              progress: interval.transform(_controller.value),
              style: style,
              loops: 2 + (digitOrder % 2),
            );
          }),
        );
      },
    );
  }

  bool _isDigit(String value) =>
      value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;
}

class _RollingDigit extends StatelessWidget {
  final int digit;
  final double progress;
  final TextStyle style;
  final int loops;

  const _RollingDigit({
    required this.digit,
    required this.progress,
    required this.style,
    required this.loops,
  });

  @override
  Widget build(BuildContext context) {
    final height = (style.fontSize ?? 22) * (style.height ?? 1.2);
    final width = (style.fontSize ?? 22) * 0.68;
    final travel = (loops * 10) + digit;
    final position = travel * progress;
    final whole = position.floor();
    final fraction = position - whole;
    final current = whole % 10;
    final next = (current + 1) % 10;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: height * 2,
          maxHeight: height * 2,
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: Offset(0, -fraction * height),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: height,
                  child: Center(child: Text('$current', style: style)),
                ),
                SizedBox(
                  height: height,
                  child: Center(child: Text('$next', style: style)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
