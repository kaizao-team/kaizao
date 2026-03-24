import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum VccToastType { info, success, warning, error }

/// 开造 VCC Toast 组件 — 顶部浮动提示
class VccToast {
  VccToast._();

  static void show(
    BuildContext context, {
    required String message,
    VccToastType type = VccToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _VccToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }
}

class _VccToastWidget extends StatefulWidget {
  final String message;
  final VccToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _VccToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_VccToastWidget> createState() => _VccToastWidgetState();
}

class _VccToastWidgetState extends State<_VccToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case VccToastType.success:
        return AppColors.success;
      case VccToastType.warning:
        return AppColors.warning;
      case VccToastType.error:
        return AppColors.error;
      case VccToastType.info:
        return AppColors.black;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case VccToastType.success:
        return Icons.check_circle_outline;
      case VccToastType.warning:
        return Icons.warning_amber_outlined;
      case VccToastType.error:
        return Icons.error_outline;
      case VccToastType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_icon, color: AppColors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(Icons.close, color: AppColors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
