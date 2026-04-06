class TeamProfile {
  final String id;
  final String teamName;
  final String? description;
  final String? avatarUrl;
  final String? vibeLevel;
  final int vibePower;
  final double? hourlyRate;
  final double avgRating;
  final int memberCount;
  final int totalProjects;
  final int availableStatus;
  final int experienceYears;
  final String? resumeSummary;
  final String leaderUuid;
  final String nickname;
  final String? leaderAvatarUrl;
  final int completedProjects;
  final String? tagline;
  final List<String> skills;
  final String createdAt;
  final List<TeamProfileMember> members;

  const TeamProfile({
    required this.id,
    required this.teamName,
    this.description,
    this.avatarUrl,
    this.vibeLevel,
    this.vibePower = 0,
    this.hourlyRate,
    this.avgRating = 0.0,
    this.memberCount = 1,
    this.totalProjects = 0,
    this.availableStatus = 1,
    this.experienceYears = 0,
    this.resumeSummary,
    required this.leaderUuid,
    required this.nickname,
    this.leaderAvatarUrl,
    this.completedProjects = 0,
    this.tagline,
    this.skills = const [],
    this.createdAt = '',
    this.members = const [],
  });

  bool get isAvailable => availableStatus == 1;

  String get rateDisplay {
    if (hourlyRate == null || hourlyRate! <= 0) return '报价面议';
    return '¥${hourlyRate!.toInt()}/h';
  }

  factory TeamProfile.fromJson(Map<String, dynamic> json) {
    return TeamProfile(
      id: json['id']?.toString() ?? '',
      teamName: json['team_name'] as String? ??
          json['project_name'] as String? ??
          '',
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      vibeLevel: json['vibe_level'] as String?,
      vibePower: json['vibe_power'] as int? ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      memberCount: json['member_count'] as int? ?? 1,
      totalProjects: json['total_projects'] as int? ?? 0,
      availableStatus: json['available_status'] as int? ?? 1,
      experienceYears: json['experience_years'] as int? ?? 0,
      resumeSummary: json['resume_summary'] as String?,
      leaderUuid: json['leader_uuid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      leaderAvatarUrl: json['leader_avatar_url'] as String?,
      completedProjects: json['completed_projects'] as int? ?? 0,
      tagline: json['tagline'] as String?,
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      createdAt: json['created_at'] as String? ?? '',
      members: (json['members'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TeamProfileMember.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TeamProfileMember {
  final int id;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String role;
  final int ratio;
  final bool isLeader;
  final String status;

  const TeamProfileMember({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.role = '',
    this.ratio = 0,
    this.isLeader = false,
    this.status = 'pending',
  });

  factory TeamProfileMember.fromJson(Map<String, dynamic> json) {
    return TeamProfileMember(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? '',
      ratio: json['ratio'] as int? ?? 0,
      isLeader: json['is_leader'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
