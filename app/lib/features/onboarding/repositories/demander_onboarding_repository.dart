import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class DemanderOnboardingRepository {
  final ApiClient _client;

  DemanderOnboardingRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> updateProfile({
    required String nickname,
    String? avatarUrl,
    String? contactPhone,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.currentUser,
      data: {
        'nickname': nickname,
        'avatar_url': avatarUrl ?? '',
        if (AppConstants.enableContactPhone &&
            contactPhone != null &&
            contactPhone.isNotEmpty)
          'contact_phone': contactPhone,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> createProjectDraft({
    String? category,
    double? budgetMin,
    double? budgetMax,
    int step = 2,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.projectDraft,
      data: {
        if (category != null) 'category': category,
        if (budgetMin != null) 'budget_min': budgetMin,
        if (budgetMax != null) 'budget_max': budgetMax,
        'step': step,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateProjectDraft(
    String projectId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.projectDetail(projectId),
      data: data,
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> publishProject(String projectId) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.projectPublish(projectId),
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> createProject({
    required String title,
    required String description,
    required String category,
    required double budgetMin,
    required double budgetMax,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.projects,
      data: {
        'title': title,
        'description': description,
        'category': category,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }
}

final demanderOnboardingRepositoryProvider =
    Provider<DemanderOnboardingRepository>((ref) {
  return DemanderOnboardingRepository();
});
