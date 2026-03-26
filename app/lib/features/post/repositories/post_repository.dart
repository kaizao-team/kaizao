import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class PostRepository {
  final ApiClient _client;

  PostRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> sendAiMessage(String message, String? category) async {
    final response = await _client.post(
      ApiEndpoints.projectAiChat,
      data: {
        'message': message,
        if (category != null) 'category': category,
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> generatePrd(String category, List<Map<String, String>> chatHistory) async {
    final response = await _client.post(
      ApiEndpoints.projectGeneratePrd,
      data: {
        'category': category,
        'chat_history': chatHistory,
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<void> saveDraft(Map<String, dynamic> draftData) async {
    await _client.post(ApiEndpoints.projectDraft, data: draftData);
  }

  Future<Map<String, dynamic>> publishProject(Map<String, dynamic> projectData) async {
    final response = await _client.post(ApiEndpoints.projects, data: projectData);
    return response.data as Map<String, dynamic>? ?? {};
  }
}
