import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final ApiClient _client = ApiClient();

  Future<List<Conversation>> fetchConversations() async {
    final response = await _client.get(ApiEndpoints.conversations);
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Conversation.fromJson(e))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final response = await _client.get(
      ApiEndpoints.conversationMessages(conversationId),
    );
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ChatMessage.fromJson(e))
        .toList();
  }

  Future<String> sendMessage(String conversationId, String content) async {
    final response = await _client.post(
      ApiEndpoints.conversationMessages(conversationId),
      data: {'content': content, 'type': 'text'},
    );
    final data = response.data as Map<String, dynamic>?;
    return data?['id'] as String? ?? '';
  }

  Future<void> markRead(String conversationId) async {
    await _client.post(ApiEndpoints.conversationRead(conversationId));
  }

  Future<void> deleteConversation(String conversationId) async {
    await _client.delete(ApiEndpoints.conversationDetail(conversationId));
  }
}
