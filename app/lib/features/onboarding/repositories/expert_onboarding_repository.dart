import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class ExpertSkillDraft {
  final String name;
  final String category;
  final bool isPrimary;

  const ExpertSkillDraft({
    required this.name,
    required this.category,
    this.isPrimary = false,
  });
}

class ExpertOnboardingRepository {
  final ApiClient _client;

  ExpertOnboardingRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
    double? hourlyRate,
    int? availableStatus,
    int? role,
    String? contactPhone,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.currentUser,
      data: {
        if (nickname != null) 'nickname': nickname,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (availableStatus != null) 'available_status': availableStatus,
        if (role != null) 'role': role,
        if (AppConstants.enableContactPhone &&
            contactPhone != null &&
            contactPhone.isNotEmpty)
          'contact_phone': contactPhone,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateSkills(
    List<ExpertSkillDraft> skills,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.userSkills('me'),
      data: {
        'skills': skills
            .map(
              (item) => {
                'name': item.name,
                'category': item.category,
                'is_primary': item.isPrimary,
              },
            )
            .toList(),
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> createTeam({
    String? name,
    double? hourlyRate,
    int? availableStatus,
    double? budgetMin,
    double? budgetMax,
    String? description,
    required String inviteCode,
    List<String>? serviceDirections,
    int? selfRating,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.teams,
      data: {
        if (name != null) 'name': name,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (availableStatus != null) 'available_status': availableStatus,
        if (budgetMin != null) 'budget_min': budgetMin,
        if (budgetMax != null) 'budget_max': budgetMax,
        if (description != null) 'description': description,
        'invite_code': inviteCode,
        if (serviceDirections != null && serviceDirections.isNotEmpty)
          'service_directions': serviceDirections,
        if (selfRating != null) 'self_rating': selfRating,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }
}

final expertOnboardingRepositoryProvider =
    Provider<ExpertOnboardingRepository>((ref) {
  return ExpertOnboardingRepository();
});
