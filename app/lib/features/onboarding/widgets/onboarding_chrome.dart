import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

bool onboardingReduceMotionOf(BuildContext context) {
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

class OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final List<String> stepLabels;
  final Widget child;
  final VoidCallback? onBack;
  final String primaryActionText;
  final VoidCallback? onPrimaryAction;
  final bool isPrimaryLoading;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final EdgeInsetsGeometry contentPadding;

  const OnboardingScaffold({
    super.key,
    required this.currentStep,
    this.stepLabels = const ['资料', '创建需求', '填写信息', '完成'],
    required this.child,
    required this.primaryActionText,
    required this.onPrimaryAction,
    this.onBack,
    this.isPrimaryLoading = false,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 12, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _AnimatedBackdrop(step: currentStep),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: OnboardingHeader(
                    currentStep: currentStep,
                    labels: stepLabels,
                    onBack: onBack,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: contentPadding,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, constraints.maxHeight - 24),
                          ),
                          child: OnboardingStage(child: child),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      OnboardingPrimaryButton(
                        text: primaryActionText,
                        onPressed: onPrimaryAction,
                        isLoading: isPrimaryLoading,
                      ),
                      if (secondaryActionText != null) ...[
                        const SizedBox(height: 12),
                        OnboardingSecondaryAction(
                          text: secondaryActionText!,
                          onTap: onSecondaryAction,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final VoidCallback? onBack;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    required this.labels,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onBack,
                  splashRadius: 18,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: AppColors.black,
                  ),
                ),
              ),
              const Text('Kaizao', style: AppTextStyles.onboardingWordmark),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ProgressRail(
          currentStep: currentStep,
          labels: labels,
        ),
      ],
    );
  }
}

class _ProgressRail extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _ProgressRail({
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / labels.length;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.onboardingHairline.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: constraints.maxWidth * progress),
                  duration: AppDurations.progress,
                  curve: AppCurves.standard,
                  builder: (context, width, child) {
                    return SizedBox(
                      width: width,
                      child: child,
                    );
                  },
                  child: OnboardingSheen(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    duration: const Duration(milliseconds: 2200),
                    sheenWidthFactor: 0.32,
                    highlightColor: AppColors.white.withValues(alpha: 0.46),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.onboardingPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(17, 17, 17, 0.12),
                            blurRadius: 10,
                            spreadRadius: 0.2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(labels.length, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;
            final numberColor = isActive
                ? AppColors.onboardingPrimary
                : (isCompleted ? AppColors.black : AppColors.gray400);
            final labelColor = isActive
                ? AppColors.black
                : (isCompleted
                    ? AppColors.onboardingMutedText
                    : AppColors.gray400);

            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '0${index + 1}',
                    style: AppTextStyles.onboardingMeta.copyWith(
                      color: numberColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class OnboardingPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const OnboardingPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<OnboardingPrimaryButton> createState() =>
      _OnboardingPrimaryButtonState();
}

class _OnboardingPrimaryButtonState extends State<OnboardingPrimaryButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final bgColor = _disabled
        ? AppColors.gray300
        : (_pressed
            ? AppColors.onboardingPrimaryPressed
            : AppColors.onboardingPrimary);

    return GestureDetector(
      onTap: _disabled ? null : widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: AppCurves.standard,
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _disabled ? const [] : AppShadows.onboardingLift,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.text,
                        style: AppTextStyles.button1,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class OnboardingSecondaryAction extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const OnboardingSecondaryAction({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.onboardingMutedText,
          ),
        ),
      ),
    );
  }
}

class OnboardingStage extends StatefulWidget {
  final Widget child;

  const OnboardingStage({super.key, required this.child});

  @override
  State<OnboardingStage> createState() => _OnboardingStageState();
}

class _OnboardingStageState extends State<OnboardingStage> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = onboardingReduceMotionOf(context);
    final visible = reduceMotion ? true : _visible;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
      curve: AppCurves.standard,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.035),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 380),
        curve: AppCurves.standard,
        child: AnimatedScale(
          scale: visible ? 1 : 0.992,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 380),
          curve: AppCurves.standard,
          child: widget.child,
        ),
      ),
    );
  }
}

class OnboardingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const OnboardingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppCurves.standard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.onboardingPrimary
              : AppColors.onboardingSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.onboardingPrimary
                : AppColors.onboardingHairline,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.white : AppColors.gray700,
          ),
        ),
      ),
    );
  }
}

class OnboardingHelperTag extends StatelessWidget {
  final String text;
  final IconData icon;

