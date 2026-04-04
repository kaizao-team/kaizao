import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../market/repositories/market_repository.dart';

class ProjectDetailState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const ProjectDetailState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
  });

  ProjectDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? Function()? errorMessage,
  }) {
    return ProjectDetailState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  String get title => data?['title']?.toString() ?? '';
  String get description => data?['description']?.toString() ?? '';
  String get category => data?['category']?.toString() ?? '';
  String get prdSummary => data?['prd_summary']?.toString() ?? '';
  double get budgetMin => (data?['budget_min'] as num?)?.toDouble() ?? 0;
  double get budgetMax => (data?['budget_max'] as num?)?.toDouble() ?? 0;
  int get status => data?['status'] as int? ?? 0;
  int get viewCount => data?['view_count'] as int? ?? 0;
  int get bidCount => data?['bid_count'] as int? ?? 0;
  int get progress => data?['progress'] as int? ?? 0;
  int get matchScore => data?['match_score'] as int? ?? 0;
  String get ownerName => data?['owner_name']?.toString() ?? '';
  String get ownerId => data?['owner_id']?.toString() ?? '';
  String get createdAt => data?['created_at']?.toString() ?? '';
  List<String> get techRequirements =>
      (data?['tech_requirements'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .toList() ??
      [];
  List<Map<String, dynamic>> get milestones =>
      (data?['milestones'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
      [];

  String get categoryName {
    switch (category) {
      case 'dev': return '开发';
      case 'visual': return '视觉设计';
      case 'content': return '内容';
      case 'consulting': return '咨询';
      default: return category.isNotEmpty ? category : '未分类';
    }
  }

  String get timeAgo {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}月前';
      if (diff.inDays > 0) return '${diff.inDays}天前';
      if (diff.inHours > 0) return '${diff.inHours}小时前';
      if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
      return '刚刚';
    } catch (_) {
      return '';
    }
  }

  bool get isFavorited => data?['is_favorited'] as bool? ?? false;

  String get budgetDisplay =>
      '¥${budgetMin.toStringAsFixed(0)}-${budgetMax.toStringAsFixed(0)}';

  String get statusName {
    switch (status) {
      case 1: return '草稿';
      case 2: return '已发布';
      case 3: return '匹配中';
      case 4: return '已匹配';
      case 5: return '进行中';
      case 6: return '验收中';
      case 7: return '已完成';
      case 8: return '已关闭';
      case 9: return '争议中';
      default: return '未知';
    }
  }
}

class ProjectDetailNotifier extends StateNotifier<ProjectDetailState> {
  final MarketRepository _repository;
  final String projectId;

  ProjectDetailNotifier(this._repository, this.projectId)
      : super(const ProjectDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final data = await _repository.fetchProjectDetail(projectId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }
}

final projectDetailProvider = StateNotifierProvider.autoDispose.family<
    ProjectDetailNotifier, ProjectDetailState, String>((ref, id) {
  final repository = MarketRepository();
  return ProjectDetailNotifier(repository, id);
});
