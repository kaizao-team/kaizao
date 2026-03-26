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

  String get roleName => isDemander ? '需求方' : '专家';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
      tagline: json['tagline'] as String? ?? '',
      role: json['role'] as int? ?? 1,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      creditScore: json['credit_score'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      phone: json['phone'] as String?,
      wechatBound: json['wechat_bound'] as bool? ?? false,
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const UserStats(),
      bio: json['bio'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
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
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
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
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
