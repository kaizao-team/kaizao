/// Tracks the current phase of an AI SSE stream.
enum AiStreamPhase {
  idle,
  thinking,
  receiving,
  toolCall,
}

enum MatchMode {
  ai('ai', 'AI 智能撮合', '系统根据项目特征自动匹配最合适的团队'),
  manual('manual', '手动选择', '在项目广场公开发布，团队主动投标'),
  invite('invite', '定向邀请', '指定邀请特定团队参与项目');

  const MatchMode(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;
}

class AiChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const AiChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  AiChatMessage copyWith({String? content}) {
    return AiChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
    );
  }
}

class PostDraft {
  final String? category;
  final List<AiChatMessage> messages;
  final PrdGeneratedData? prdData;
  final double? budgetMin;
  final double? budgetMax;
  final MatchMode? matchMode;

  const PostDraft({
    this.category,
    this.messages = const [],
    this.prdData,
    this.budgetMin,
    this.budgetMax,
    this.matchMode,
  });
}

class PrdGeneratedData {
  final String prdId;
  final String title;
  final List<PrdModuleSummary> modules;
  final BudgetSuggestion? budgetSuggestion;

  const PrdGeneratedData({
    required this.prdId,
    required this.title,
    required this.modules,
    this.budgetSuggestion,
  });

  factory PrdGeneratedData.fromJson(Map<String, dynamic> json) {
    return PrdGeneratedData(
      prdId: json['prd_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      modules: (json['modules'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((m) => PrdModuleSummary.fromJson(m))
              .toList() ??
          [],
      budgetSuggestion: json['budget_suggestion'] != null
          ? BudgetSuggestion.fromJson(
              json['budget_suggestion'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PrdModuleSummary {
  final String id;
  final String name;
  final int cardCount;

  const PrdModuleSummary({
    required this.id,
    required this.name,
    required this.cardCount,
  });

  factory PrdModuleSummary.fromJson(Map<String, dynamic> json) {
    final cards = json['cards'] as List?;
    return PrdModuleSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cardCount: cards?.length ?? 0,
    );
  }
}

class BudgetSuggestion {
  final double min;
  final double max;
  final String reason;

  const BudgetSuggestion({
    required this.min,
    required this.max,
    required this.reason,
  });

  factory BudgetSuggestion.fromJson(Map<String, dynamic> json) {
    return BudgetSuggestion(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }
}
