import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reduceMotionProvider = Provider<bool>((ref) {
  return false;
});

class ReduceMotionWidget extends StatelessWidget {
  final Widget child;

  const ReduceMotionWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }

  static bool isReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  static Duration animationDuration(BuildContext context, Duration normal) {
    if (isReduceMotion(context)) {
      return const Duration(milliseconds: 200);
    }
    return normal;
  }

  static Curve animationCurve(BuildContext context, Curve normal) {
    if (isReduceMotion(context)) {
      return Curves.linear;
    }
    return normal;
  }
}
