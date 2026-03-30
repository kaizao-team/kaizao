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
}

final expertOnboardingRepositoryProvider =
    Provider<ExpertOnboardingRepository>((ref) {
  return ExpertOnboardingRepository();
});
