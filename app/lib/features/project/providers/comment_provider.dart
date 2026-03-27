import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/comment_models.dart';

class CommentListState {
  final bool isLoading;
  final List<CommentItem> comments;
  final String? errorMessage;
  final bool isSubmitting;

  const CommentListState({
    this.isLoading = false,
    this.comments = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  CommentListState copyWith({
    bool? isLoading,
    List<CommentItem>? comments,
    String? Function()? errorMessage,
    bool? isSubmitting,
  }) {
    return CommentListState(
      isLoading: isLoading ?? this.isLoading,
      comments: comments ?? this.comments,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CommentListNotifier extends StateNotifier<CommentListState> {
  final ApiClient _client = ApiClient();
  final String projectId;

  CommentListNotifier(this.projectId)
      : super(const CommentListState()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.projectComments(projectId),
        fromJson: (data) => data as List<dynamic>,
      );
      if (!mounted) return;
      final comments = (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => CommentItem.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, comments: comments);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<bool> addComment(String content) async {
    if (content.trim().isEmpty) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);
    try {
      await _client.post(
        ApiEndpoints.projectComments(projectId),
        data: {'content': content.trim()},
      );
      if (!mounted) return false;
      state = state.copyWith(isSubmitting: false);
      await loadComments();
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

  void toggleLike(String commentId) {
    final comments = state.comments.map((c) {
      if (c.id == commentId) {
        final newLiked = !c.isLiked;
        return c.copyWith(
          isLiked: newLiked,
          likeCount: c.likeCount + (newLiked ? 1 : -1),
        );
      }
      return c;
    }).toList();
    state = state.copyWith(comments: comments);
  }
}

final commentListProvider = StateNotifierProvider.autoDispose
    .family<CommentListNotifier, CommentListState, String>((ref, projectId) {
  return CommentListNotifier(projectId);
});
