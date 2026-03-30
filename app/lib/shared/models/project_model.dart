import 'project_category.dart';

class ProjectModel {
  final String id;
  final String uuid;
  final String ownerId;
  final String? providerId;
  final String? providerName;
  final String? providerAvatarUrl;
  final String? teamId;
  final String title;
  final String description;
  final String category;
  final double? budgetMin;
  final double? budgetMax;
  final double? agreedPrice;
  final String? complexity;
  final int progress;
  final int status;
  final int matchMode;
  final int viewCount;
  final int bidCount;
  final List<String> techRequirements;
  final DateTime? deadlineAt;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.uuid,
    required this.ownerId,
    this.providerId,
    this.providerName,
    this.providerAvatarUrl,
    this.teamId,
    required this.title,
    required this.description,
    required this.category,
    this.budgetMin,
    this.budgetMax,
    this.agreedPrice,
    this.complexity,
    this.progress = 0,
    this.status = 1,
    this.matchMode = 1,
    this.viewCount = 0,
    this.bidCount = 0,
    this.techRequirements = const [],
    this.deadlineAt,
    this.publishedAt,
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid'] as String? ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      providerId: json['provider_id']?.toString(),
      providerName:
          json['provider_name'] as String? ??
          json['provider_nickname'] as String?,
      providerAvatarUrl:
          json['provider_avatar_url'] as String? ??
          json['avatar_url'] as String?,
      teamId: json['team_id']?.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: normalizeProjectCategoryKey(json['category'] as String? ?? ''),
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      agreedPrice: (json['agreed_price'] as num?)?.toDouble(),
      complexity: json['complexity'] as String?,
      progress: json['progress'] as int? ?? 0,
      status: json['status'] as int? ?? 1,
      matchMode: json['match_mode'] as int? ?? 1,
      viewCount: json['view_count'] as int? ?? 0,
      bidCount: json['bid_count'] as int? ?? 0,
      techRequirements:
          (json['tech_requirements'] as List?)?.cast<String>() ?? [],
      deadlineAt: _parseDateTime(
        json['deadline_at'] ??
            json['deadline'] ??
            json['due_date'] ??
            json['end_date'],
      ),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get statusName {
    switch (status) {
      case 1:
        return '草稿';
      case 2:
        return '已发布';
      case 3:
        return '匹配中';
      case 4:
        return '已匹配';
      case 5:
        return '进行中';
      case 6:
        return '验收中';
      case 7:
        return '已完成';
      case 8:
        return '已关闭';
      case 9:
        return '争议中';
      default:
        return '未知';
    }
  }

  String get homeStatusName {
    switch (status) {
      case 1:
      case 2:
      case 3:
        return '招募中';
      case 4:
      case 5:
        return '进行中';
      case 6:
        return '待验收';
      case 7:
        return '已完成';
      default:
        return statusName;
    }
  }

  String get statusTagType {
    switch (status) {
      case 5:
        return 'in_progress';
      case 6:
        return 'pending';
      case 7:
        return 'completed';
      case 9:
        return 'at_risk';
      default:
        return 'not_started';
    }
  }

  /// 路由用唯一标识：优先 uuid，回退 id，确保后端仅返回 uuid 时也能正常跳转
  String get routingId => uuid.isNotEmpty ? uuid : id;

  String get budgetDisplay {
    if (agreedPrice != null) return '\u00a5${agreedPrice!.toStringAsFixed(0)}';
    if (budgetMin != null && budgetMax != null) {
      return '\u00a5${budgetMin!.toStringAsFixed(0)}-${budgetMax!.toStringAsFixed(0)}';
    }
    return '面议';
  }

  String get categoryName {
    return projectCategoryLabel(category);
  }

  bool get hasMatchedProvider {
    final hasProviderIdentity =
        (providerId?.isNotEmpty ?? false) ||
        (providerName?.isNotEmpty ?? false);

    if (hasProviderIdentity) return true;
    return status >= 4 && status <= 7;
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
