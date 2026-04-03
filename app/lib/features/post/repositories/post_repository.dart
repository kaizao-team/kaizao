import '../../../core/network/ai_agent_client.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/ai_agent_response.dart';

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
      return body;
    }

    final code = body['code'] as int? ?? -1;
    if (code != 0) {
      final message = body['message'] as String? ?? '$operation failed';
      throw Exception(message);
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
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

  /// First turn: create a requirement session.
  Future<AiAgentResponse> startRequirement(
    String projectId,
    String message, {
    String? title,
  }) async {
    final body = await _aiAgent.post(
      ApiEndpoints.aiAgentStart,
      data: {
        'project_id': projectId,
        'message': message,
        if (title != null) 'title': title,
      },
    );
    return AiAgentResponse.fromJson(body);
  }

  /// Subsequent turns: continue the conversation.
  Future<AiAgentResponse> sendMessage(
    String projectId,
    String message,
  ) async {
    final body = await _aiAgent.post(
      ApiEndpoints.aiAgentMessage(projectId),
      data: {'message': message},
    );
    return AiAgentResponse.fromJson(body);
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

  /// POST match/recommend — get recommended teams.
  Future<Map<String, dynamic>> recommendTeam(
    String projectId, {
    int pageSize = 1,
  }) async {
    return await _aiAgent.post(
      ApiEndpoints.matchRecommend,
      data: {
        'demand_id': projectId,
        'page_size': pageSize,
      },
    );
  }

  /// No real backend endpoint exists yet for confirming a matched team.
  Future<Map<String, dynamic>> confirmMatch(
    String projectId,
    String teamId,
  ) async {
    throw UnimplementedError('缺少真实的确认撮合接口，无法继续提交 team_id=$teamId');
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
