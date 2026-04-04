enum FavoriteTargetType {
  project('project'),
  expert('expert');

  final String value;
  const FavoriteTargetType(this.value);

  static FavoriteTargetType fromValue(String? v) => FavoriteTargetType.values
      .firstWhere((e) => e.value == v, orElse: () => project);
}

class FavoriteItem {
  final String id;
  final FavoriteTargetType targetType;
  final String targetId;
  final String createdAt;

  // project 附加字段
  final String? title;
  final int? status;
  final String? category;
  final double? budgetMin;
  final double? budgetMax;

  // expert 附加字段
  final String? nickname;
  final String? avatarUrl;
  final double? rating;

  const FavoriteItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.createdAt = '',
    this.title,
    this.status,
    this.category,
    this.budgetMin,
    this.budgetMax,
    this.nickname,
    this.avatarUrl,
    this.rating,
  });

  bool get isProject => targetType == FavoriteTargetType.project;
  bool get isExpert => targetType == FavoriteTargetType.expert;

  String get displayBudget {
    if (budgetMin == null && budgetMax == null) return '面议';
    final min = budgetMin?.toStringAsFixed(0) ?? '?';
    final max = budgetMax?.toStringAsFixed(0) ?? '?';
    return '¥$min - ¥$max';
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      targetType: FavoriteTargetType.fromValue(json['target_type']?.toString()),
      targetId: json['target_id']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      title: json['title']?.toString(),
      status: json['status'] as int?,
      category: json['category']?.toString(),
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      nickname: json['nickname']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class FavoriteListMeta {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const FavoriteListMeta({
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.totalPages = 1,
  });

  factory FavoriteListMeta.fromJson(Map<String, dynamic> json) {
    return FavoriteListMeta(
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}
