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
  customInput('custom_input'),
  freeText('free_text');

  const AiChatInputType(this.backendValue);

  final String backendValue;

  static AiChatInputType fromBackend(String? value) {
    switch (value) {
      case 'single_choice':
        return AiChatInputType.singleChoice;
      case 'multi_choice':
        return AiChatInputType.multiChoice;
      case 'custom_input':
        return AiChatInputType.customInput;
      case 'free_text':
      case 'text':
        return AiChatInputType.freeText;
      default:
        return AiChatInputType.unknown;
    }
  }
}

enum PostPublishResultType {
  awaitingTeamConfirmation,
  publishedWithoutMatch,
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
  bool get usesFreeText =>
      inputType == AiChatInputType.freeText ||
      inputType == AiChatInputType.customInput;

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
  final List<ProjectOverviewTargetUser> targetUsers;
  final String? complexity;
  final ProjectOverviewTechRequirements? techRequirements;
  final Map<String, String> nonFunctionalRequirements;
  final int? moduleCount;
  final int? itemCount;
  final List<ProjectOverviewPrdItem> prdItems;
  final BudgetSuggestion? budgetSuggestion;

  const ProjectOverviewData({
    required this.projectId,
    required this.title,
    required this.summary,
    this.targetUsers = const [],
    this.complexity,
    this.techRequirements,
    this.nonFunctionalRequirements = const {},
    this.moduleCount,
    this.itemCount,
    this.prdItems = const [],
    this.budgetSuggestion,
  });

  bool get hasHighlights =>
      complexity != null || moduleCount != null || itemCount != null;

  bool get hasTechSummary =>
      techRequirements?.platform != null ||
      techRequirements?.techStack != null ||
      (techRequirements?.thirdParty.isNotEmpty ?? false);

  bool get hasDetailSections =>
      targetUsers.isNotEmpty ||
      hasTechSummary ||
      nonFunctionalRequirements.isNotEmpty;

  factory ProjectOverviewData.fromJson(Map<String, dynamic> json) {
    String requireString(String field) {
      final value = json[field];
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) {
        throw FormatException('overview payload missing $field');
      }
      return text;
    }

    final rawTargetUsers = json['target_users'];
    final targetUsers = <ProjectOverviewTargetUser>[];
    if (rawTargetUsers is List) {
      for (final item in rawTargetUsers) {
        if (item is! Map) continue;
        try {
          targetUsers.add(ProjectOverviewTargetUser.fromJson(
            Map<String, dynamic>.from(item),
          ));
        } catch (_) {}
      }
    }

    final rawNonFunctional = json['non_functional_requirements'];
    final nonFunctionalRequirements = switch (rawNonFunctional) {
      null => const <String, String>{},
      final Map<dynamic, dynamic> map => map.map(
          (key, value) => MapEntry(
            key.toString(),
            value?.toString().trim() ?? '',
          ),
        )..removeWhere((key, value) => key.trim().isEmpty || value.isEmpty),
      _ => throw const FormatException(
          'overview payload field non_functional_requirements expected Object',
        ),
    };

    final rawPrdItems = json['prd_items'];
    final prdItems = <ProjectOverviewPrdItem>[];
    if (rawPrdItems is List) {
      for (final item in rawPrdItems) {
        if (item is! Map) continue;
        try {
          prdItems.add(ProjectOverviewPrdItem.fromJson(
            Map<String, dynamic>.from(item),
          ));
        } catch (_) {}
      }
    }

    final rawTechRequirements = json['tech_requirements'];

    return ProjectOverviewData(
      projectId: requireString('project_id'),
      title: requireString('title'),
      summary: requireString('summary'),
      targetUsers: targetUsers,
      complexity: json['complexity']?.toString().trim(),
      techRequirements: rawTechRequirements == null
          ? null
          : ProjectOverviewTechRequirements.fromJson(
              Map<String, dynamic>.from(rawTechRequirements as Map),
            ),
      nonFunctionalRequirements: nonFunctionalRequirements,
      moduleCount: (json['module_count'] as num?)?.toInt(),
      itemCount: (json['item_count'] as num?)?.toInt(),
      prdItems: prdItems,
    );
  }
}

class ProjectOverviewTargetUser {
  final String role;
  final String description;

  const ProjectOverviewTargetUser({
    required this.role,
    required this.description,
  });

  factory ProjectOverviewTargetUser.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString().trim() ?? '';
    final description = json['description']?.toString().trim() ?? '';
    return ProjectOverviewTargetUser(
      role: role.isNotEmpty ? role : '用户',
      description: description.isNotEmpty ? description : '—',
    );
  }
}

class ProjectOverviewTechRequirements {
  final String? platform;
  final String? techStack;
  final List<String> thirdParty;

  const ProjectOverviewTechRequirements({
    this.platform,
    this.techStack,
    this.thirdParty = const [],
  });

