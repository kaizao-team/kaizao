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
              const Text('KAIZO', style: AppTextStyles.onboardingWordmark),
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
            borderRadius: BorderRadius.circular(AppRadius.md),
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
  final IconData? icon;
  final Widget Function(Color color)? iconBuilder;

  const OnboardingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.01 : 1,
        duration: AppDurations.normal,
        curve: AppCurves.standard,
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
            boxShadow: selected ? AppShadows.shadow1 : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null || iconBuilder != null) ...[
                if (iconBuilder != null)
                  iconBuilder!(selected ? AppColors.white : AppColors.gray700)
                else
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? AppColors.white : AppColors.gray700,
                  ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.white : AppColors.gray700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingIconTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? iconWidget;
  final bool compact;

  const OnboardingIconTag({
    super.key,
    required this.label,
    required this.icon,
    this.iconWidget,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null)
            iconWidget!
          else
            Icon(
              icon,
              size: compact ? 14 : 15,
              color: AppColors.gray700,
            ),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSectionHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? accessory;

  const OnboardingSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.accessory,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: AppTextStyles.onboardingSectionLabel,
    );

    final descriptionWidget = description == null
        ? null
        : Text(
            description!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final verticalLayout = constraints.maxWidth < 360 || accessory == null;

        if (verticalLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              if (descriptionWidget != null) ...[
                const SizedBox(height: 6),
                descriptionWidget,
              ],
              if (accessory != null) ...[
                const SizedBox(height: 10),
                accessory!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  if (descriptionWidget != null) ...[
                    const SizedBox(height: 6),
                    descriptionWidget,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(child: accessory!),
          ],
        );
      },
    );
  }
}

class OnboardingDeckCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final bool animateOnAppear;
  final bool ambientPulse;

  const OnboardingDeckCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.elevated = false,
    this.animateOnAppear = true,
    this.ambientPulse = false,
  });

  @override
  State<OnboardingDeckCard> createState() => _OnboardingDeckCardState();
}

class _OnboardingDeckCardState extends State<OnboardingDeckCard> {
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _settled = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = onboardingReduceMotionOf(context);
    final settled = reduceMotion || !widget.animateOnAppear ? true : _settled;

    return OnboardingAmbientMotion(
      enabled: widget.ambientPulse,
      duration: const Duration(milliseconds: 3200),
      scaleDelta: 0.004,
      translateY: 2.5,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 420),
            curve: AppCurves.standard,
            left: settled ? 8 : 4,
            right: settled ? 18 : 10,
            top: settled ? 14 : 10,
            bottom: settled ? -4 : 2,
            child: AnimatedOpacity(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              curve: AppCurves.standard,
              opacity: settled ? 1 : 0.24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.onboardingSurface.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.onboardingHairline.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 460),
            curve: AppCurves.standard,
            left: settled ? 16 : 10,
            right: settled ? 8 : 4,
            top: settled ? 7 : 4,
            bottom: settled ? 6 : 10,
            child: AnimatedOpacity(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 340),
              curve: AppCurves.standard,
              opacity: settled ? 1 : 0.35,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.onboardingSurface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.onboardingHairline.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ),
          ),
          AnimatedScale(
            scale: settled ? 1 : 0.992,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 420),
            curve: AppCurves.standard,
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: AppCurves.standard,
              width: double.infinity,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: AppColors.onboardingSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.64),
                ),
                boxShadow: widget.elevated
                    ? (settled ? AppShadows.onboardingLift : AppShadows.shadow1)
                    : const [],
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingAmbientMotion extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;
  final double scaleDelta;
  final double translateY;

  const OnboardingAmbientMotion({
    super.key,
    required this.child,
    this.enabled = false,
    this.duration = const Duration(milliseconds: 2800),
    this.scaleDelta = 0.006,
    this.translateY = 2,
  });

  @override
  State<OnboardingAmbientMotion> createState() =>
      _OnboardingAmbientMotionState();
}

class _OnboardingAmbientMotionState extends State<OnboardingAmbientMotion>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  AnimationController _ensureController() {
    return _controller ??= AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _ensureController().repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingAmbientMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && oldWidget.duration != widget.duration) {
      _controller!.duration = widget.duration;
    }
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _ensureController().repeat(reverse: true);
      } else if (_controller != null) {
        _controller!
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = onboardingReduceMotionOf(context);
    if (!widget.enabled || reduceMotion) {
      return widget.child;
    }

    final controller = _ensureController();
    if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }

    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(controller.value);
        final scale = 1 + widget.scaleDelta * t;
        final dy = -widget.translateY * t;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }
}

class OnboardingChoiceCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final IconData? icon;
  final Widget Function(Color color)? iconBuilder;

  const OnboardingChoiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.badge,
    this.icon,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppCurves.standard,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.onboardingPrimary
              : AppColors.onboardingSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.onboardingPrimary
                : AppColors.onboardingHairline,
          ),
          boxShadow: selected ? AppShadows.shadow2 : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null || icon != null || iconBuilder != null) ...[
              Row(
                children: [
                  if (icon != null || iconBuilder != null)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.white.withValues(alpha: 0.12)
                            : AppColors.onboardingSurfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: iconBuilder != null
                            ? iconBuilder!(
                                selected ? AppColors.white : AppColors.black,
                              )
                            : Icon(
                                icon,
                                size: 17,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.black,
                              ),
                      ),
                    ),
                  const Spacer(),
                  if (badge != null)
                    Text(
                      badge!,
                      style: AppTextStyles.onboardingMeta.copyWith(
                        color: selected
                            ? AppColors.white.withValues(alpha: 0.75)
                            : AppColors.gray400,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              style: AppTextStyles.body1.copyWith(
                color: selected ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: selected
                    ? AppColors.white.withValues(alpha: 0.8)
                    : AppColors.onboardingMutedText,
                height: 1.45,
              ),
            ),
          ],
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
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.black),
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
    this.animate = false,
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
          _OnboardingSignalGlyph(animate: animate),
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

class _OnboardingSignalGlyph extends StatefulWidget {
  final bool animate;

  const _OnboardingSignalGlyph({
    required this.animate,
  });

  @override
  State<_OnboardingSignalGlyph> createState() => _OnboardingSignalGlyphState();
}

class _OnboardingSignalGlyphState extends State<_OnboardingSignalGlyph>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  AnimationController _ensureController() {
    return _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ensureController().repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingSignalGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _ensureController().repeat();
      } else if (_controller != null) {
        _controller!
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = onboardingReduceMotionOf(context);
    if (reduceMotion || !widget.animate) {
      return SizedBox(
        width: 12,
        height: 12,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onboardingPrimary.withValues(alpha: 0.04),
                border: Border.all(
                  color: AppColors.onboardingPrimary.withValues(alpha: 0.24),
                ),
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onboardingPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final controller = _ensureController();
    if (!controller.isAnimating) {
      controller.repeat();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final angle = controller.value * math.pi * 2;

        return SizedBox(
          width: 12,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onboardingPrimary.withValues(alpha: 0.04),
                  border: Border.all(
                    color: AppColors.onboardingPrimary.withValues(alpha: 0.24),
                  ),
                ),
              ),
              Transform.rotate(
                angle: angle,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.onboardingPrimary,
                    ),
                  ),
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
