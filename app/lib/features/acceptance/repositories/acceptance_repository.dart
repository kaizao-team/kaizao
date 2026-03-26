import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/acceptance_models.dart';

class AcceptanceRepository {
  final ApiClient _client = ApiClient();

  Future<AcceptanceChecklist> fetchChecklist(String milestoneId) async {
    final response =
        await _client.get(ApiEndpoints.milestoneAcceptance(milestoneId));
    return AcceptanceChecklist.fromJson(response.data as Map<String, dynamic>? ?? {});
  }

  Future<void> confirmAcceptance(String milestoneId) async {
    await _client.post(ApiEndpoints.milestoneAccept(milestoneId));
  }

  Future<void> submitRevision({
    required String milestoneId,
    required String description,
    required List<String> relatedItemIds,
  }) async {
    await _client.post(
      ApiEndpoints.milestoneRevision(milestoneId),
      data: {
        'description': description,
        'related_items': relatedItemIds,
      },
    );
  }
}
