import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'vcc_button.dart';

class VccFlowScaffold extends StatelessWidget {
  final int stepIndex;
  final int stepCount;
  final List<String> stepLabels;
  final String title;
  final String subtitle;
  final String? compactTitle;
  final String? titleTag;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final List<Widget> slivers;
  final Widget? footer;
  final double footerHeight;
  final ScrollController? scrollController;
  final Color backgroundColor;

  const VccFlowScaffold({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.stepLabels,
    required this.title,
    required this.subtitle,
    required this.slivers,
    this.compactTitle,
    this.titleTag,
    this.onBack,
    this.onClose,
    this.footer,
    this.footerHeight = 0,
    this.scrollController,
    this.backgroundColor = AppColors.onboardingBackground,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _VccFlowHeaderDelegate(
                    topPadding: topPadding,
                    stepIndex: stepIndex,
                    stepCount: stepCount,
                    stepLabels: stepLabels,
                    title: title,
                    subtitle: subtitle,
                    compactTitle: compactTitle ?? title,
                    titleTag: titleTag,
                    onBack: onBack,
                    onClose: onClose,
                    backgroundColor: backgroundColor,
                  ),
                ),
                ...slivers,
                if (footer != null)
                  SliverToBoxAdapter(
                    child: SizedBox(height: footerHeight + bottomPadding),
                  ),
              ],
            ),
          ),
          if (footer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: footer!,
            ),
        ],
      ),
    );
  }
}

class VccFlowFooterShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const VccFlowFooterShell({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.onboardingSurface,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(17, 17, 17, 0.06),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}

class VccFlowFooterBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const VccFlowFooterBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return VccFlowFooterShell(
      child: VccButton(
        text: label,
        onPressed: onPressed,
        isLoading: isLoading,
      ),
    );
  }
}

class VccFlowStepIndicator extends StatelessWidget {
  final int stepIndex;
  final int stepCount;
  final List<String> labels;
  final bool compact;

  const VccFlowStepIndicator({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.labels,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactIndicator(
        stepIndex: stepIndex,
        stepCount: stepCount,
        labels: labels,
      );
    }

    return _ExpandedIndicator(
      stepIndex: stepIndex,
      stepCount: stepCount,
      labels: labels,
    );
  }
}

class _ExpandedIndicator extends StatelessWidget {
  final int stepIndex;
  final int stepCount;
  final List<String> labels;

