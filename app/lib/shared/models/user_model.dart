class UserModel {
  final String id;
  final String uuid;
  final String nickname;
  final String? avatarUrl;
  final int role;
  final String? bio;
  final String? city;
  final bool isVerified;
  final int creditScore;
  final int level;
  final int totalOrders;
  final int completedOrders;
  final double completionRate;
  final double avgRating;
  final double? hourlyRate;
  final int availableStatus;
  final List<String> skills;
  final List<String> roleTags;

  const UserModel({
    required this.id,
    required this.uuid,
    required this.nickname,
    this.avatarUrl,
    this.role = 0,
    this.bio,
    this.city,
    this.isVerified = false,
    this.creditScore = 500,
    this.level = 1,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.completionRate = 0,
    this.avgRating = 0,
    this.hourlyRate,
    this.availableStatus = 1,
    this.skills = const [],
    this.roleTags = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as int? ?? 0,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      creditScore: json['credit_score'] as int? ?? 500,
      level: json['level'] as int? ?? 1,
      totalOrders: json['total_orders'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      availableStatus: json['available_status'] as int? ?? 1,
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      roleTags: (json['role_tags'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'role': role,
      'bio': bio,
      'city': city,
      'is_verified': isVerified,
      'credit_score': creditScore,
      'level': level,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'completion_rate': completionRate,
      'avg_rating': avgRating,
      'hourly_rate': hourlyRate,
      'available_status': availableStatus,
      'skills': skills,
      'role_tags': roleTags,
    };
  }

  String get levelName {
    switch (level) {
      case 1: return '新手';
      case 2: return '成长';
      case 3: return '专业';
      case 4: return '精英';
      case 5: return '大师';
      default: return '新手';
    }
  }

  bool get isDemander => role == 1 || role == 3;
  bool get isProvider => role == 2 || role == 3;
}
