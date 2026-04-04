import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/profile_models.dart';

class ProfileRepository {
  final ApiClient _client = ApiClient();

  Future<UserProfile> fetchProfile(String userId) async {
    final response = await _client.get(ApiEndpoints.userInfo(userId));
    final raw = response.data as Map<String, dynamic>? ?? {};
    debugPrint('[ProfileRepo] fetchProfile($userId) raw role: ${raw['role']}');
    return UserProfile.fromJson(raw);
  }

  Future<UserProfile> fetchCurrentUser() async {
    final response = await _client.get(ApiEndpoints.currentUser);
    final raw = response.data as Map<String, dynamic>? ?? {};
    debugPrint('[ProfileRepo] fetchCurrentUser raw data keys: ${raw.keys.toList()}');
    debugPrint('[ProfileRepo] fetchCurrentUser raw role: ${raw['role']} (type: ${raw['role'].runtimeType})');
    return UserProfile.fromJson(raw);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.put(ApiEndpoints.updateUser(userId), data: data);
  }

  Future<List<SkillTag>> fetchSkills(String userId) async {
    final response = await _client.get(ApiEndpoints.userSkills(userId));
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => SkillTag.fromJson(e))
        .toList();
  }

  Future<void> updateSkills(String userId, List<SkillTag> skills) async {
    await _client.put(
      ApiEndpoints.userSkills(userId),
      data: {'skills': skills.map((s) => s.toJson()).toList()},
    );
  }

  Future<List<PortfolioItem>> fetchPortfolios(String userId) async {
    final response = await _client.get(ApiEndpoints.userPortfolios(userId));
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => PortfolioItem.fromJson(e))
        .toList();
  }
}
