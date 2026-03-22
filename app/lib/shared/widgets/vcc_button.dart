import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum VccButtonType { primary, secondary, ghost, text, danger, small }

/// 开造 VCC 按钮组件
/// 支持主按钮(渐变)、次要按钮、幽灵按钮、文字按钮、危险按钮、小按钮
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (widget.type) {
      case VccButtonType.primary:
        return _buildPrimaryButton(isDark);
      case VccButtonType.secondary:
        return _buildSecondaryButton(isDark);
      case VccButtonType.ghost:
        return _buildGhostButton(isDark);
      case VccButtonType.text:
        return _buildTextButton(isDark);
      case VccButtonType.danger:
        return _buildDangerButton(isDark);
      case VccButtonType.small:
        return _buildSmallButton(isDark);
    }
  }

  Widget _buildPrimaryButton(bool isDark) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        width: widget.isFullWidth ? double.infinity : widget.width,
        constraints: widget.isFullWidth
            ? null
            : const BoxConstraints(minWidth: 120),
        decoration: BoxDecoration(
          gradient: _isDisabled
              ? null
              : (_isPressed ? AppGradients.primaryPressed : AppGradients.primaryButton),
          color: _isDisabled ? AppColors.gray200 : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isDisabled
              ? null
              : (_isPressed ? AppShadows.brandShadowPressed : AppShadows.brandShadow),
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _buildContent(
                  color: _isDisabled ? AppColors.gray400 : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(bool isDark) {
    final borderColor = _isDisabled
        ? AppColors.gray200
        : (_isPressed
            ? AppColors.brandDarkPurple
            : (isDark ? const Color(0xFF8B5CF6) : AppColors.brandPurple));
    final bgColor = _isDisabled
        ? AppColors.gray50
        : (_isPressed
            ? const Color(0xFFF8F7FF)
            : (isDark ? AppColors.darkCard : Colors.white));
    final textColor = _isDisabled
        ? AppColors.gray400
        : (_isPressed ? AppColors.brandDarkPurple : AppColors.brandPurple);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        width: widget.isFullWidth ? double.infinity : widget.width,
        constraints: widget.isFullWidth
            ? null
            : const BoxConstraints(minWidth: 120),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: _buildContent(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(bool isDark) {
    final borderColor = _isDisabled
        ? AppColors.gray200
        : (isDark ? const Color(0xFF8B5CF6) : AppColors.brandPurple);
    final textColor = _isDisabled
        ? AppColors.gray300
        : (isDark ? const Color(0xFF8B5CF6) : AppColors.brandPurple);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        width: widget.isFullWidth ? double.infinity : widget.width,
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.brandPurple.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: _buildContent(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(bool isDark) {
    final textColor = _isDisabled
        ? AppColors.gray300
        : (isDark ? const Color(0xFF8B5CF6) : AppColors.brandPurple);

    return GestureDetector(
      onTap: _isDisabled ? null : widget.onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
            decoration: _isPressed ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton(bool isDark) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        width: widget.isFullWidth ? double.infinity : widget.width,
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFFDC2626) : AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _buildContent(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(bool isDark) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: _isDisabled ? null : AppGradients.primaryButton,
          color: _isDisabled ? AppColors.gray200 : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isDisabled ? AppColors.gray400 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
            ),
          ),
        ],
      );
    }
    return Text(
      widget.text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