  const _ExpandedIndicator({
    required this.stepIndex,
    required this.stepCount,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final safeStepCount = _resolvedStepCount(stepCount);
    final currentStep = _resolvedStepIndex(stepIndex, stepCount) + 1;
    final progress = _resolvedStepProgress(stepIndex, stepCount);
    final currentLabel = _currentStepLabel(
      stepIndex: stepIndex,
      stepCount: stepCount,
      labels: labels,
    );

    return Semantics(
      label: 'Step $currentStep of $safeStepCount'
          '${currentLabel.isEmpty ? '' : ': $currentLabel'}',
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.onboardingSurface,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: [
            Text(
              'STEP',
              style: AppTextStyles.onboardingMeta.copyWith(
                color: AppColors.gray400,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _IndicatorProgressBar(
                progress: progress,
                height: 4,
                trackColor: AppColors.gray200,
                fillColor: AppColors.gray800,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$currentStep / $safeStepCount',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactIndicator extends StatelessWidget {
  final int stepIndex;
  final int stepCount;
  final List<String> labels;

  const _CompactIndicator({
    required this.stepIndex,
    required this.stepCount,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final safeStepCount = _resolvedStepCount(stepCount);
    final currentStep = _resolvedStepIndex(stepIndex, stepCount) + 1;
    final progress = _resolvedStepProgress(stepIndex, stepCount);
    final currentLabel = _currentStepLabel(
      stepIndex: stepIndex,
      stepCount: stepCount,
      labels: labels,
    );

    return Semantics(
      label: 'Step $currentStep of $safeStepCount'
          '${currentLabel.isEmpty ? '' : ': $currentLabel'}',
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              child: _IndicatorProgressBar(
                progress: progress,
                height: 3,
                trackColor: AppColors.gray300,
                fillColor: AppColors.gray800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$currentStep/$safeStepCount',
              style: AppTextStyles.onboardingMeta.copyWith(
                color: AppColors.gray800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color trackColor;
  final Color fillColor;

  const _IndicatorProgressBar({
    required this.progress,
    required this.height,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clampedProgress = progress.clamp(0.0, 1.0);
        final width = constraints.maxWidth * clampedProgress;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: height,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            AnimatedContainer(
              duration: Duration.zero,
              height: height,
              width: width,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VccFlowHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _toolbarHeight = 48;
  static const double _expandedHeight = 160;
  static const double _actionInset = 12;
  static const double _contentInset = 20;
  static const double _actionSize = 40;
  static const double _toolbarGap = 12;
  static const double _titleToCompactGap = 12;
  static const double _compactIndicatorReserveWidth = 84;
  static const double _expandedTitleFontSize = 20;
  static const double _collapsedTitleFontSize = 15;
  static const double _expandedSubtitleFontSize = 13;

  final double topPadding;
  final int stepIndex;
  final int stepCount;
  final List<String> stepLabels;
  final String title;
  final String subtitle;
  final String compactTitle;
  final String? titleTag;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Color backgroundColor;

  const _VccFlowHeaderDelegate({
    required this.topPadding,
    required this.stepIndex,
    required this.stepCount,
    required this.stepLabels,
    required this.title,
    required this.subtitle,
    required this.compactTitle,
    required this.titleTag,
    required this.onBack,
    required this.onClose,
    required this.backgroundColor,
  });

  @override
  double get minExtent => topPadding + _toolbarHeight;

  @override
  double get maxExtent => topPadding + _expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final progress = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final subtitleOpacity =
        1 - Curves.easeOut.transform((progress / 0.3).clamp(0.0, 1.0));
    final expandedIndicatorOpacity =
        1 - Curves.easeOut.transform(((progress - 0.2) / 0.4).clamp(0.0, 1.0));
    final compactIndicatorOpacity =
        Curves.easeOut.transform(((progress - 0.4) / 0.4).clamp(0.0, 1.0));
    // Immersive design: no shadow, only a subtle divider at full collapse.
    final dividerOpacity =
        Curves.easeOut.transform(((progress - 0.85) / 0.15).clamp(0.0, 1.0));
    final compactTitleOpacity = compactTitle == title
        ? 0.0
        : Curves.easeOut.transform(((progress - 0.68) / 0.22).clamp(0.0, 1.0));
    final movingTitleOpacity =
        compactTitle == title ? 1.0 : (1 - compactTitleOpacity).clamp(0.0, 1.0);

    // Immersive: background stays page color, no lerp to white surface.
    final background = backgroundColor;
    final toolbarTop = topPadding + ((_toolbarHeight - _actionSize) / 2);
    final compactIndicatorTop = topPadding + ((_toolbarHeight - 28) / 2);
    final expandedTitleTop = topPadding + _toolbarHeight + 4;
    final collapsedTitleTop = topPadding + 15;
    final titleTop = lerpDouble(expandedTitleTop, collapsedTitleTop, progress)!;
    final titleLeft = lerpDouble(
      _contentInset,
      _actionInset + _actionSize + _toolbarGap,
      progress,
    )!;
    final titleRight = lerpDouble(
      _actionInset + _actionSize + _toolbarGap,
      _actionInset +
          _actionSize +
          _toolbarGap +
          _compactIndicatorReserveWidth +
          _titleToCompactGap,
      progress,
    )!;
    final titleFontSize = lerpDouble(
      _expandedTitleFontSize,
      _collapsedTitleFontSize,
      progress,
    )!;
    final titleWeight =
        FontWeight.lerp(FontWeight.w700, FontWeight.w600, progress) ??
            FontWeight.w600;
    final hasTitleTag = titleTag?.trim().isNotEmpty == true;

    final subtitleTop = expandedTitleTop + 28;
    final expandedIndicatorTop = subtitleTop + 42;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        // Immersive: thin bottom border instead of shadow/solid bar
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
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: toolbarTop,
            left: _actionInset,
            child: _HeaderActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: onBack,
            ),
          ),
          Positioned(
            top: toolbarTop,
            right: _actionInset,
            child: _HeaderActionButton(
              icon: Icons.close_rounded,
              onPressed: onClose,
            ),
          ),
          Positioned(
            top: titleTop,
            left: titleLeft,
            right: titleRight,
            child: IgnorePointer(
              child: Opacity(
                opacity: movingTitleOpacity,
                child: _HeaderTitleRow(
                  title: title,
                  titleStyle: AppTextStyles.h2.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: titleWeight,
                    height: 1.18,
                    color: AppColors.gray800,
                  ),
                  titleTag: hasTitleTag ? titleTag : null,
                  compact: progress > 0.55,
                ),
              ),
            ),
          ),
          if (compactTitle != title)
            Positioned(
              top: collapsedTitleTop,
              left: _actionInset + _actionSize + _toolbarGap,
              right: _actionInset +
                  _actionSize +
                  _toolbarGap +
                  _compactIndicatorReserveWidth +
                  _titleToCompactGap,
              child: IgnorePointer(
                child: Opacity(
                  opacity: compactTitleOpacity,
                  child: _HeaderTitleRow(
                    title: compactTitle,
                    titleStyle: AppTextStyles.h3.copyWith(
                      fontSize: _collapsedTitleFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppColors.gray800,
                    ),
                    titleTag: hasTitleTag ? titleTag : null,
                    compact: true,
                  ),
                ),
              ),
            ),
          Positioned(
            top: lerpDouble(subtitleTop, subtitleTop - 8, progress)!,
            left: _contentInset,
            right: _actionInset + _actionSize + _toolbarGap,
            child: IgnorePointer(
              child: Opacity(
                opacity: subtitleOpacity,
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body2.copyWith(
                    fontSize: _expandedSubtitleFontSize,
                    height: 1.35,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: lerpDouble(
              expandedIndicatorTop,
              expandedIndicatorTop - 10,
              progress,
            )!,
            left: _contentInset,
            right: _contentInset,
            child: IgnorePointer(
              child: Opacity(
                opacity: expandedIndicatorOpacity,
                child: VccFlowStepIndicator(
                  stepIndex: stepIndex,
                  stepCount: stepCount,
                  labels: stepLabels,
                ),
              ),
            ),
          ),
          Positioned(
            top: compactIndicatorTop,
            right: _actionInset + _actionSize + 8,
            child: IgnorePointer(
              child: Opacity(
                opacity: compactIndicatorOpacity,
                child: Transform.translate(
                  offset: Offset(10 * (1 - compactIndicatorOpacity), 0),
                  child: VccFlowStepIndicator(
                    stepIndex: stepIndex,
                    stepCount: stepCount,
                    labels: stepLabels,
                    compact: true,
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
  bool shouldRebuild(covariant _VccFlowHeaderDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding ||
        stepIndex != oldDelegate.stepIndex ||
        stepCount != oldDelegate.stepCount ||
        !listEquals(stepLabels, oldDelegate.stepLabels) ||
        title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        compactTitle != oldDelegate.compactTitle ||
        titleTag != oldDelegate.titleTag ||
        onBack != oldDelegate.onBack ||
        onClose != oldDelegate.onClose ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

class _HeaderTitleRow extends StatelessWidget {
  final String title;
  final TextStyle titleStyle;
  final String? titleTag;
  final bool compact;

  const _HeaderTitleRow({
    required this.title,
    required this.titleStyle,
    required this.titleTag,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        if (titleTag != null) ...[
          SizedBox(width: compact ? 8 : 10),
          _HeaderTitleTag(
            label: titleTag!,
            compact: compact,
          ),
        ],
      ],
    );
  }
}

class _HeaderTitleTag extends StatelessWidget {
  final String label;
  final bool compact;

  const _HeaderTitleTag({
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.gray300,
        ),
        boxShadow: compact
            ? null
            : const [
                BoxShadow(
                  color: Color.fromRGBO(17, 17, 17, 0.04),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            label,
            style:
                (compact ? AppTextStyles.caption : AppTextStyles.onboardingMeta)
                    .copyWith(
              color: AppColors.gray800,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? 0 : 0.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _HeaderActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDisabled ? AppColors.gray100 : AppColors.onboardingSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDisabled ? AppColors.gray400 : AppColors.black,
          ),
        ),
      ),
    );
  }
}

int _resolvedStepCount(int stepCount) {
  return stepCount <= 0 ? 1 : stepCount;
}

int _resolvedStepIndex(int stepIndex, int stepCount) {
  final safeStepCount = _resolvedStepCount(stepCount);
  if (stepIndex < 0) {
    return 0;
  }
  if (stepIndex >= safeStepCount) {
    return safeStepCount - 1;
  }
  return stepIndex;
}

double _resolvedStepProgress(int stepIndex, int stepCount) {
  final safeStepCount = _resolvedStepCount(stepCount);
  if (safeStepCount <= 1) {
    return 1.0;
  }
  final currentStep = _resolvedStepIndex(stepIndex, stepCount) + 1;
  return currentStep / safeStepCount;
}

String _currentStepLabel({
  required int stepIndex,
  required int stepCount,
  required List<String> labels,
}) {
  if (labels.isEmpty) {
    return '';
  }

  final resolvedIndex = _resolvedStepIndex(stepIndex, stepCount);
  if (resolvedIndex >= labels.length) {
    return labels.last;
  }

  return labels[resolvedIndex];
}
