import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/rate_models.dart';

class RateRepository {
  final ApiClient _client = ApiClient();

  Future<void> submitReview(ReviewSubmission submission) async {
    await _client.post(ApiEndpoints.reviews, data: submission.toJson());
  }

  Future<List<ReviewItem>> fetchProjectReviews(String projectId) async {
    final response =
        await _client.get(ApiEndpoints.projectReviews(projectId));
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ReviewItem.fromJson(e))
        .toList();
  }
}
