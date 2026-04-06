import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/team_models.dart';
import '../models/team_profile.dart';

class TeamRepository {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> fetchTeamHall({String? roleFilter}) async {
    final params = <String, dynamic>{};
    if (roleFilter != null && roleFilter.isNotEmpty) {
      params['role'] = roleFilter;
    }
    final response =
        await _client.get(ApiEndpoints.teams, queryParameters: params);
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<TeamDetail> fetchTeamDetail(String teamId) async {
    final response = await _client.get(ApiEndpoints.teamDetail(teamId));
    return TeamDetail.fromJson(response.data as Map<String, dynamic>? ?? {});
  }

  Future<TeamProfile> fetchTeamProfile(String teamId) async {
    final response = await _client.get(ApiEndpoints.teamDetail(teamId));
    return TeamProfile.fromJson(response.data as Map<String, dynamic>? ?? {});
  }

  Future<void> createTeamPost(Map<String, dynamic> data) async {
    await _client.post(ApiEndpoints.teamPosts, data: data);
  }

  Future<void> updateSplitRatio(
    String teamId,
    List<Map<String, dynamic>> ratios,
  ) async {
    await _client.put(
      ApiEndpoints.teamSplitRatio(teamId),
      data: {'ratios': ratios},
    );
  }

  Future<void> confirmTeam(String teamId) async {
    await _client.post(ApiEndpoints.teamInvite(teamId));
  }

  Future<void> respondInvite(String inviteId, bool accept) async {
    await _client.post(
      ApiEndpoints.teamInviteRespond(inviteId),
      data: {'accept': accept},
    );
  }
}
