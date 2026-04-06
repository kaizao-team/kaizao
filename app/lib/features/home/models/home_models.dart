import '../../../shared/models/project_model.dart';

String _formatWholeAmount(num amount) {
  final normalized = amount.toStringAsFixed(0);
  return normalized.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

class CategoryItem {
  final String key;
  final String name;
  final String icon;
  final int count;

  const CategoryItem({
    required this.key,
    required this.name,
    required this.icon,
    required this.count,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class RecommendedExpert {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final double rating;
  final String skill;
  final int hourlyRate;
  final int completedOrders;
  final String? vibeLevel;
  final int vibePower;
  final int memberCount;

  const RecommendedExpert({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.rating,
    required this.skill,
    required this.hourlyRate,
    required this.completedOrders,
    this.vibeLevel,
    this.vibePower = 0,
    this.memberCount = 1,
  });

  factory RecommendedExpert.fromJson(Map<String, dynamic> json) {
    return RecommendedExpert(
      id: json['id'] as String? ?? '',
      nickname: json['name'] as String? ?? json['nickname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      skill: json['skill'] as String? ?? '',
      hourlyRate: json['hourly_rate'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? json['completed_projects'] as int? ?? 0,
      vibeLevel: json['vibe_level'] as String?,
      vibePower: json['vibe_power'] as int? ?? 0,
      memberCount: json['member_count'] as int? ?? 1,
    );
  }
}

class DemanderHomeData {
  final String aiPrompt;
  final List<CategoryItem> categories;
  final List<ProjectModel> myProjects;
  final List<RecommendedExpert> recommendedExperts;

  const DemanderHomeData({
    required this.aiPrompt,
    required this.categories,
    required this.myProjects,
    required this.recommendedExperts,
  });

  factory DemanderHomeData.fromJson(Map<String, dynamic> json) {
    return DemanderHomeData(
      aiPrompt: json['ai_prompt'] as String? ?? '',
      categories: (json['categories'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => CategoryItem.fromJson(e))
              .toList() ??
          [],
      myProjects: (json['my_projects'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => ProjectModel.fromJson(e))
              .toList() ??
          [],
      recommendedExperts: (json['recommended_experts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => RecommendedExpert.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RevenueData {
  final double totalIncome;
  final double monthIncome;
  final double pendingIncome;
  final double trend;

  const RevenueData({
    required this.totalIncome,
    required this.monthIncome,
    required this.pendingIncome,
    required this.trend,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
      monthIncome: (json['month_income'] as num?)?.toDouble() ?? 0,
      pendingIncome: (json['pending_income'] as num?)?.toDouble() ?? 0,
      trend: (json['trend'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RecommendedDemand {
  final String id;
  final String uuid;
  final String title;
  final String description;
  final String category;
  final double budgetMin;
  final double budgetMax;
  final int matchScore;
  final List<String> techRequirements;

  const RecommendedDemand({
    required this.id,
    this.uuid = '',
    required this.title,
    required this.description,
    required this.category,
    required this.budgetMin,
    required this.budgetMax,
    required this.matchScore,
    required this.techRequirements,
  });

  /// 路由用唯一标识：优先 uuid，回退 id
  String get routingId => uuid.isNotEmpty ? uuid : id;

  factory RecommendedDemand.fromJson(Map<String, dynamic> json) {
    return RecommendedDemand(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      budgetMin: (json['budget_min'] as num?)?.toDouble() ?? 0,
      budgetMax: (json['budget_max'] as num?)?.toDouble() ?? 0,
      matchScore: json['match_score'] as int? ?? 0,
      techRequirements:
          (json['tech_requirements'] as List?)?.cast<String>() ?? [],
    );
  }

  String get budgetDisplay =>
      '¥${_formatWholeAmount(budgetMin)}-${_formatWholeAmount(budgetMax)}';
}

class SkillHeatItem {
  final String name;
  final int heat;

  const SkillHeatItem({required this.name, required this.heat});

  factory SkillHeatItem.fromJson(Map<String, dynamic> json) {
    return SkillHeatItem(
      name: json['name'] as String? ?? '',
      heat: json['heat'] as int? ?? 0,
    );
  }
}

class TeamOpportunity {
  final String id;
  final String projectTitle;
  final String neededRole;
  final int teamSize;
  final int budget;

  const TeamOpportunity({
    required this.id,
    required this.projectTitle,
    required this.neededRole,
    required this.teamSize,
    required this.budget,
  });

  factory TeamOpportunity.fromJson(Map<String, dynamic> json) {
    return TeamOpportunity(
      id: json['id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? '',
      neededRole: json['needed_role'] as String? ?? '',
      teamSize: json['team_size'] as int? ?? 0,
      budget: json['budget'] as int? ?? 0,
    );
  }

  String get budgetDisplay => '¥${_formatWholeAmount(budget)}';

  String get teamSizeDisplay => '$teamSize 人团队';
}

class ExpertHomeData {
  final RevenueData revenue;
  final List<RecommendedDemand> recommendedDemands;
  final List<SkillHeatItem> skillHeat;
  final List<TeamOpportunity> teamOpportunities;

  const ExpertHomeData({
    required this.revenue,
    required this.recommendedDemands,
    required this.skillHeat,
    required this.teamOpportunities,
  });

  factory ExpertHomeData.fromJson(Map<String, dynamic> json) {
    return ExpertHomeData(
      revenue:
          RevenueData.fromJson(json['revenue'] as Map<String, dynamic>? ?? {}),
      recommendedDemands: (json['recommended_demands'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => RecommendedDemand.fromJson(e))
              .toList() ??
          [],
      skillHeat: (json['skill_heat'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => SkillHeatItem.fromJson(e))
              .toList() ??
          [],
      teamOpportunities: (json['team_opportunities'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TeamOpportunity.fromJson(e))
              .toList() ??
          [],
    );
  }
}
