import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/notification_models.dart';

class NotificationState {
  final bool isLoading;
  final List<NotificationItem> notifications;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationItem>? notifications,
    String? Function()? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _client = ApiClient();

  NotificationNotifier() : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _client.get<List<dynamic>>(
        ApiEndpoints.notifications,
        fromJson: (data) => data as List<dynamic>,
      );
      if (!mounted) return;
      final items = (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, notifications: items);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
