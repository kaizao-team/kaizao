import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/match_models.dart';

class MatchRepository {
  final ApiClient _client = ApiClient();

  Future<List<BidItem>> fetchBids(String projectId) async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.projectBids(projectId),
      fromJson: (data) => data is List ? data : <dynamic>[],
    );
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => BidItem.fromJson(e))
        .toList();
  }

  Future<AiSuggestion> fetchAiSuggestion(String projectId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.projectAiSuggestion(projectId),
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return AiSuggestion.fromJson(response.data ?? {});
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

  Future<void> withdrawBid(String bidId) async {
    await _client.put(ApiEndpoints.bidWithdraw(bidId));
  }
}
