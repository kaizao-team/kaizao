import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

// ============================================================
// Conversation List
// ============================================================

class ConversationListState {
  final bool isLoading;
  final List<Conversation> conversations;
  final String? errorMessage;

  const ConversationListState({
    this.isLoading = false,
    this.conversations = const [],
    this.errorMessage,
  });

  ConversationListState copyWith({
    bool? isLoading,
    List<Conversation>? conversations,
    String? Function()? errorMessage,
  }) {
    return ConversationListState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);
}

class ConversationListNotifier extends StateNotifier<ConversationListState> {
  final ChatRepository _repository;

  ConversationListNotifier(this._repository)
      : super(const ConversationListState()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final list = await _repository.fetchConversations();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, conversations: list);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> markRead(String conversationId) async {
    final updated = state.conversations.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    state = state.copyWith(conversations: updated);
    try {
      await _repository.markRead(conversationId);
    } catch (_) {}
  }

  Future<void> deleteConversation(String conversationId) async {
    final updated =
        state.conversations.where((c) => c.id != conversationId).toList();
    state = state.copyWith(conversations: updated);
    try {
      await _repository.deleteConversation(conversationId);
    } catch (_) {
      if (!mounted) return;
      await loadConversations();
    }
  }
}

final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, ConversationListState>(
        (ref) {
  return ConversationListNotifier(ChatRepository());
});

// ============================================================
// Chat Detail
// ============================================================

class ChatDetailState {
  final bool isLoading;
  final List<ChatMessage> messages;
  final String? errorMessage;

  const ChatDetailState({
    this.isLoading = false,
    this.messages = const [],
    this.errorMessage,
  });

  ChatDetailState copyWith({
    bool? isLoading,
    List<ChatMessage>? messages,
    String? Function()? errorMessage,
  }) {
    return ChatDetailState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  final ChatRepository _repository;
  final String conversationId;

  ChatDetailNotifier(this._repository, this.conversationId)
      : super(const ChatDetailState()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final list = await _repository.fetchMessages(conversationId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, messages: list);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      senderId: 'me',
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(messages: [...state.messages, tempMsg]);

    try {
      final newId = await _repository.sendMessage(conversationId, content);
      if (!mounted) return;
      final updated = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(status: MessageStatus.sent, id: newId);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
    } catch (_) {
      if (!mounted) return;
      final updated = state.messages.map((m) {
        if (m.id == tempId) return m.copyWith(status: MessageStatus.failed);
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
    }
  }

  Future<void> retryMessage(String messageId) async {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final msg = state.messages[index];
    if (!msg.isFailed) return;

    final updated = state.messages.map((m) {
      if (m.id == messageId) return m.copyWith(status: MessageStatus.sending);
      return m;
    }).toList();
    state = state.copyWith(messages: updated);

    try {
      final newId =
          await _repository.sendMessage(conversationId, msg.content);
      if (!mounted) return;
      final updatedAfter = state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(status: MessageStatus.sent, id: newId);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedAfter);
    } catch (_) {
      if (!mounted) return;
      final updatedAfter = state.messages.map((m) {
        if (m.id == messageId) return m.copyWith(status: MessageStatus.failed);
        return m;
      }).toList();
      state = state.copyWith(messages: updatedAfter);
    }
  }

  void deleteMessage(String messageId) {
    final updated = state.messages.where((m) => m.id != messageId).toList();
    state = state.copyWith(messages: updated);
  }
}

final chatDetailProvider = StateNotifierProvider.autoDispose
    .family<ChatDetailNotifier, ChatDetailState, String>(
        (ref, conversationId) {
  return ChatDetailNotifier(ChatRepository(), conversationId);
});
