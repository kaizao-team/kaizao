import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/match_models.dart';

class MatchRepository {
  final ApiClient _client = ApiClient();

  Future<List<BidItem>> fetchBids(String projectId) async {
    final response = await _client.get(ApiEndpoints.projectBids(projectId));
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => BidItem.fromJson(e))
        .toList();
  }

  Future<AiSuggestion> fetchAiSuggestion(String projectId) async {
    final response =
        await _client.get(ApiEndpoints.projectAiSuggestion(projectId));
    return AiSuggestion.fromJson(response.data as Map<String, dynamic>? ?? {});
  }

  Future<void> submitBid({
    required String projectId,
    required double amount,
    required int durationDays,
    required String proposal,
    required String bidType,
    String? teamId,
  }) async {
    await _client.post(
      ApiEndpoints.projectBids(projectId),
      data: {
        'amount': amount,
        'duration_days': durationDays,
        'proposal': proposal,
        'bid_type': bidType,
        if (teamId != null) 'team_id': teamId,
      },
    );
  }

  Future<void> acceptBid(String bidId) async {
    await _client.post(ApiEndpoints.bidAccept(bidId));
  }
}
