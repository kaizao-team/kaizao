import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/notification_models.dart';

class NotificationState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<NotificationItem> notifications;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;

  const NotificationState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.notifications = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = true,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<NotificationItem>? notifications,
    String? Function()? errorMessage,
    int? currentPage,
    bool? hasMore,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _client = ApiClient();

  NotificationNotifier() : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(
      isLoading: true,
      currentPage: 1,
      hasMore: true,
      errorMessage: () => null,
    );
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {'page': 1, 'page_size': 10},
        fromJson: (data) => data as List<dynamic>,
      );
      if (!mounted) return;
      final items = (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      final meta = response.meta;
      state = state.copyWith(
        isLoading: false,
        notifications: items,
        currentPage: 1,
        hasMore: meta != null && meta.page < meta.totalPages,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {'page': nextPage, 'page_size': 10},
        fromJson: (data) => data as List<dynamic>,
      );
      if (!mounted) return;
      final items = (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      final meta = response.meta;
      state = state.copyWith(
        isLoadingMore: false,
        notifications: [...state.notifications, ...items],
        currentPage: nextPage,
        hasMore: meta != null && meta.page < meta.totalPages,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void markAsRead(String id) {
    _client.post(ApiEndpoints.notificationRead(id));
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    _client.post(ApiEndpoints.notificationReadAll);
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
