/// Response model for AI Agent v2 requirement endpoints.
class AiAgentResponse {
  final String projectId;
  final String sessionId;
  final String agentMessage;
  final String subStage;
  final int completenessScore;
  final bool? analysisComplete;

  const AiAgentResponse({
    required this.projectId,
    required this.sessionId,
    required this.agentMessage,
    required this.subStage,
    required this.completenessScore,
    this.analysisComplete,
  });

  factory AiAgentResponse.fromJson(Map<String, dynamic> json) {
    // The AI Agent may nest data under a 'data' key or return flat.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final String projectId = data['project_id']?.toString().trim() ?? '';
    final String sessionId = data['session_id']?.toString().trim() ?? '';
    final String agentMessage = data['agent_message']?.toString().trim() ??
        data['message']?.toString().trim() ??
        '';
    final int? completenessScore = switch (data['completeness_score']) {
      final int value => value,
      final num value => value.toInt(),
      _ => null,
    };

    if (projectId.isEmpty) {
      throw const FormatException('AI Agent response missing project_id');
    }
    if (sessionId.isEmpty) {
      throw const FormatException('AI Agent response missing session_id');
    }
    if (agentMessage.isEmpty) {
      throw const FormatException('AI Agent response missing agent_message');
    }
    if (completenessScore == null) {
      throw const FormatException(
        'AI Agent response missing completeness_score',
      );
    }

    return AiAgentResponse(
      projectId: projectId,
      sessionId: sessionId,
      agentMessage: agentMessage,
      subStage: data['sub_stage'] as String? ?? 'clarifying',
      completenessScore: completenessScore,
      analysisComplete: data['analysis_complete'] as bool?,
    );
  }

  bool get canGeneratePrd =>
      analysisComplete ??
      (subStage == 'prd_draft' || completenessScore >= 60);
}
