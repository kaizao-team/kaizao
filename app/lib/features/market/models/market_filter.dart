import '../../../shared/models/project_category.dart';

class MarketCategory {
  final String key;
  final String name;

  const MarketCategory({required this.key, required this.name});

  static const List<MarketCategory> all = [
    MarketCategory(key: 'all', name: '全部'),
    MarketCategory(key: 'data', name: '数据'),
    MarketCategory(key: 'dev', name: '研发'),
    MarketCategory(key: 'visual', name: '视觉设计'),
    MarketCategory(key: 'solution', name: '解决方案'),
  ];

  static bool supports(String? key) {
    if (key == null || key.isEmpty) return false;
    if (key == 'all') return true;
    return supportsProjectCategory(key);
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

  /// 根据角色过滤排序选项：项目方不展示"匹配度"
  static List<MarketSortOption> forRole(int role) {
    if (role == 2) return all;
    return all.where((s) => s.key != 'match').toList();
  }
}

class MarketProjectItem {
  final String id;
  final String uuid;
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
    this.uuid = '',
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

  /// 路由用唯一标识：优先 uuid，回退 id
  String get routingId => uuid.isNotEmpty ? uuid : id;

  factory MarketProjectItem.fromJson(Map<String, dynamic> json) {
    return MarketProjectItem(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: normalizeProjectCategoryKey(json['category'] as String? ?? ''),
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
    return projectCategoryLabel(category);
  }
}

String normalizeMarketCategory(String? category) {
  if (category == 'all') return 'all';
  final normalized = normalizeProjectCategoryKey(category);
  if (MarketCategory.supports(normalized)) {
    return normalized;
  }
  return 'all';
}
