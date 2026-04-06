class MarketExpertItem {
  final String id;
  final String? leaderUuid;
  final String teamName;
  final String nickname;
  final String? avatarUrl;
  final double rating;
  final List<String> skills;
  final int completedProjects;
  final int hourlyRate;
  final String tagline;
  final String? vibeLevel;
  final int vibePower;
  final int memberCount;

  String get displayName => teamName.isNotEmpty ? teamName : nickname;

  const MarketExpertItem({
    required this.id,
    this.leaderUuid,
    this.teamName = '',
    required this.nickname,
    this.avatarUrl,
    required this.rating,
    required this.skills,
    required this.completedProjects,
    required this.hourlyRate,
    this.tagline = '',
    this.vibeLevel,
    this.vibePower = 0,
    this.memberCount = 1,
  });

  factory MarketExpertItem.fromJson(Map<String, dynamic> json) {
    return MarketExpertItem(
      id: json['id']?.toString() ?? '',
      leaderUuid: json['leader_uuid']?.toString(),
      teamName: json['team_name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      completedProjects: json['completed_projects'] as int? ?? 0,
      hourlyRate: json['hourly_rate'] as int? ?? 0,
      tagline: json['tagline'] as String? ?? '',
      vibeLevel: json['vibe_level'] as String?,
      vibePower: json['vibe_power'] as int? ?? 0,
      memberCount: json['member_count'] as int? ?? 1,
    );
  }
}