  factory ProjectOverviewTechRequirements.fromJson(Map<String, dynamic> json) {
    final rawThirdParty = json['third_party'];
    final thirdParty = switch (rawThirdParty) {
      null => const <String>[],
      final List<dynamic> list => list
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      _ => throw const FormatException(
          'tech_requirements.third_party expected List',
        ),
    };

    final platform = json['platform']?.toString().trim();
    final techStack = (json['tech_stack'] ?? json['technology_stack'])
        ?.toString()
        .trim();

    return ProjectOverviewTechRequirements(
      platform: platform == null || platform.isEmpty ? null : platform,
      techStack: techStack == null || techStack.isEmpty ? null : techStack,
      thirdParty: thirdParty,
    );
  }
}

class ProjectOverviewPrdItem {
  final String itemId;
  final String moduleName;
  final String title;
  final String description;
  final String? priority;
  final String? acceptanceSummary;

  const ProjectOverviewPrdItem({
    required this.itemId,
    required this.moduleName,
    required this.title,
    required this.description,
    this.priority,
    this.acceptanceSummary,
  });

  factory ProjectOverviewPrdItem.fromJson(Map<String, dynamic> json) {
    String requireString(String field) {
      final value = json[field];
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) {
        throw FormatException('prd_items item missing $field');
      }
      return text;
    }

    final priority = json['priority']?.toString().trim();
    final acceptanceSummary = json['acceptance_summary']?.toString().trim();

    return ProjectOverviewPrdItem(
      itemId: requireString('item_id'),
      moduleName: requireString('module_name'),
      title: requireString('title'),
      description: requireString('description'),
      priority: priority == null || priority.isEmpty ? null : priority,
      acceptanceSummary: acceptanceSummary == null || acceptanceSummary.isEmpty
          ? null
          : acceptanceSummary,
    );
  }
}

class RecommendedTeam {
  final String teamId;
  final String name;
  final String? avatar;
  final int matchScore;
  final List<String> skills;
  final String level;
  final String? reason;
  final double? budgetMin;
  final double? budgetMax;

  const RecommendedTeam({
    required this.teamId,
    required this.name,
    this.avatar,
    required this.matchScore,
    required this.skills,
    required this.level,
    this.reason,
    this.budgetMin,
    this.budgetMax,
  });

  factory RecommendedTeam.fromJson(Map<String, dynamic> json) {
    List<dynamic> readListField(String field) {
      final value = json[field];
      if (value == null) return const <dynamic>[];
      if (value is List) return value;
      throw FormatException(
        'recommendation payload field $field expected List but got ${value.runtimeType}',
      );
    }

    String firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }

    final resolvedId = firstNonEmpty([
      json['team_id'],
      json['provider_id'],
      json['user_id'],
      json['id'],
    ]);
    if (resolvedId.isEmpty) {
      throw const FormatException(
        'recommendation payload missing team_id/provider_id',
      );
    }

    final resolvedName = firstNonEmpty([
      json['team_name'],
      json['name'],
      json['nickname'],
      json['user_name'],
    ]);
    if (resolvedName.isEmpty) {
      throw const FormatException(
        'recommendation payload missing display name',
      );
    }

    final rawScore = json['match_score'];
    final resolvedScore = switch (rawScore) {
      final num value => value.round(),
      final String value =>
        int.tryParse(value) ?? double.tryParse(value)?.round() ?? -1,
      _ => -1,
    };
    if (resolvedScore < 0) {
      throw const FormatException(
        'recommendation payload missing match_score',
      );
    }

    final skills = <String>[];
    final skillSet = <String>{};
    void addSkill(dynamic value) {
      final skill = value?.toString().trim();
      if (skill != null && skill.isNotEmpty && skillSet.add(skill)) {
        skills.add(skill);
      }
    }

    for (final skill in readListField('highlight_skills')) {
      addSkill(skill);
    }
    addSkill(json['primary_skill']);
    addSkill(json['skill']);

    final resolvedLevel = firstNonEmpty([
      json['level'],
      json['primary_skill'],
      json['skill'],
      json['bid_type'] == 'team' ? '团队' : null,
      '推荐服务方',
    ]);
    final avatar = firstNonEmpty([json['team_avatar_url'], json['avatar_url'], json['avatar']]);
    final reason = firstNonEmpty([
      json['recommendation_reason'],
      json['reason'],
    ]);

    final budgetMin = (json['budget_min'] as num?)?.toDouble();
    final budgetMax = (json['budget_max'] as num?)?.toDouble();

    return RecommendedTeam(
      teamId: resolvedId,
      name: resolvedName,
      avatar: avatar.isEmpty ? null : avatar,
      matchScore: resolvedScore,
      skills: skills,
      level: resolvedLevel,
      reason: reason.isEmpty ? null : reason,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
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
