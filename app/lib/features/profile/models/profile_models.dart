class UserProfile {
  final String id;
  final String nickname;
  final String? avatar;
  final String tagline;
  final int role;
  final double rating;
  final int creditScore;
  final bool isVerified;
  final String? phone;
  final bool wechatBound;
  final UserStats stats;
  final String bio;
  final String createdAt;

  const UserProfile({
    required this.id,
    required this.nickname,
    this.avatar,
    this.tagline = '',
    this.role = 1,
    this.rating = 0,
    this.creditScore = 0,
    this.isVerified = false,
    this.phone,
    this.wechatBound = false,
    this.stats = const UserStats(),
    this.bio = '',
    this.createdAt = '',
  });

  bool get isDemander => role == 1;
  bool get isExpert => role == 2;

  String get roleName => isDemander ? '项目方' : '团队方';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? json['uuid']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      avatar: (json['avatar_url'] ?? json['avatar'])?.toString(),
      tagline: json['tagline']?.toString() ?? '',
      role: json['role'] as int? ?? 1,
      rating: (json['avg_rating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0,
      creditScore: json['credit_score'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      phone: (json['contact_phone'] ?? json['phone'])?.toString(),
      wechatBound: json['wechat_bound'] as bool? ?? false,
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const UserStats(),
      bio: json['bio']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class UserStats {
  final int completedProjects;
  final int approvalRate;
  final double avgDeliveryDays;
  final double totalEarnings;
  final int publishedProjects;
  final double totalSpent;
  final int daysOnPlatform;

  const UserStats({
    this.completedProjects = 0,
    this.approvalRate = 0,
    this.avgDeliveryDays = 0,
    this.totalEarnings = 0,
    this.publishedProjects = 0,
    this.totalSpent = 0,
    this.daysOnPlatform = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      completedProjects: json['completed_projects'] as int? ?? 0,
      approvalRate: json['approval_rate'] as int? ?? 0,
      avgDeliveryDays: (json['avg_delivery_days'] as num?)?.toDouble() ?? 0,
      totalEarnings: (json['total_earned'] as num?)?.toDouble() ??
          (json['total_earnings'] as num?)?.toDouble() ??
          0,
      publishedProjects: json['published_projects'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      daysOnPlatform: json['days_on_platform'] as int? ?? 0,
    );
  }
}

class SkillTag {
  final String id;
  final String name;
  final String category;

  const SkillTag({
    required this.id,
    required this.name,
    this.category = '',
  });

  factory SkillTag.fromJson(Map<String, dynamic> json) {
    return SkillTag(
      id: json['id']?.toString() ?? json['skill_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
      };
}

class PortfolioItem {
  final String id;
  final String title;
  final String? coverUrl;
  final String description;
  final List<String> tags;
  final String createdAt;

  const PortfolioItem({
    required this.id,
    required this.title,
    this.coverUrl,
    this.description = '',
    this.tags = const [],
    this.createdAt = '',
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString(),
      description: json['description']?.toString() ?? '',
      tags: (json['tags'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
