/// Response model for AI Agent v2 requirement endpoints.
class AiAgentResponse {
  final String projectId;
  final String sessionId;
  final String agentMessage;
  final String subStage;
  final int completenessScore;

  const AiAgentResponse({
    required this.projectId,
    required this.sessionId,
    required this.agentMessage,
    required this.subStage,
    required this.completenessScore,
  });

  factory AiAgentResponse.fromJson(Map<String, dynamic> json) {
    // The AI Agent may nest data under a 'data' key or return flat.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return AiAgentResponse(
      projectId: data['project_id'] as String? ?? '',
      sessionId: data['session_id'] as String? ?? '',
      agentMessage: data['agent_message'] as String? ??
          data['message'] as String? ??
          '',
      subStage: data['sub_stage'] as String? ?? 'clarifying',
      completenessScore: data['completeness_score'] as int? ?? 0,
    );
  }

  bool get canGeneratePrd => subStage == 'prd_draft' || completenessScore >= 60;
}
