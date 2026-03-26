enum PrdViewMode { overview, cards }

class PrdData {
  final String prdId;
  final String projectId;
  final String title;
  final String version;
  final String createdAt;
  final List<PrdModule> modules;

  const PrdData({
    required this.prdId,
    required this.projectId,
    required this.title,
    required this.version,
    required this.createdAt,
    required this.modules,
  });

  factory PrdData.fromJson(Map<String, dynamic> json) {
    return PrdData(
      prdId: json['prd_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      version: json['version'] as String? ?? '1.0',
      createdAt: json['created_at'] as String? ?? '',
      modules: (json['modules'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((m) => PrdModule.fromJson(m))
              .toList() ??
          [],
    );
  }

  int get totalCards => modules.fold(0, (sum, m) => sum + m.cards.length);

  int get completedCards => modules.fold(
      0, (sum, m) => sum + m.cards.where((c) => c.status == 'completed').length);

  double get progress => totalCards > 0 ? completedCards / totalCards : 0;
}

class PrdModule {
  final String id;
  final String name;
  final String icon;
  final int order;
  final List<EarsCard> cards;

  const PrdModule({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
    required this.cards,
  });

  factory PrdModule.fromJson(Map<String, dynamic> json) {
    return PrdModule(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'widgets',
      order: json['order'] as int? ?? 0,
      cards: (json['cards'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((c) => EarsCard.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class EarsCard {
  final String id;
  final String moduleId;
  final String title;
  final String type;
  final String priority;
  final String description;
  final String event;
  final String action;
  final String response;
  final String stateChange;
  final List<AcceptanceCriteria> acceptanceCriteria;
  final List<String> roles;
  final int effortHours;
  final List<String> dependencies;
  final List<String> techTags;
  final String status;

  const EarsCard({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.type,
    required this.priority,
    required this.description,
    required this.event,
    required this.action,
    required this.response,
    required this.stateChange,
    required this.acceptanceCriteria,
    required this.roles,
    required this.effortHours,
    required this.dependencies,
    required this.techTags,
    required this.status,
  });

  factory EarsCard.fromJson(Map<String, dynamic> json) {
    return EarsCard(
      id: json['id'] as String? ?? '',
      moduleId: json['module_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'event',
      priority: json['priority'] as String? ?? 'P2',
      description: json['description'] as String? ?? '',
      event: json['event'] as String? ?? '',
      action: json['action'] as String? ?? '',
      response: json['response'] as String? ?? '',
      stateChange: json['state_change'] as String? ?? '',
      acceptanceCriteria: (json['acceptance_criteria'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((c) => AcceptanceCriteria.fromJson(c))
              .toList() ??
          [],
      roles: (json['roles'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      effortHours: json['effort_hours'] as int? ?? 0,
      dependencies: (json['dependencies'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      techTags: (json['tech_tags'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      status: json['status'] as String? ?? 'pending',
    );
  }

  bool get isCompleted => status == 'completed';

  int get completedCriteria => acceptanceCriteria.where((c) => c.checked).length;

  double get criteriaProgress =>
      acceptanceCriteria.isNotEmpty ? completedCriteria / acceptanceCriteria.length : 0;
}

class AcceptanceCriteria {
  final String id;
  final String content;
  final bool checked;

  const AcceptanceCriteria({
    required this.id,
    required this.content,
    required this.checked,
  });

  factory AcceptanceCriteria.fromJson(Map<String, dynamic> json) {
    return AcceptanceCriteria(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      checked: json['checked'] as bool? ?? false,
    );
  }

  AcceptanceCriteria copyWith({bool? checked}) {
    return AcceptanceCriteria(
      id: id,
      content: content,
      checked: checked ?? this.checked,
    );
  }
}
