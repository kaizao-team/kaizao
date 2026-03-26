import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/rate_provider.dart';
import '../widgets/star_rating.dart';
import '../widgets/rating_dimension_group.dart';

class RatePage extends ConsumerStatefulWidget {
  final String projectId;
  final String revieweeId;
  final String revieweeName;
  final bool isDemander;

  const RatePage({
    super.key,
    required this.projectId,
    required this.revieweeId,
    this.revieweeName = '',
    this.isDemander = true,
  });

  @override
  ConsumerState<RatePage> createState() => _RatePageState();
}

class _RatePageState extends ConsumerState<RatePage> {
  final _commentController = TextEditingController();

  RateFormParams get _params => RateFormParams(
        projectId: widget.projectId,
        revieweeId: widget.revieweeId,
        isDemander: widget.isDemander,
      );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rateFormProvider(_params));

    if (state.isSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '评价已提交',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '感谢你的评价，这将帮助社区更好地运转',
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
              const SizedBox(height: 32),
              VccButton(
                text: '返回',
                type: VccButtonType.secondary,
                isFullWidth: false,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '项目评价',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.revieweeName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '评价 ${widget.revieweeName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
          const Text(
            '综合评分',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                StarRating(
                  rating: state.overallRating,
                  starSize: 44,
                  onChanged: (r) => ref
                      .read(rateFormProvider(_params).notifier)
                      .setOverallRating(r),
                ),
                const SizedBox(height: 8),
                Text(
                  state.overallRating > 0
                      ? state.overallRating.toStringAsFixed(1)
                      : '点击评分',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: state.overallRating > 0
                        ? AppColors.accentGold
                        : AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.gray200),
          const SizedBox(height: 20),
          RatingDimensionGroup(
            dimensions: state.dimensions,
            onDimensionChanged: (entry) => ref
                .read(rateFormProvider(_params).notifier)
                .setDimensionRating(entry.key, entry.value),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.gray200),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                '文字评价',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              Text(
                '${state.comment.length}/500',
                style: const TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            onChanged: (val) => ref
                .read(rateFormProvider(_params).notifier)
                .setComment(val),
            style: const TextStyle(fontSize: 15, color: AppColors.black),
            decoration: InputDecoration(
              hintText: '请输入至少10个字的评价...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.gray400,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.black,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (state.comment.isNotEmpty && state.comment.trim().length < 10)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '评价内容至少10个字',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          const SizedBox(height: 32),
          VccButton(
            text: '提交评价',
            isLoading: state.isSubmitting,
            onPressed: state.isValid ? () => _submit(context) : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final success =
        await ref.read(rateFormProvider(_params).notifier).submit();
    if (!context.mounted) return;
    if (!success) {
      VccToast.show(context,
          message: '提交失败，请重试', type: VccToastType.error);
    }
  }
}
