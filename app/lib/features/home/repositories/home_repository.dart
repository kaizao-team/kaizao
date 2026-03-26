import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/home_models.dart';

class HomeRepository {
  final ApiClient _client = ApiClient();

  Future<DemanderHomeData> fetchDemanderHome() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.homeDemander,
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return DemanderHomeData.fromJson(response.data ?? {});
  }

  Future<ExpertHomeData> fetchExpertHome() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.homeExpert,
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return ExpertHomeData.fromJson(response.data ?? {});
  }
}
