import 'package:dio/dio.dart';

import '../../../core/network/ai_agent_client.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/sse_client.dart';
import '../models/post_models.dart';

class PostRepository {
  final ApiClient _client;
  final AiAgentClient _aiAgent;

  PostRepository({ApiClient? client, AiAgentClient? aiAgent})
      : _client = client ?? ApiClient(),
        _aiAgent = aiAgent ?? AiAgentClient();

  Map<String, dynamic> _unwrapAiAgentEnvelope(
    Map<String, dynamic> body, {
    required String operation,
  }) {
    if (!body.containsKey('code')) {
      throw FormatException(
        '$operation expected AI envelope with code/message/data',
      );
    }

    final code = body['code'] as int? ?? -1;
    if (code != 0) {
      final message = body['message'] as String? ?? '$operation failed';
      throw Exception(message);
    }

    if (!body.containsKey('data')) {
      throw FormatException('$operation expected AI envelope data field');
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data != null) {
      return {'data': data};
    }

    return const {};
  }

  // ============================================================
  // AI Agent v2 — project draft bootstrap + requirement conversation
  // ============================================================

  /// Create a Go-side project draft and return the raw data payload.
  Future<Map<String, dynamic>> createProjectDraft({
    String? category,
    double? budgetMin,
    double? budgetMax,
    int step = 1,
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

  /// First turn: create a requirement session via SSE.
  Stream<SseEvent> startRequirementStream(
    String projectId,
    String message, {
    String? title,
    String? category,
    CancelToken? cancelToken,
  }) {
    return _aiAgent.postSseStream(
      ApiEndpoints.aiAgentStartStream,
      data: {
        'project_id': projectId,
        'message': message,
        if (title != null) 'title': title,
        if (category != null) 'category': category,
      },
      cancelToken: cancelToken,
    );
  }

  /// Subsequent turns: continue the conversation via SSE.
  Stream<SseEvent> sendRequirementMessageStream(
    String projectId,
    String message, {
    CancelToken? cancelToken,
  }) {
    return _aiAgent.postSseStream(
      ApiEndpoints.aiAgentMessageStream(projectId),
      data: {'message': message},
      cancelToken: cancelToken,
    );
  }

  /// Confirm the PRD. This is now a lightweight ack only.
  Future<Map<String, dynamic>> confirmRequirement(
    String projectId, {
    String? feedback,
  }) async {
    final body = await _aiAgent.post(
      ApiEndpoints.aiAgentConfirm(projectId),
      data: {
        'project_id': projectId,
        if (feedback != null) 'feedback': feedback,
      },
    );
    return _unwrapAiAgentEnvelope(body, operation: 'Confirm requirement');
  }

  Future<ProjectOverviewData> fetchProjectOverview(String projectId) async {
    final body = await _aiAgent.get(ApiEndpoints.pipelineOverview(projectId));
    final data =
        _unwrapAiAgentEnvelope(body, operation: 'Fetch project overview');
    return ProjectOverviewData.fromJson(data);
  }

  /// Trigger EARS decomposition after match + cooperation confirmation.
  /// This is reserved for a later flow; current PostPage should not call it.
  Future<Map<String, dynamic>> decomposeRequirement(String projectId) async {
    final body = await _aiAgent.post(
      ApiEndpoints.aiAgentDecompose(projectId),
    );
    return _unwrapAiAgentEnvelope(body, operation: 'Decompose requirement');
  }

  /// GET the requirement document (markdown).
  Future<Map<String, dynamic>> fetchDocument(String projectId) async {
    final body = await _aiAgent.get(
      ApiEndpoints.requirementDocument(projectId),
    );
    return _unwrapAiAgentEnvelope(
      body,
      operation: 'Fetch requirement document',
    );
  }

  Future<Map<String, dynamic>> updateProjectDraft(
    String projectId, {
    String? title,
    String? description,
    String? category,
    double? budgetMin,
    double? budgetMax,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.projectDetail(projectId),
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (budgetMin != null) 'budget_min': budgetMin,
        if (budgetMax != null) 'budget_max': budgetMax,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  /// Publish the draft project so Go-side matching can proceed.
  Future<Map<String, dynamic>> publishDraftProject(String projectId) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.projectPublish(projectId),
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  /// GET project recommendations from the Go backend.
  Future<Map<String, dynamic>> recommendTeam(
    String projectId, {
    int pageSize = 1,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.projectRecommendations(projectId),
      queryParameters: {
        'page': 1,
        'page_size': pageSize,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  /// Confirm the recommended team by triggering Go quick-match.
  Future<Map<String, dynamic>> confirmMatch(String projectId) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.quickMatch(projectId),
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? const {};
  }

  // ============================================================
  // Non-AI endpoints (Go server)
  // ============================================================

  Future<void> saveDraft(Map<String, dynamic> draftData) async {
    await _client.post(ApiEndpoints.projectDraft, data: draftData);
  }

  Future<Map<String, dynamic>> publishProject(
    Map<String, dynamic> projectData,
  ) async {
    final response =
        await _client.post(ApiEndpoints.projects, data: projectData);
    return response.data as Map<String, dynamic>? ?? {};
  }
}
