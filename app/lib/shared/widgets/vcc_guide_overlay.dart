import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// 开造 VCC 引导蒙层 — 高亮目标区域 + 气泡提示
class VccGuideOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String message;
  final String? buttonText;
  final VoidCallback? onDismiss;
  final VoidCallback? onTargetTap;
  final bool showPulse;

  const VccGuideOverlay({
    super.key,
    required this.targetKey,
    required this.message,
    this.buttonText,
    this.onDismiss,
    this.onTargetTap,
    this.showPulse = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();

        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final targetRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

        return Stack(
          children: [
            // dim overlay
            GestureDetector(
              onTap: onDismiss,
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _HolePainter(targetRect: targetRect),
              ),
            ),

            // pulse effect
            if (showPulse)
              Positioned(
                left: targetRect.center.dx - 30,
                top: targetRect.center.dy - 30,
                child: const _PulseWidget(size: 60),
              ),

            // target tap area
            Positioned(
              left: targetRect.left,
              top: targetRect.top,
              width: targetRect.width,
              height: targetRect.height,
              child: GestureDetector(
                onTap: onTargetTap ?? onDismiss,
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // tooltip bubble
            Positioned(
              left: 16,
              right: 16,
              top: targetRect.top > 300
                  ? targetRect.top - 80
                  : targetRect.bottom + 16,
              child: _buildTooltip(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTooltip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.2),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
                height: 1.4,
              ),
            ),
          ),
          if (buttonText != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect targetRect;

  _HolePainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color.fromRGBO(0, 0, 0, 0.6);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        targetRect.inflate(6),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) => old.targetRect != targetRect;
}

class _PulseWidget extends StatefulWidget {
  final double size;

  const _PulseWidget({required this.size});

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + _controller.value * 0.4;
        final opacity = 1.0 - _controller.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.fromRGBO(124, 58, 237, opacity * 0.6),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
