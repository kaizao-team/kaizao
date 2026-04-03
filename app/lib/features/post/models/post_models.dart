/// Tracks the current phase of an AI SSE stream.
enum AiStreamPhase {
  idle,
  thinking,
  receiving,
  toolCall,
}

enum AiChatInputType {
  unknown('unknown'),
  singleChoice('single_choice'),
  multiChoice('multi_choice'),
  freeText('free_text');

  const AiChatInputType(this.backendValue);

  final String backendValue;

  static AiChatInputType fromBackend(String? value) {
    switch (value) {
      case 'single_choice':
        return AiChatInputType.singleChoice;
      case 'multi_choice':
        return AiChatInputType.multiChoice;
      case 'free_text':
      case 'text':
        return AiChatInputType.freeText;
      default:
        return AiChatInputType.unknown;
    }
  }
}

class AiChatOption {
  final String key;
  final String label;
  final bool isCustom;

  const AiChatOption({
    required this.key,
    required this.label,
    this.isCustom = false,
  });
}

class AiChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AiChatInputType inputType;
  final List<AiChatOption>? options;
  final AiChatOption? optionSelected;
  final List<AiChatOption>? optionsSelected;
  final String? freeTextAnswer;
  final int? minSelections;
  final int? maxSelections;
  final String? placeholder;

  const AiChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.inputType = AiChatInputType.unknown,
    this.options,
    this.optionSelected,
    this.optionsSelected,
    this.freeTextAnswer,
    this.minSelections,
    this.maxSelections,
    this.placeholder,
  });

  AiChatMessage copyWith({
    String? content,
    AiChatInputType? inputType,
    List<AiChatOption>? Function()? options,
    AiChatOption? Function()? optionSelected,
    List<AiChatOption>? Function()? optionsSelected,
    String? Function()? freeTextAnswer,
    int? Function()? minSelections,
    int? Function()? maxSelections,
    String? Function()? placeholder,
  }) {
    return AiChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      inputType: inputType ?? this.inputType,
      options: options != null ? options() : this.options,
      optionSelected:
          optionSelected != null ? optionSelected() : this.optionSelected,
      optionsSelected:
          optionsSelected != null ? optionsSelected() : this.optionsSelected,
      freeTextAnswer:
          freeTextAnswer != null ? freeTextAnswer() : this.freeTextAnswer,
      minSelections:
          minSelections != null ? minSelections() : this.minSelections,
      maxSelections:
          maxSelections != null ? maxSelections() : this.maxSelections,
      placeholder: placeholder != null ? placeholder() : this.placeholder,
    );
  }

  bool get hasOptions => options != null && options!.isNotEmpty;

  bool get usesMultiChoice => inputType == AiChatInputType.multiChoice;
  bool get usesFreeText => inputType == AiChatInputType.freeText;

  bool get allowsQuickSelect => hasOptions && !usesMultiChoice;

  bool get isAnswered => usesMultiChoice
      ? optionsSelected != null && optionsSelected!.isNotEmpty
      : usesFreeText
          ? freeTextAnswer?.trim().isNotEmpty == true
          : optionSelected != null;
}

class ProjectOverviewData {
  final String projectId;
  final String title;
  final String summary;
  final BudgetSuggestion? budgetSuggestion;

  const ProjectOverviewData({
    required this.projectId,
    required this.title,
    required this.summary,
    this.budgetSuggestion,
  });
}

class RecommendedTeam {
  final String teamId;
  final String name;
  final String? avatar;
  final int matchScore;
  final List<String> skills;
  final String level;
  final String? reason;

  const RecommendedTeam({
    required this.teamId,
    required this.name,
    this.avatar,
    required this.matchScore,
    required this.skills,
    required this.level,
    this.reason,
  });

  factory RecommendedTeam.fromJson(Map<String, dynamic> json) {
    return RecommendedTeam(
      teamId: json['team_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      matchScore: json['match_score'] as int? ?? 0,
      skills: (json['skills'] as List?)?.whereType<String>().toList() ?? [],
      level: json['level'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }
}

class PostDraft {
  final String? category;
  final List<AiChatMessage> messages;
  final ProjectOverviewData? overviewData;
  final double? budgetMin;
  final double? budgetMax;

  const PostDraft({
    this.category,
    this.messages = const [],
    this.overviewData,
    this.budgetMin,
    this.budgetMax,
  });
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