  const OnboardingHelperTag({
    super.key,
    required this.text,
    this.icon = Icons.auto_awesome_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.black),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingInfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingInfoBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.onboardingSurfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.black, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingStatusBadge extends StatelessWidget {
  final String text;
  final bool animate;

  const OnboardingStatusBadge({
    super.key,
    required this.text,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OnboardingPulseDot(animate: animate),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final Color color;

  const OnboardingSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 999,
    this.color = AppColors.gray100,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return OnboardingSheen(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class OnboardingSheen extends StatefulWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final Duration duration;
  final double sheenWidthFactor;
  final Color highlightColor;
  final bool enabled;

  const OnboardingSheen({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.duration = const Duration(milliseconds: 1900),
    this.sheenWidthFactor = 0.42,
    this.highlightColor = const Color.fromRGBO(255, 255, 255, 0.58),
    this.enabled = true,
  });

  @override
  State<OnboardingSheen> createState() => _OnboardingSheenState();
}

class _OnboardingSheenState extends State<OnboardingSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void didUpdateWidget(covariant OnboardingSheen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = onboardingReduceMotionOf(context);
    if (reduceMotion || !widget.enabled) {
      return widget.child;
    }

    final borderRadius = widget.borderRadius.resolve(
      Directionality.of(context),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sheenWidth = math
                      .max(
                        44,
                        constraints.maxWidth * widget.sheenWidthFactor,
                      )
                      .toDouble();

                  return AnimatedBuilder(
                    animation: _controller,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: sheenWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              widget.highlightColor,
                              Colors.transparent,
                            ],
                            stops: const [0, 0.52, 1],
                          ),
                        ),
                      ),
                    ),
                    builder: (context, child) {
                      final travel = constraints.maxWidth + sheenWidth * 2;
                      final dx = -sheenWidth + travel * _controller.value;

                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPulseDot extends StatefulWidget {
  final bool animate;

  const _OnboardingPulseDot({
    required this.animate,
  });

  @override
  State<_OnboardingPulseDot> createState() => _OnboardingPulseDotState();
}

class _OnboardingPulseDotState extends State<_OnboardingPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = onboardingReduceMotionOf(context);
    if (reduceMotion || !widget.animate) {
      return Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.onboardingPrimary,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        return SizedBox(
          width: 10,
          height: 10,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.16 * (1 - t),
                child: Transform.scale(
                  scale: 0.7 + (t * 1.1),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.onboardingPrimary,
                    ),
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onboardingPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedBackdrop extends StatefulWidget {
  final int step;

  const _AnimatedBackdrop({required this.step});

  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = onboardingReduceMotionOf(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = reduceMotion
              ? 0.22 + widget.step * 0.08
              : (_controller.value + widget.step * 0.14) % 1;

          return CustomPaint(
            painter: _OnboardingBackdropPainter(
              step: widget.step,
              phase: phase,
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingBackdropPainter extends CustomPainter {
  final int step;
  final double phase;

  const _OnboardingBackdropPainter({
    required this.step,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wave = 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final linePaint = Paint()
      ..color = AppColors.onboardingHairline.withValues(alpha: 0.38)
      ..strokeWidth = 1;
    final dotPaint = Paint()
      ..color =
          AppColors.onboardingPrimary.withValues(alpha: 0.15 + wave * 0.08);
    final frameAccentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color =
          AppColors.onboardingPrimary.withValues(alpha: 0.05 + wave * 0.05);

    final stepLabel = '0${step + 1}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: stepLabel,
        style: TextStyle(
          fontSize: 96,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          letterSpacing: -6,
          color: AppColors.onboardingHairline
              .withValues(alpha: 0.24 + wave * 0.03),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final numberOffset = Offset(6, 42 + step * 6.0 + wave * 2.5);
    textPainter.paint(canvas, numberOffset);

    const leftRailX = 46.0;
    canvas.drawLine(
      const Offset(leftRailX, 0),
      Offset(leftRailX, size.height * 0.86),
      linePaint,
    );

    final upperGuideY = 136.0 + step * 10.0;
    canvas.drawLine(
      Offset(leftRailX, upperGuideY),
      Offset(size.width - 18, upperGuideY),
      linePaint,
    );

    final lowerGuideY = size.height * 0.72;
    canvas.drawLine(
      Offset(size.width * 0.56, lowerGuideY),
      Offset(size.width - 12, lowerGuideY),
      linePaint,
    );

    final frameRect = Rect.fromLTWH(
      size.width * 0.62,
      size.height * 0.12,
      size.width * 0.22,
      size.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(18)),
      linePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(18)),
      frameAccentPaint,
    );

    final railSweepRect = Rect.fromCenter(
      center: Offset(leftRailX, size.height * (0.18 + phase * 0.58)),
      width: 2,
      height: 128,
    );
    final railSweepPaint = Paint()
      ..strokeWidth = 2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.onboardingPrimary.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(railSweepRect);
    canvas.drawLine(
      Offset(leftRailX, railSweepRect.top),
      Offset(leftRailX, railSweepRect.bottom),
      railSweepPaint,
    );

    const guideSweepWidth = 152.0;
    final guideSweepX = leftRailX -
        guideSweepWidth +
        ((size.width - 18) - leftRailX + guideSweepWidth * 2) * phase;
    final guideSweepRect = Rect.fromLTWH(
      guideSweepX,
      upperGuideY - 2,
      guideSweepWidth,
      4,
    );
    final guideSweepPaint = Paint()
      ..strokeWidth = 2
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppColors.onboardingPrimary.withValues(alpha: 0.14 + wave * 0.04),
          Colors.transparent,
        ],
      ).createShader(guideSweepRect);
    canvas.drawLine(
      Offset(leftRailX, upperGuideY),
      Offset(size.width - 18, upperGuideY),
      guideSweepPaint,
    );

    canvas.drawCircle(
      Offset(size.width - 20, upperGuideY + 18),
      2.5 + wave,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, lowerGuideY),
      2.2 + wave * 0.6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingBackdropPainter oldDelegate) {
    return oldDelegate.step != step || oldDelegate.phase != phase;
  }
}
