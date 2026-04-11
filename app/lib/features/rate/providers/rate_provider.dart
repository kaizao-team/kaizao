import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rate_models.dart';
import '../repositories/rate_repository.dart';

class RateFormState {
  final double overallRating;
  final List<RatingDimension> dimensions;
  final String comment;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;

  const RateFormState({
    this.overallRating = 0,
    this.dimensions = const [],
    this.comment = '',
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  bool get isValid =>
      overallRating > 0 &&
      dimensions.every((d) => d.rating > 0) &&
      comment.trim().length >= 10;

  double get averageRating {
    if (dimensions.isEmpty) return overallRating;
    final sum = dimensions.fold<double>(0, (s, d) => s + d.rating);
    return sum / dimensions.length;
  }

  RateFormState copyWith({
    double? overallRating,
    List<RatingDimension>? dimensions,
    String? comment,
    bool? isSubmitting,
    bool? isSubmitted,
    String? Function()? errorMessage,
  }) {
    return RateFormState(
      overallRating: overallRating ?? this.overallRating,
      dimensions: dimensions ?? this.dimensions,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class RateFormNotifier extends StateNotifier<RateFormState> {
  final RateRepository _repository;
  final String _projectId;
  final String _revieweeId;

  RateFormNotifier(
    this._repository,
    this._projectId,
    this._revieweeId,
    bool isDemander,
  ) : super(RateFormState(
          dimensions: isDemander
              ? const [
                  RatingDimension(name: '代码质量'),
                  RatingDimension(name: '沟通效率'),
                  RatingDimension(name: '交付时效'),
                ]
              : const [
                  RatingDimension(name: '需求清晰度'),
                  RatingDimension(name: '付款及时性'),
                ],
        ));

  void setOverallRating(double rating) {
    state = state.copyWith(overallRating: rating);
  }

  void setDimensionRating(int index, double rating) {
    final dims = List<RatingDimension>.from(state.dimensions);
    dims[index] = dims[index].copyWith(rating: rating);
    state = state.copyWith(dimensions: dims);
  }

  void setComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  Future<bool> submit() async {
    if (!state.isValid) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);
    try {
      await _repository.submitReview(ReviewSubmission(
        projectId: _projectId,
        revieweeId: _revieweeId,
        overallRating: state.overallRating,
        dimensions: state.dimensions,
        comment: state.comment.trim(),
      ));
      if (!mounted) return false;
      state = state.copyWith(isSubmitting: false, isSubmitted: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => e.toString(),
      );
      return false;
    }
  }
}

class RateFormParams {
  final String projectId;
  final String revieweeId;
  final bool isDemander;

  const RateFormParams({
    required this.projectId,
    required this.revieweeId,
    this.isDemander = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RateFormParams &&
          projectId == other.projectId &&
          revieweeId == other.revieweeId &&
          isDemander == other.isDemander;

  @override
  int get hashCode =>
      projectId.hashCode ^ revieweeId.hashCode ^ isDemander.hashCode;
}

final rateFormProvider = StateNotifierProvider.autoDispose
    .family<RateFormNotifier, RateFormState, RateFormParams>((ref, params) {
  return RateFormNotifier(
    RateRepository(),
    params.projectId,
    params.revieweeId,
    params.isDemander,
  );
});
