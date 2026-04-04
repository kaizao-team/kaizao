enum BidStatus {
  pending(1, '待处理'),
  accepted(2, '已选定'),
  rejected(3, '已拒绝'),
  withdrawn(4, '已撤回');

  final int value;
  final String label;
  const BidStatus(this.value, this.label);

  static BidStatus fromValue(int? v) =>
      BidStatus.values.firstWhere((e) => e.value == v, orElse: () => pending);
}

class BidItem {
  final String id;
  final String userId;
  final String userName;
  final String? avatar;
  final double rating;
  final int completionRate;
  final int matchScore;
  final double bidAmount;
  final int durationDays;
  final String proposal;
  final String bidType;
  final String? teamName;
  final List<TeamMember> teamMembers;
  final bool isAiRecommended;
  final List<String> skills;
  final String createdAt;
  final BidStatus status;

  const BidItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatar,
    required this.rating,
    required this.completionRate,
    required this.matchScore,
    required this.bidAmount,
    required this.durationDays,
    required this.proposal,
    required this.bidType,
    this.teamName,
    this.teamMembers = const [],
    required this.isAiRecommended,
    this.skills = const [],
    required this.createdAt,
    this.status = BidStatus.pending,
  });

  bool get isTeamBid => bidType == 'team';
  bool get isPending => status == BidStatus.pending;
  bool get canWithdraw => status == BidStatus.pending;

  BidItem copyWith({BidStatus? status}) => BidItem(
        id: id,
        userId: userId,
        userName: userName,
        avatar: avatar,
        rating: rating,
        completionRate: completionRate,
        matchScore: matchScore,
        bidAmount: bidAmount,
        durationDays: durationDays,
        proposal: proposal,
        bidType: bidType,
        teamName: teamName,
        teamMembers: teamMembers,
        isAiRecommended: isAiRecommended,
        skills: skills,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  factory BidItem.fromJson(Map<String, dynamic> json) {
    return BidItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toInt() ?? 0,
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      bidAmount: (json['bid_amount'] as num?)?.toDouble() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      proposal: json['proposal']?.toString() ?? '',
      bidType: json['bid_type']?.toString() ?? 'personal',
      teamName: json['team_name']?.toString(),
      teamMembers: (json['team_members'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((m) => TeamMember.fromJson(m))
              .toList() ??
          [],
      isAiRecommended: json['is_ai_recommended'] as bool? ?? false,
      skills:
          (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at']?.toString() ?? '',
      status: BidStatus.fromValue(
          json['status'] is int ? json['status'] as int : null),
    );
  }
}

class TeamMember {
  final String name;
  final String role;

  const TeamMember({required this.name, required this.role});

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class AiSuggestion {
  final double suggestedPriceMin;
  final double suggestedPriceMax;
  final int suggestedDurationDays;
  final int skillMatchScore;
  final String reason;

  const AiSuggestion({
    required this.suggestedPriceMin,
    required this.suggestedPriceMax,
    required this.suggestedDurationDays,
    required this.skillMatchScore,
    required this.reason,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      suggestedPriceMin: (json['suggested_price_min'] as num).toDouble(),
      suggestedPriceMax: (json['suggested_price_max'] as num).toDouble(),
      suggestedDurationDays: json['suggested_duration_days'] as int,
      skillMatchScore: json['skill_match_score'] as int,
      reason: json['reason'] as String,
    );
  }
}

enum BidFormType { personal, team }
