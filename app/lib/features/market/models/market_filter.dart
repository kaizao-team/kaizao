class MarketCategory {
  final String key;
  final String name;

  const MarketCategory({required this.key, required this.name});

  static const List<MarketCategory> all = [
    MarketCategory(key: 'all', name: '全部'),
    MarketCategory(key: 'data', name: '数据'),
    MarketCategory(key: 'dev', name: '研发'),
    MarketCategory(key: 'design', name: '视觉设计'),
    MarketCategory(key: 'solution', name: '解决方案'),
  ];

  static bool supports(String? key) {
    if (key == null || key.isEmpty) return false;
    return all.any((category) => category.key == key);
  }
}

class MarketSortOption {
  final String key;
  final String name;

  const MarketSortOption({required this.key, required this.name});

  static const List<MarketSortOption> all = [
    MarketSortOption(key: 'latest', name: '最新发布'),
    MarketSortOption(key: 'budget_desc', name: '预算最高'),
    MarketSortOption(key: 'match', name: '匹配度'),
  ];

  /// 根据角色过滤排序选项：需求方不展示"匹配度"
  static List<MarketSortOption> forRole(int role) {
    if (role == 2) return all;
    return all.where((s) => s.key != 'match').toList();
  }
}

class MarketProjectItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? ownerName;
  final double budgetMin;
  final double budgetMax;
  final int? matchScore;
  final int status;
  final List<String> techRequirements;
  final int viewCount;
  final int bidCount;
  final DateTime createdAt;

  const MarketProjectItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.ownerName,
    required this.budgetMin,
    required this.budgetMax,
    this.matchScore,
    required this.status,
    required this.techRequirements,
    required this.viewCount,
    required this.bidCount,
    required this.createdAt,
  });

  factory MarketProjectItem.fromJson(Map<String, dynamic> json) {
    return MarketProjectItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      ownerName: json['owner_name'] as String?,
      budgetMin: (json['budget_min'] as num?)?.toDouble() ?? 0,
      budgetMax: (json['budget_max'] as num?)?.toDouble() ?? 0,
      matchScore: json['match_score'] as int?,
      status: json['status'] as int? ?? 1,
      techRequirements:
          (json['tech_requirements'] as List?)?.cast<String>() ?? [],
      viewCount: json['view_count'] as int? ?? 0,
      bidCount: json['bid_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get budgetDisplay =>
      '¥${budgetMin.toStringAsFixed(0)}-${budgetMax.toStringAsFixed(0)}';

  String get categoryName {
    for (final cat in MarketCategory.all) {
      if (cat.key == category) return cat.name;
    }
    return '其他';
  }
}

String normalizeMarketCategory(String? category) {
  if (MarketCategory.supports(category)) {
    return category!;
  }
  return 'all';
}
