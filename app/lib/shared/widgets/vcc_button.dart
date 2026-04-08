import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

enum VccButtonType { primary, secondary, ghost, text, danger, small }

/// 开造 VCC 按钮组件 — Notion/Linear 风格
/// primary: 黑色实底白字 / secondary: 白底黑边 / ghost: 透明黑边
class VccButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final VccButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;

  const VccButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = VccButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
  });

  @override
  State<VccButton> createState() => _VccButtonState();
}

class _VccButtonState extends State<VccButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case VccButtonType.primary:
        return _buildPrimaryButton();
      case VccButtonType.secondary:
        return _buildSecondaryButton();
      case VccButtonType.ghost:
        return _buildGhostButton();
      case VccButtonType.text:
        return _buildTextButton();
      case VccButtonType.danger:
        return _buildDangerButton();
      case VccButtonType.small:
        return _buildSmallButton();
    }
  }

  Widget _wrapGesture({required Widget child}) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: child,
    );
  }

  BoxConstraints? get _constraints =>
      widget.isFullWidth ? null : const BoxConstraints(minWidth: 120);

  double? get _width => widget.isFullWidth ? double.infinity : widget.width;

  Widget _buildPrimaryButton() {
    final bgColor = _isDisabled
        ? AppColors.surfaceStrong
        : (_isPressed ? AppColors.gray700 : AppColors.primary);
    final textColor = _isDisabled ? AppColors.gray400 : AppColors.white;

    return _wrapGesture(
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 48,
        width: _width,
        constraints: _constraints,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : _buildContent(
                  color: textColor,
                  style: AppTextStyles.button1,
                ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    final borderColor = _isDisabled
        ? AppColors.outlineVariant
        : (_isPressed ? AppColors.outlineSoft : AppColors.outlineVariant);
    final bgColor = _isDisabled
        ? AppColors.surfaceAlt
        : (_isPressed ? AppColors.surfaceAlt : AppColors.surfaceRaised);
    final textColor = _isDisabled ? AppColors.gray400 : AppColors.onSurface;

    return _wrapGesture(
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 48,
        width: _width,
        constraints: _constraints,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: _buildContent(
            color: textColor,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton() {
    final borderColor =
        _isDisabled ? AppColors.outlineVariant : AppColors.outlineSoft;
    final textColor = _isDisabled ? AppColors.gray300 : AppColors.onSurface;

    return _wrapGesture(
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 48,
        width: _width,
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.surfaceAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: _buildContent(
            color: textColor,
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton() {
    final textColor = _isDisabled ? AppColors.gray300 : AppColors.accent;

    return GestureDetector(
      onTap: _isDisabled ? null : widget.onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          widget.text,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton() {
    return _wrapGesture(
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 48,
        width: _width,
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.error.withValues(alpha: 0.92)
              : AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: _buildContent(
            color: AppColors.white,
            style: AppTextStyles.button1,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton() {
    final bgColor = _isDisabled
        ? AppColors.gray200
        : (_isPressed ? AppColors.gray700 : AppColors.black);

    return _wrapGesture(
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: _isDisabled ? AppColors.gray400 : AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required Color color,
    required TextStyle style,
  }) {
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(widget.text, style: style.copyWith(color: color)),
        ],
      );
    }
    return Text(widget.text, style: style.copyWith(color: color));
  }
}
