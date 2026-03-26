import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';

class StarRating extends StatefulWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final double starSize;
  final bool allowHalf;

  const StarRating({
    super.key,
    this.rating = 0,
    required this.onChanged,
    this.starSize = 36,
    this.allowHalf = true,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int _lastSelectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onStarTap(int index, {bool isHalf = false}) {
    final newRating = isHalf ? index + 0.5 : index + 1.0;
    if (newRating != widget.rating) {
      HapticFeedback.lightImpact();
      widget.onChanged(newRating);
      _lastSelectedIndex = index;
      _bounceController.forward(from: 0);
    }
  }

  double _ratingFromPosition(Offset localPosition, double totalWidth) {
    final starWidth = totalWidth / 5;
    final starIndex = (localPosition.dx / starWidth).clamp(0, 4.99);
    final fraction = starIndex - starIndex.floor();
    if (widget.allowHalf && fraction < 0.5) {
      return starIndex.floor() + 0.5;
    }
    return starIndex.floor() + 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final rating = _ratingFromPosition(
              details.localPosition,
              constraints.maxWidth.clamp(0, widget.starSize * 5 + 20),
            );
            widget.onChanged(rating.clamp(0.5, 5.0));
          },
          onHorizontalDragEnd: (_) {
            HapticFeedback.lightImpact();
            _bounceController.forward(from: 0);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  final scale = _lastSelectedIndex == index
                      ? _bounceAnimation.value
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTapUp: (details) {
                    final isHalf = widget.allowHalf &&
                        details.localPosition.dx < widget.starSize / 2;
                    _onStarTap(index, isHalf: isHalf);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _buildStar(index),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStar(int index) {
    final diff = widget.rating - index;

    if (diff >= 1) {
      return _StarIcon(
        size: widget.starSize,
        color: AppColors.accentGold,
        filled: true,
      );
    } else if (diff >= 0.5) {
      return _HalfStar(
        size: widget.starSize,
        filledColor: AppColors.accentGold,
        emptyColor: const Color(0xFFE2E8F0),
      );
    } else {
      return _StarIcon(
        size: widget.starSize,
        color: const Color(0xFFE2E8F0),
        filled: false,
      );
    }
  }
}

class _StarIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;

  const _StarIcon({
    required this.size,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      child: Icon(
        filled ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: color,
      ),
    );
  }
}

class _HalfStar extends StatelessWidget {
  final double size;
  final Color filledColor;
  final Color emptyColor;

  const _HalfStar({
    required this.size,
    required this.filledColor,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(Icons.star_outline_rounded, size: size, color: emptyColor),
          ClipRect(
            clipper: _HalfClipper(),
            child: Icon(Icons.star_rounded, size: size, color: filledColor),
          ),
        ],
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
