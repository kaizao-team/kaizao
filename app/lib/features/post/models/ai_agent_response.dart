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

  factory AiAgentResponse.fromSnapshotJson(Map<String, dynamic> json) {
    final payload = AiAgentSsePayload.fromJson(json);
    final projectId = payload.projectId?.trim() ?? '';
    final sessionId = payload.sessionId?.trim() ?? '';
    final agentMessage = payload.agentMessage?.trim() ?? '';
    final completenessScore = payload.completenessScore;

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
      subStage: payload.subStage ?? 'clarifying',
      completenessScore: completenessScore,
      analysisComplete: payload.analysisComplete,
    );
  }

  bool get canGeneratePrd =>
      analysisComplete ?? (subStage == 'prd_draft' || completenessScore >= 60);
}

/// Event-level payload for SSE responses.
///
/// Unlike [AiAgentResponse], this model intentionally keeps fields optional so
/// `init` / `text` / `stage_info` / `done` can share a single decoder.
class AiAgentSsePayload {
  final String? projectId;
  final String? sessionId;
  final String? agentMessage;
  final String? subStage;
  final int? completenessScore;
  final bool? analysisComplete;
  final String? inputType;
  final Map<String, dynamic>? question;

  const AiAgentSsePayload({
    this.projectId,
    this.sessionId,
    this.agentMessage,
    this.subStage,
    this.completenessScore,
    this.analysisComplete,
    this.inputType,
    this.question,
  });

  factory AiAgentSsePayload.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final question = _asJsonMap(data['question']);

    return AiAgentSsePayload(
      projectId: _readText(data['project_id']),
      sessionId: _readText(data['session_id']),
      agentMessage:
          _readText(data['agent_message']) ?? _readText(data['message']),
      subStage: _readText(data['sub_stage']),
      completenessScore: _readInt(data['completeness_score']),
      analysisComplete: data['analysis_complete'] as bool?,
      inputType: _readText(question?['input_type'] ?? data['input_type']),
      question: question,
    );
  }

  static String? _readText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _readInt(Object? value) {
    return switch (value) {
      final int number => number,
      final num number => number.toInt(),
      final String text => int.tryParse(text),
      _ => null,
    };
  }

  static Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry('$key', mapValue));
    }
    return null;
  }
}
