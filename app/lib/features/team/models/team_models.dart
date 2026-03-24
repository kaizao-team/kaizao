class TeamRoleSlot {
  final String name;
  final int ratio;
  final bool filled;

  const TeamRoleSlot({
    required this.name,
    this.ratio = 0,
    this.filled = false,
  });

  factory TeamRoleSlot.fromJson(Map<String, dynamic> json) {
    return TeamRoleSlot(
      name: json['name'] as String? ?? '',
      ratio: json['ratio'] as int? ?? 0,
      filled: json['filled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'ratio': ratio,
        'filled': filled,
      };
}

class TeamPostCreator {
  final String id;
  final String nickname;
  final String? avatar;

  const TeamPostCreator({
    required this.id,
    required this.nickname,
    this.avatar,
  });

  factory TeamPostCreator.fromJson(Map<String, dynamic> json) {
    return TeamPostCreator(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
    );
  }
}

class TeamPost {
  final String id;
  final String projectName;
  final String projectId;
  final TeamPostCreator creator;
  final List<TeamRoleSlot> neededRoles;
  final String description;
  final int filledCount;
  final int totalCount;
  final bool isAiRecommended;
  final int matchScore;
  final String status;
  final String createdAt;

  const TeamPost({
    required this.id,
    required this.projectName,
    required this.projectId,
    required this.creator,
    this.neededRoles = const [],
    this.description = '',
    this.filledCount = 0,
    this.totalCount = 0,
    this.isAiRecommended = false,
    this.matchScore = 0,
    this.status = 'recruiting',
    this.createdAt = '',
  });

  String get progressText => '$filledCount/$totalCount 已就位';

  factory TeamPost.fromJson(Map<String, dynamic> json) {
    return TeamPost(
      id: json['id'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      creator: TeamPostCreator.fromJson(
          json['creator'] as Map<String, dynamic>? ?? {}),
      neededRoles: (json['needed_roles'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TeamRoleSlot.fromJson(e))
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
      filledCount: json['filled_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      isAiRecommended: json['is_ai_recommended'] as bool? ?? false,
      matchScore: json['match_score'] as int? ?? 0,
      status: json['status'] as String? ?? 'recruiting',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class TeamMember {
  final String id;
  final String nickname;
  final String? avatar;
  final String role;
  final int ratio;
  final bool isLeader;
  final String status;

  const TeamMember({
    required this.id,
    required this.nickname,
    this.avatar,
    this.role = '',
    this.ratio = 0,
    this.isLeader = false,
    this.status = 'pending',
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? '',
      ratio: json['ratio'] as int? ?? 0,
      isLeader: json['is_leader'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
    );
  }

  TeamMember copyWith({int? ratio}) {
    return TeamMember(
      id: id,
      nickname: nickname,
      avatar: avatar,
      role: role,
      ratio: ratio ?? this.ratio,
      isLeader: isLeader,
      status: status,
    );
  }
}

class TeamDetail {
  final String id;
  final String projectName;
  final String projectId;
  final String status;
  final List<TeamMember> members;
  final String createdAt;

  const TeamDetail({
    required this.id,
    required this.projectName,
    required this.projectId,
    this.status = 'confirming',
    this.members = const [],
    this.createdAt = '',
  });

  int get totalRatio =>
      members.fold<int>(0, (sum, m) => sum + m.ratio);

  bool get isRatioValid => totalRatio == 100;

  factory TeamDetail.fromJson(Map<String, dynamic> json) {
    return TeamDetail(
      id: json['id'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      status: json['status'] as String? ?? 'confirming',
      members: (json['members'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TeamMember.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
