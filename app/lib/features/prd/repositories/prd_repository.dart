import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class PrdRepository {
  final ApiClient _client;

  PrdRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> fetchPrd(String projectId) async {
    final response = await _client.get(ApiEndpoints.projectPrd(projectId));
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<void> updateCard(String projectId, String cardId, Map<String, dynamic> data) async {
    await _client.put(ApiEndpoints.prdCardUpdate(projectId, cardId), data: data);
  }
}
