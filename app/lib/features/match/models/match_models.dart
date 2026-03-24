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
  });

  bool get isTeamBid => bidType == 'team';

  factory BidItem.fromJson(Map<String, dynamic> json) {
    return BidItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      avatar: json['avatar'] as String?,
      rating: (json['rating'] as num).toDouble(),
      completionRate: json['completion_rate'] as int,
      matchScore: json['match_score'] as int,
      bidAmount: (json['bid_amount'] as num).toDouble(),
      durationDays: json['duration_days'] as int,
      proposal: json['proposal'] as String,
      bidType: json['bid_type'] as String,
      teamName: json['team_name'] as String?,
      teamMembers: (json['team_members'] as List?)
              ?.map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      isAiRecommended: json['is_ai_recommended'] as bool,
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      createdAt: json['created_at'] as String,
    );
  }
}

class TeamMember {
  final String name;
  final String role;

  const TeamMember({required this.name, required this.role});

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] as String,
      role: json['role'] as String,
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
