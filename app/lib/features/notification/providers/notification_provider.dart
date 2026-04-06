import 'dart:math' as math;

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
  final int unreadCount;

  const NotificationState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.notifications = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = true,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<NotificationItem>? notifications,
    String? Function()? errorMessage,
    int? currentPage,
    bool? hasMore,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _client = ApiClient();

  NotificationNotifier() : super(const NotificationState()) {
    refresh();
  }

  Future<void> refresh() async {
    await Future.wait([
      loadNotifications(),
      refreshUnreadCount(),
    ]);
  }

  Future<void> refreshUnreadCount() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.notificationUnreadCount,
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (!mounted) return;
      final unread = (response.data?['unread_count'] as num?)?.toInt() ?? 0;
      state = state.copyWith(unreadCount: unread);
    } catch (_) {
      // Keep the current badge count if the refresh fails.
    }
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
        queryParameters: {'page': 1, 'page_size': 20},
        fromJson: (data) => data as List<dynamic>,
      );
      if (!mounted) return;
      final items = (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList(growable: false);
      final meta = response.meta;
      final fallbackUnread = items.where((item) => !item.isRead).length;
      state = state.copyWith(
        isLoading: false,
        notifications: items,
        currentPage: 1,
        hasMore: meta != null && meta.page < meta.totalPages,
        unreadCount:
            state.unreadCount > 0 ? state.unreadCount : fallbackUnread,
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
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {'page': nextPage, 'page_size': 20},
        fromJson: (data) => data as List<dynamic>,
      );
      if (!mounted) return;
      final items = (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList(growable: false);
      final meta = response.meta;
      state = state.copyWith(
        isLoadingMore: false,
        notifications: [...state.notifications, ...items],
        currentPage: nextPage,
        hasMore: meta != null && meta.page < meta.totalPages,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markAsRead(String id) async {
    final index = state.notifications.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = state.notifications[index];
    if (current.isRead) return;

    final updated = [...state.notifications];
    updated[index] = current.copyWith(isRead: true);
    state = state.copyWith(
      notifications: updated,
      unreadCount: math.max(0, state.unreadCount - 1),
    );

    try {
      await _client.put<void>(ApiEndpoints.notificationRead(id));
    } catch (_) {
      if (!mounted) return;
      updated[index] = current;
      state = state.copyWith(
        notifications: updated,
        unreadCount: state.unreadCount + 1,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final hadUnread = state.notifications.any((item) => !item.isRead);
    if (!hadUnread && state.unreadCount == 0) return;

    final previous = state.notifications;
    final updated = previous
        .map((item) => item.isRead ? item : item.copyWith(isRead: true))
        .toList(growable: false);
    final previousUnreadCount = state.unreadCount;
    state = state.copyWith(
      notifications: updated,
      unreadCount: 0,
    );

    try {
      await _client.put<void>(ApiEndpoints.notificationReadAll);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        notifications: previous,
        unreadCount: previousUnreadCount,
      );
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
