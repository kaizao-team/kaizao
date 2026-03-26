import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_colors.dart';

/// 全屏加载指示器 — 黑色 spinner
class VccLoading extends StatelessWidget {
  final String? message;

  const VccLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? const Color.fromRGBO(10, 10, 10, 0.85)
          : const Color.fromRGBO(255, 255, 255, 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 骨架屏组件
class VccSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const VccSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// 卡片骨架屏
class VccCardSkeleton extends StatelessWidget {
  const VccCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VccSkeleton(width: 60, height: 20),
              VccSkeleton(width: 80, height: 20),
            ],
          ),
          SizedBox(height: 12),
          VccSkeleton(height: 20),
          SizedBox(height: 8),
          VccSkeleton(height: 16),
          SizedBox(height: 12),
          Row(
            children: [
              VccSkeleton(width: 60, height: 24),
              SizedBox(width: 8),
              VccSkeleton(width: 60, height: 24),
              SizedBox(width: 8),
              VccSkeleton(width: 60, height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
