import '../../../core/config/app_env.dart';
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

  // ============================================================
  // AI Agent v2 — real AI conversation
  // ============================================================

  /// First turn: create a requirement session.
  /// [projectId] is required by the AI Agent — in production this comes from
  /// Go backend's project creation; for demo we generate a UUID on the client.
  Future<AiAgentResponse> startRequirement(
    String projectId,
    String message, {
    String? title,
  }) async {
    if (AppEnv.useMock) {
      return _mockSendMessage(message, null);
    }
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
    if (AppEnv.useMock) {
      return _mockSendMessage(message, null);
    }
    final body = await _aiAgent.post(
      ApiEndpoints.aiAgentMessage(projectId),
      data: {'message': message},
    );
    return AiAgentResponse.fromJson(body);
  }

  /// Confirm (or give feedback on) the generated PRD.
  Future<AiAgentResponse> confirmPrd(
    String projectId, {
    String? feedback,
  }) async {
    if (AppEnv.useMock) {
      return _mockConfirmPrd();
    }
    final body = await _aiAgent.post(
      ApiEndpoints.aiAgentConfirm(projectId),
      data: {
        if (feedback != null) 'feedback': feedback,
      },
    );
    return AiAgentResponse.fromJson(body);
  }

  // ============================================================
  // Legacy mock fallback (USE_MOCK=true)
  // ============================================================

  Future<AiAgentResponse> _mockSendMessage(
    String message,
    String? category,
  ) async {
    final result = await _client.post(
      ApiEndpoints.projectAiChat,
      data: {
        'message': message,
        if (category != null) 'category': category,
      },
    );
    final data = result.data as Map<String, dynamic>? ?? {};
    return AiAgentResponse(
      projectId: data['project_id'] as String? ?? 'mock_project',
      sessionId: data['session_id'] as String? ?? 'mock_session',
      agentMessage: data['reply'] as String? ?? '',
      subStage: (data['can_generate_prd'] == true) ? 'prd_draft' : 'clarifying',
      completenessScore: data['completeness_score'] as int? ?? 0,
    );
  }

  Future<AiAgentResponse> _mockConfirmPrd() async {
    return const AiAgentResponse(
      projectId: 'mock_project',
      sessionId: 'mock_session',
      agentMessage: 'PRD confirmed',
      subStage: 'tasks_ready',
      completenessScore: 100,
    );
  }

  // ============================================================
  // Non-AI endpoints (unchanged, still via Go server)
  // ============================================================

  Future<Map<String, dynamic>> generatePrd(
    String category,
    List<Map<String, String>> chatHistory,
  ) async {
    final response = await _client.post(
      ApiEndpoints.projectGeneratePrd,
      data: {
        'category': category,
        'chat_history': chatHistory,
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<void> saveDraft(Map<String, dynamic> draftData) async {
    await _client.post(ApiEndpoints.projectDraft, data: draftData);
  }

  Future<Map<String, dynamic>> publishProject(
    Map<String, dynamic> projectData,
  ) async {
    final response = await _client.post(ApiEndpoints.projects, data: projectData);
    return response.data as Map<String, dynamic>? ?? {};
  }
}
